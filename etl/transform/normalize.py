from __future__ import annotations

from decimal import Decimal, InvalidOperation
import re
from typing import Any

import pandas as pd


_AMOUNT_RE = re.compile(r'[^0-9,.-]')


def clean_amount(value: Any) -> Decimal | None:
    """Convert Indonesian spreadsheet currency strings to a positive Decimal."""
    text = str(value or '').strip()
    if not text:
        return Decimal('0.00')
    text = text.replace('Rp', '').replace('rp', '').replace(' ', '')
    text = _AMOUNT_RE.sub('', text)
    if not text:
        return Decimal('0.00')
    text = text.replace(',', '')
    try:
        amount = Decimal(text)
    except InvalidOperation as exc:
        raise ValueError(f'invalid amount: {value!r}') from exc
    return abs(amount).quantize(Decimal('0.01'))


def clean_text(value: Any) -> str | None:
    text = str(value or '').strip()
    return text or None


def clean_person_name(value: Any) -> str | None:
    text = clean_text(value)
    if not text:
        return None
    text = re.split(r'\s*[:(]', text, maxsplit=1)[0].strip()
    return text or None


def parse_date(value: Any) -> str:
    text = clean_text(value)
    if not text:
        raise ValueError('missing transaction date')
    parsed = pd.to_datetime(text, dayfirst=True, errors='coerce')
    if pd.isna(parsed):
        raise ValueError(f'invalid transaction date: {value!r}')
    return parsed.date().isoformat()


def lookup_key(value: Any) -> str:
    return ' '.join(str(value or '').strip().lower().split())


def source_amount(row: pd.Series, source_type: str) -> Decimal:
    flow = lookup_key(row.get('flow'))
    if flow not in {'income', 'expense'}:
        raise ValueError('row has no Income or Expense flow')
    candidates = [row.get('kredit'), row.get('debit')]
    if source_type == 'INFAQ' and flow == 'expense':
        candidates = [row.get('debit'), row.get('kredit')]
    for candidate in candidates:
        amount = clean_amount(candidate)
        if amount is not None and amount > 0:
            return amount
    raise ValueError('row has no positive Kredit/Debit amount')


def _category_code(row: pd.Series, source_type: str, mapping: dict) -> str:
    if source_type == 'INFAQ':
        key = lookup_key(row.get('event'))
        if 'saldo' in lookup_key(row.get('description')):
            return 'OPENING_BALANCE'
        return mapping.get('categories', {}).get('infaq', {}).get(key) or mapping['default_category'][lookup_key(row.get('flow'))]
    if lookup_key(row.get('flow')) == 'income':
        return 'DONATION'
    description = lookup_key(row.get('description'))
    category = lookup_key(row.get('category'))
    if any(word in description for word in ('admin bsi', 'admni bsi', 'admin flip', 'admin bank')):
        return 'BANK_ADMINISTRATION'
    if any(word in description for word in ('upah', 'tukang', 'pekerja', 'labor')):
        return 'LABOR'
    if any(word in description for word in ('material', 'semen', 'pasir', 'batu', 'bata', 'besi', 'keramik', 'pintu', 'atap', 'engsel', 'spanduk', 'meja', 'bagel')):
        return 'MATERIAL'
    return mapping.get('categories', {}).get('wakaf', {}).get(category) or mapping['default_category'][lookup_key(row.get('flow'))]


def _activity_code(row: pd.Series, source_type: str, mapping: dict) -> str | None:
    field = row.get('event') if source_type == 'INFAQ' else row.get('category')
    return mapping.get('activities', {}).get(source_type.lower(), {}).get(lookup_key(field))


def normalize_row(row: pd.Series, source_type: str, mapping: dict) -> dict:
    external_id = clean_text(row.get('external_id'))
    if not external_id:
        raise ValueError('missing external ID')
    source_prefix = 'INF' if source_type == 'INFAQ' else 'WKF'
    if not re.fullmatch(rf'{source_prefix}\d+', external_id, flags=re.IGNORECASE):
        raise ValueError(f'invalid external ID: {external_id!r}')
    flow = lookup_key(row.get('flow'))
    transaction_type = flow.upper()
    if transaction_type not in {'INCOME', 'EXPENSE'}:
        raise ValueError('flow must be Income or Expense')
    description = clean_text(row.get('description')) or clean_text(row.get('event')) or clean_text(row.get('category'))
    if not description:
        raise ValueError('missing description')
    source_vendor = clean_text(row.get('vendor')) if source_type == 'WAKAF' else None
    if source_vendor in {'-', '??????', 'admin bank'}:
        source_vendor = None
    return {
        'external_id': external_id,
        'transaction_date': parse_date(row.get('tanggal')),
        'fund_code': source_type,
        'category_code': _category_code(row, source_type, mapping),
        'activity_code': _activity_code(row, source_type, mapping),
        'activity_name': clean_text(row.get('event')) if source_type == 'INFAQ' else clean_text(row.get('category')),
        'transaction_type': transaction_type,
        'amount': source_amount(row, source_type),
        'description': description,
        'vendor_name': source_vendor,
        'person_name': clean_person_name(row.get('pic') or row.get('note')) if source_type == 'INFAQ' else clean_person_name(row.get('vendor')),
        'account_alias': clean_text(row.get('account_type')) if source_type == 'WAKAF' else None,
        'reference_number': clean_text(row.get('nota')) if source_type == 'WAKAF' else None,
        'reimbursement': lookup_key(row.get('reimburse')) if source_type == 'INFAQ' else None,
        'notes': clean_text(row.get('note')) or clean_text(row.get('remark')),
        'raw_payload': row.to_dict(),
    }


def normalize_frame(frame: pd.DataFrame, source_type: str, mapping: dict) -> tuple[list[dict], list[dict]]:
    normalized: list[dict] = []
    errors: list[dict] = []
    seen_ids: set[str] = set()
    for source_row, (_, row) in enumerate(frame.iterrows(), start=2):
        if not clean_text(row.get('external_id')):
            continue
        if not any(clean_text(row.get(column)) for column in ('flow', 'tanggal', 'kredit', 'debit')):
            continue
        try:
            record = normalize_row(row, source_type, mapping)
            if record['external_id'] in seen_ids:
                raise ValueError(f'duplicate external ID: {record["external_id"]}')
            seen_ids.add(record['external_id'])
            normalized.append(record)
        except ValueError as exc:
            errors.append({'source_row': source_row, 'external_id': clean_text(row.get('external_id')), 'error_message': str(exc), 'raw_payload': row.to_dict()})
    return normalized, errors
