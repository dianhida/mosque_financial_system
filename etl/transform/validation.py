from __future__ import annotations

from decimal import Decimal


def validate_transaction(record: dict) -> None:
    required = ('external_id', 'transaction_date', 'fund_code', 'category_code', 'transaction_type', 'description')
    missing = [field for field in required if not record.get(field)]
    if missing:
        raise ValueError(f'missing normalized fields: {", ".join(missing)}')
    if record['transaction_type'] not in {'INCOME', 'EXPENSE'}:
        raise ValueError('transaction_type must be INCOME or EXPENSE')
    if not isinstance(record['amount'], Decimal) or record['amount'] <= 0:
        raise ValueError('amount must be a positive Decimal')
