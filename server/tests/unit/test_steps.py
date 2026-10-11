from datetime import date

import pytest

from stepquest.steps import coins, date_range


@pytest.mark.parametrize("total, expected", [
    (0, 0), (999, 0), (1000, 10), (1999, 10), (2500, 20), (100_000, 1000),
])
def test_coins(total, expected):
    assert coins(total) == expected


def test_today_range():
    d = date(2026, 10, 10)
    assert date_range("today", d) == (d, d)


def test_week_is_last_7_days():
    assert date_range("week", date(2026, 10, 10)) == (date(2026, 10, 4), date(2026, 10, 10))


def test_unknown_range():
    with pytest.raises(ValueError):
        date_range("year")
