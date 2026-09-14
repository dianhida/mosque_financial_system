from pathlib import Path
import csv

import pandas as pd


WAKAF_COLUMNS = [
    'no_text', 'flow', 'account_type', 'kredit', 'debit', 'tanggal',
    'category', 'description', 'nota', 'vendor', 'donator', 'external_id',
    'unused_1', 'unused_2', 'summary_income', 'summary_expense', 'unused_3',
    'target', 'kekurangan', 'unused_4', 'unused_5', 'balance_label',
    'tahap_satu', 'target_final',
]


def read_wakaf(path: str | Path) -> pd.DataFrame:
    """Read the source-shaped WAKAF sheet without interpreting summary columns."""
    with Path(path).open(newline='', encoding='utf-8-sig') as handle:
        rows = list(csv.reader(handle))
    if rows and len(rows[0]) == 1 and ',' in rows[0][0]:
        rows = [next(csv.reader([row[0]])) for row in rows]
    frame = pd.DataFrame(rows)
    if len(frame.columns) != len(WAKAF_COLUMNS):
        raise ValueError(f'WAKAF source has {len(frame.columns)} columns; expected {len(WAKAF_COLUMNS)}')
    frame = frame.iloc[1:].copy()
    frame.columns = WAKAF_COLUMNS
    return frame.fillna('')
