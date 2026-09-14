from __future__ import annotations

import json

import pandas as pd
from sqlalchemy import text


INFAQ_COLUMNS = [
    'no_text', 'flow', 'kredit', 'debit', 'tanggal', 'bulan', 'event',
    'description', 'pic', 'reimbursement', 'remark', 'reimburse', 'saldo',
    'note', 'external_id', 'summary_income', 'summary_expense', 'summary_month',
    'summary_event', 'summary_total_kredit', 'summary_total_debit', 'summary_total',
]
WAKAF_COLUMNS = [
    'no_text', 'flow', 'account_type', 'kredit', 'debit', 'tanggal', 'category',
    'description', 'nota', 'vendor', 'donator', 'external_id', 'summary_income',
    'summary_expense', 'target', 'kekurangan', 'balance_label', 'balance_update_manual',
    'tahap_satu', 'target_final',
]


def load_raw_rows(connection, frame: pd.DataFrame, source_type: str, batch_id: int) -> None:
    table = 'staging.infaq_raw' if source_type == 'INFAQ' else 'staging.wakaf_raw'
    columns = INFAQ_COLUMNS if source_type == 'INFAQ' else WAKAF_COLUMNS
    for source_row, (_, row) in enumerate(frame.iterrows(), start=2):
        values = {column: (str(row.get(column, '')).strip() or None) for column in columns}
        payload = {key: (value if value != '' else None) for key, value in row.to_dict().items()}
        values.update({'batch_id': batch_id, 'source_row': source_row, 'raw_payload': json.dumps(payload, ensure_ascii=True)})
        names = ', '.join(values)
        binds = ', '.join(f':{name}' for name in values)
        connection.execute(text(f'INSERT INTO {table} ({names}) VALUES ({binds})'), values)
