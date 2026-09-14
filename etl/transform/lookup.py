from __future__ import annotations


def master_name_for_code(code: str) -> str:
    return {
        'OPENING_BALANCE': 'Opening Balance',
        'INFAQ': 'Infaq',
        'DONATION': 'Donation',
        'OPERATIONAL': 'Operational',
        'KAJIAN': 'Kajian',
        'EQUIPMENT': 'Equipment',
        'SOCIAL': 'Social',
        'TPA': 'TPA',
        'QURBAN': 'Qurban',
        'BANK_ADMINISTRATION': 'Bank Administration',
        'MATERIAL': 'Material',
        'LABOR': 'Labor',
        'OTHER_INCOME': 'Other Income',
        'OTHER_EXPENSE': 'Other Expense',
    }.get(code, code.replace('_', ' ').title())
