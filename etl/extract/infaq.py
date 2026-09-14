from pathlib import Path
import csv

import pandas as pd


INFAQ_COLUMNS = [
    'no_text', 'flow', 'kredit', 'debit', 'tanggal', 'bulan', 'event',
    'description', 'pic', 'reimbursement', 'remark', 'reimburse', 'saldo',
    'note', 'external_id', 'unused_1', 'unused_2', 'summary_income',
    'summary_expense', 'unused_3', 'summary_month', 'summary_event',
    'summary_total_kredit', 'summary_total_debit', 'summary_total',
]


def read_infaq(path: str | Path) -> pd.DataFrame:
    """Read the source-shaped INFAQ sheet without interpreting summary columns."""
    with Path(path).open(newline='', encoding='utf-8-sig') as handle:
        rows = list(csv.reader(handle))
    if rows and len(rows[0]) == 1 and ',' in rows[0][0]:
        rows = [next(csv.reader([row[0]])) for row in rows]
    frame = pd.DataFrame(rows)
    if len(frame.columns) != len(INFAQ_COLUMNS):
        raise ValueError(f'INFAQ source has {len(frame.columns)} columns; expected {len(INFAQ_COLUMNS)}')
    frame = frame.iloc[1:].copy()
    frame.columns = INFAQ_COLUMNS
    return frame.fillna('')
