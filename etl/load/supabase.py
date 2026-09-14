from __future__ import annotations

from decimal import Decimal
from typing import Any

from sqlalchemy import create_engine, text


class Database:
    def __init__(self, database_url: str):
        if database_url.startswith('postgres://'):
            database_url = database_url.replace('postgres://', 'postgresql+psycopg2://', 1)
        elif database_url.startswith('postgresql://'):
            database_url = database_url.replace('postgresql://', 'postgresql+psycopg2://', 1)
        self.engine = create_engine(database_url, future=True)

    def begin(self):
        return self.engine.begin()

    @staticmethod
    def _one(connection, query: str, params: dict[str, Any]) -> Any:
        return connection.execute(text(query), params).mappings().first()

    def create_batch(self, connection, source_file: str, source_type: str, total_rows: int) -> int:
        row = self._one(connection, """
            INSERT INTO staging.import_batches (source_file, source_type, total_rows)
            VALUES (:source_file, :source_type, :total_rows)
            RETURNING batch_id
        """, {'source_file': source_file, 'source_type': source_type, 'total_rows': total_rows})
        return int(row['batch_id'])

    def finish_batch(self, connection, batch_id: int, status: str, success: int, failed: int, skipped: int, notes: str | None = None) -> None:
        connection.execute(text("""
            UPDATE staging.import_batches
            SET status = :status, success_rows = :success, failed_rows = :failed,
                skipped_rows = :skipped, notes = :notes
            WHERE batch_id = :batch_id
        """), {'batch_id': batch_id, 'status': status, 'success': success, 'failed': failed, 'skipped': skipped, 'notes': notes})

    def record_error(self, connection, batch_id: int, error: dict) -> None:
        connection.execute(text("""
            INSERT INTO staging.import_errors (batch_id, source_row, external_id, error_message, raw_payload)
            VALUES (:batch_id, :source_row, :external_id, :error_message, CAST(:raw_payload AS jsonb))
        """), {**error, 'batch_id': batch_id, 'raw_payload': __import__('json').dumps(error['raw_payload'], ensure_ascii=True)})

    def lookup_or_create(self, connection, table: str, name: str | None, fields: dict[str, Any], match_column: str = 'name') -> int | None:
        if not name:
            return None
        existing = self._one(connection, f"SELECT id FROM public.{table} WHERE LOWER(TRIM({match_column})) = LOWER(TRIM(:name)) LIMIT 1", {'name': name})
        if existing:
            return int(existing['id'])
        values = {match_column: name, **fields}
        columns = ', '.join(values)
        binds = ', '.join(f':{column}' for column in values)
        row = self._one(connection, f'INSERT INTO public.{table} ({columns}) VALUES ({binds}) RETURNING id', values)
        return int(row['id'])

    def fund_id(self, connection, code: str) -> int:
        row = self._one(connection, 'SELECT id FROM public.funds WHERE code = :code', {'code': code})
        if not row:
            raise ValueError(f'missing fund {code}; run etl/sql/master_seed.sql first')
        return int(row['id'])

    def category_id(self, connection, code: str, name: str) -> int:
        row = self._one(connection, 'SELECT id FROM public.categories WHERE code = :code', {'code': code})
        if row:
            return int(row['id'])
        inserted = self._one(connection, """
            INSERT INTO public.categories (code, name, active)
            VALUES (:code, :name, TRUE)
            ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name
            RETURNING id
        """, {'code': code, 'name': name})
        return int(inserted['id'])

    def activity_id(self, connection, code: str | None, name: str | None, fund_id: int) -> int | None:
        if not code or not name:
            return None
        row = self._one(connection, 'SELECT id FROM public.activities WHERE code = :code', {'code': code})
        if row:
            return int(row['id'])
        inserted = self._one(connection, """
            INSERT INTO public.activities (fund_id, code, name, active)
            VALUES (:fund_id, :code, :name, TRUE)
            ON CONFLICT (code) DO NOTHING
            RETURNING id
        """, {'fund_id': fund_id, 'code': code, 'name': name})
        if inserted:
            return int(inserted['id'])
        return int(self._one(connection, 'SELECT id FROM public.activities WHERE code = :code', {'code': code})['id'])

    def person_id(self, connection, name: str | None) -> int | None:
        return self.lookup_or_create(connection, 'persons', name, {'active': True})

    def vendor_id(self, connection, name: str | None) -> int | None:
        return self.lookup_or_create(connection, 'vendors', name, {'active': True})

    def upsert_vendor(self, connection, vendor: dict[str, Any]) -> int:
        existing = self._one(connection, """
            SELECT id FROM public.vendors
            WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
            LIMIT 1
        """, {'name': vendor['name']})
        if existing:
            connection.execute(text("""
                UPDATE public.vendors
                SET bank_name = COALESCE(:bank_name, bank_name),
                    bank_account_number = COALESCE(:bank_account_number, bank_account_number),
                    bank_account_name = COALESCE(:bank_account_name, bank_account_name),
                    notes = COALESCE(:notes, notes),
                    updated_at = NOW()
                WHERE id = :id
            """), {**vendor, 'id': int(existing['id'])})
            return int(existing['id'])
        inserted = self._one(connection, """
            INSERT INTO public.vendors (name, bank_name, bank_account_number, bank_account_name, notes, active)
            VALUES (:name, :bank_name, :bank_account_number, :bank_account_name, :notes, TRUE)
            RETURNING id
        """, vendor)
        return int(inserted['id'])

    def account_id(self, connection, alias: str | None) -> int | None:
        if not alias:
            return None
        normalized = alias.strip().upper()
        if normalized not in {'BANK', 'CASH'}:
            return None
        name = 'BSI Wakaf' if normalized == 'BANK' else 'Kas Wakaf'
        row = self._one(connection, 'SELECT id FROM public.accounts WHERE name = :name LIMIT 1', {'name': name})
        if row:
            return int(row['id'])
        account_type = normalized
        inserted = self._one(connection, """
            INSERT INTO public.accounts (name, account_type, active)
            VALUES (:name, :account_type, TRUE)
            RETURNING id
        """, {'name': name, 'account_type': account_type})
        return int(inserted['id'])

    def load_transaction(self, connection, record: dict, update_existing: bool) -> str:
        existing = self._one(connection, 'SELECT id FROM public.transactions WHERE external_id = :external_id', {'external_id': record['external_id']})
        values = {key: record[key] for key in (
            'external_id', 'transaction_date', 'fund_id', 'category_id', 'activity_id',
            'transaction_type', 'amount', 'description', 'vendor_id', 'person_id',
            'account_id', 'reference_number', 'notes')}
        if existing and not update_existing:
            return 'skipped'
        if existing:
            assignments = ', '.join(f'{key} = :{key}' for key in values if key != 'external_id')
            values['id'] = int(existing['id'])
            connection.execute(text(f'UPDATE public.transactions SET {assignments}, updated_at = NOW() WHERE id = :id'), values)
            return 'updated'
        columns = ', '.join(values)
        binds = ', '.join(f':{key}' for key in values)
        connection.execute(text(f'INSERT INTO public.transactions ({columns}) VALUES ({binds})'), values)
        return 'inserted'

    def transaction_id(self, connection, external_id: str) -> int:
        row = self._one(connection, 'SELECT id FROM public.transactions WHERE external_id = :external_id', {'external_id': external_id})
        if not row:
            raise ValueError(f'transaction {external_id} was not loaded')
        return int(row['id'])

    def load_reimbursement(self, connection, transaction_id: int, person_id: int | None, status: str | None, notes: str | None) -> None:
        if not person_id or status not in {'PENDING', 'REIMBURSED'}:
            return
        existing = self._one(connection, 'SELECT id FROM public.reimbursements WHERE transaction_id = :transaction_id', {'transaction_id': transaction_id})
        params = {'transaction_id': transaction_id, 'person_id': person_id, 'status': status, 'notes': notes}
        if existing:
            connection.execute(text("""
                UPDATE public.reimbursements
                SET person_id = :person_id, status = :status, notes = :notes, updated_at = NOW()
                WHERE transaction_id = :transaction_id
            """), params)
        else:
            connection.execute(text("""
                INSERT INTO public.reimbursements (transaction_id, person_id, status, notes)
                VALUES (:transaction_id, :person_id, :status, :notes)
            """), params)
