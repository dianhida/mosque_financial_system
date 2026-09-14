from __future__ import annotations

import argparse
import csv
import os
import re
from pathlib import Path

import yaml

from etl.extract.infaq import read_infaq
from etl.extract.wakaf import read_wakaf
from etl.load.staging import load_raw_rows
from etl.load.supabase import Database
from etl.transform.lookup import master_name_for_code
from etl.transform.normalize import normalize_frame
from etl.transform.validation import validate_transaction


ROOT = Path(__file__).resolve().parent


def load_mapping() -> dict:
    with (ROOT / 'config' / 'mapping.yaml').open(encoding='utf-8') as handle:
        return yaml.safe_load(handle)


def parse_vendor_file(path: Path) -> list[dict]:
    vendors: list[dict] = []
    pattern = re.compile(r'^(?P<name>.+?)\s+\((?P<bank>[^)]+)\)\s+(?P<number>\d+)\s*$')
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        line = line.strip()
        if not line or line.lower() == 'rekening vendor':
            continue
        match = pattern.match(line)
        if match:
            values = match.groupdict()
            vendors.append({
                'name': values['name'].strip(),
                'bank_name': values['bank'].strip(),
                'bank_account_number': values['number'].strip(),
                'bank_account_name': values['name'].strip(),
                'notes': 'Imported from Rekening Vendor.txt',
            })
        else:
            vendors.append({
                'name': line,
                'bank_name': None,
                'bank_account_number': None,
                'bank_account_name': line,
                'notes': 'Vendor has no bank account in source file.',
            })
    return vendors


def source_type_for(path: Path) -> str:
    name = path.name.lower()
    if 'infaq' in name:
        return 'INFAQ'
    if 'wakaf' in name:
        return 'WAKAF'
    raise ValueError(f'cannot infer source type from filename: {path.name}')


def process_source(database: Database | None, path: Path, mapping: dict, update_existing: bool, dry_run: bool) -> dict:
    source_type = source_type_for(path)
    frame = read_infaq(path) if source_type == 'INFAQ' else read_wakaf(path)
    normalized, errors = normalize_frame(frame, source_type, mapping)
    for record in normalized:
        validate_transaction(record)
    result = {'source': path.name, 'source_type': source_type, 'rows': len(frame), 'normalized': len(normalized), 'errors': len(errors), 'inserted': 0, 'updated': 0, 'skipped': 0}
    if dry_run:
        return result
    if database is None:
        raise RuntimeError('SUPABASE_DB_MOSQUE_URL is required unless --dry-run is used')
    with database.begin() as connection:
        batch_id = database.create_batch(connection, path.name, source_type, len(frame))
        load_raw_rows(connection, frame, source_type, batch_id)
        for error in errors:
            database.record_error(connection, batch_id, error)
        for record in normalized:
            fund_id = database.fund_id(connection, record['fund_code'])
            category_id = database.category_id(connection, record['category_code'], master_name_for_code(record['category_code']))
            activity_id = database.activity_id(connection, record['activity_code'], record['activity_name'], fund_id)
            vendor_id = database.vendor_id(connection, record['vendor_name'])
            person_id = database.person_id(connection, record['person_name'])
            account_id = database.account_id(connection, record['account_alias'])
            loaded = database.load_transaction(connection, {
                **record,
                'fund_id': fund_id,
                'category_id': category_id,
                'activity_id': activity_id,
                'vendor_id': vendor_id,
                'person_id': person_id,
                'account_id': account_id,
            }, update_existing)
            result[loaded] += 1
            if loaded != 'skipped' and record.get('reimbursement') in {'sudah', 'belum'}:
                reimbursement_status = 'REIMBURSED' if record['reimbursement'] == 'sudah' else 'PENDING'
                database.load_reimbursement(connection, database.transaction_id(connection, record['external_id']), person_id, reimbursement_status, record.get('notes'))
        status = 'COMPLETED' if not errors else 'COMPLETED_WITH_ERRORS'
        notes = f"inserted={result['inserted']}, updated={result['updated']}, skipped={result['skipped']}"
        database.finish_batch(connection, batch_id, status, result['inserted'] + result['updated'], len(errors), result['skipped'], notes)
    return result


def print_report(results: list[dict], vendor_count: int = 0) -> None:
    print(f'Found {vendor_count} vendor records')
    total_imported = 0
    total_skipped = 0
    total_errors = 0
    for result in results:
        total_imported += result['inserted'] + result['updated']
        total_skipped += result['skipped']
        total_errors += result['errors']
        print(
            f"{result['source']}: normalized {result['normalized']} rows, "
            f"imported {result['inserted'] + result['updated']}, "
            f"skipped {result['skipped']} duplicates, failed {result['errors']} rows"
        )
    print(f'TOTAL: imported {total_imported}, skipped {total_skipped} duplicates, errors {total_errors}')


def main() -> None:
    parser = argparse.ArgumentParser(description='Idempotent INFAQ/WAKAF spreadsheet ETL.')
    parser.add_argument('files', nargs='+', type=Path, help='Infaq.csv and/or Wakaf.csv')
    parser.add_argument('--vendor-file', type=Path, default=None, help='Optional Rekening Vendor.txt path')
    parser.add_argument('--update-existing', action='store_true', help='Update transactions whose external_id already exists')
    parser.add_argument('--dry-run', action='store_true', help='Parse and validate without connecting to Supabase')
    args = parser.parse_args()
    mapping = load_mapping()
    if not args.dry_run and not os.environ.get('SUPABASE_DB_MOSQUE_URL'):
        parser.error('SUPABASE_DB_MOSQUE_URL is required for a database import')
    database = None if args.dry_run else Database(os.environ['SUPABASE_DB_MOSQUE_URL'])
    vendor_count = 0
    if args.vendor_file and not args.dry_run:
        with database.begin() as connection:
            for vendor in parse_vendor_file(args.vendor_file):
                database.upsert_vendor(connection, vendor)
                vendor_count += 1
    results = [process_source(database, path, mapping, args.update_existing, args.dry_run) for path in args.files]
    if args.vendor_file and args.dry_run:
        vendor_count = len(parse_vendor_file(args.vendor_file))
    print_report(results, vendor_count)


if __name__ == '__main__':
    main()
