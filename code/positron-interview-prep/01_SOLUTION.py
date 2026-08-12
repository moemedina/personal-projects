# %% [markdown]
# Reference solution for 01_coding_exercise.py — one reasonable approach,
# not "the" answer. Compare your design, don't just copy it.
#
# Design choice: a dict[symbol -> list[Trade]] kept sorted by timestamp
# (append-mostly, since late trades are only a few seconds late — insert
# near the end via a short backward scan rather than a full sort).
# moving_average / top_symbols_by_volume do a linear scan over the relevant
# window; that's O(k) per query where k = trades in window, which is fine
# unless queries vastly outnumber writes (see follow-up notes at bottom).

# %%
from bisect import insort
from collections import defaultdict
from dataclasses import dataclass, field


@dataclass
class Trade:
    timestamp: int
    symbol: str
    price: float
    volume: float


class TradeAnalyzer:
    def __init__(self):
        self._by_symbol: dict[str, list[Trade]] = defaultdict(list)

    def add_trade(self, timestamp: int, symbol: str, price: float, volume: float) -> None:
        trade = Trade(timestamp, symbol, price, volume)
        trades = self._by_symbol[symbol]
        # trades arrive nearly-sorted; insert to keep the list sorted by ts
        insort(trades, trade, key=lambda t: t.timestamp)

    def _in_window(self, symbol: str, window_seconds: int, as_of: int):
        lo = as_of - window_seconds
        for t in self._by_symbol.get(symbol, []):
            if lo < t.timestamp <= as_of:
                yield t

    def moving_average(self, symbol: str, window_seconds: int, as_of: int):
        num = 0.0
        den = 0.0
        for t in self._in_window(symbol, window_seconds, as_of):
            num += t.price * t.volume
            den += t.volume
        return num / den if den else None

    def top_symbols_by_volume(self, n: int, as_of: int, window_seconds: int) -> list[str]:
        totals: dict[str, float] = {}
        for symbol in self._by_symbol:
            vol = sum(t.volume for t in self._in_window(symbol, window_seconds, as_of))
            if vol > 0:
                totals[symbol] = vol
        ranked = sorted(totals.items(), key=lambda kv: (-kv[1], kv[0]))
        return [symbol for symbol, _ in ranked[:n]]


# %%
analyzer = TradeAnalyzer()
analyzer.add_trade(100, "BTC", 61000, 1.0)
analyzer.add_trade(101, "ETH", 3400, 5.0)
analyzer.add_trade(105, "BTC", 61200, 0.5)

assert round(analyzer.moving_average("BTC", window_seconds=10, as_of=105), 2) == round(
    (61000 * 1.0 + 61200 * 0.5) / 1.5, 2
)
assert analyzer.top_symbols_by_volume(n=2, as_of=105, window_seconds=10) == ["ETH", "BTC"]
print("ok")

# %% [markdown]
# Follow-up talking points (say these even if not asked):
#
# - If moving_average is called far more than add_trade: precompute a
#   running prefix sum of (price*volume) and volume per symbol, indexed by
#   time, so the window query becomes O(log k) via binary search on
#   timestamps instead of O(k) linear scan. Trade-off: more bookkeeping on
#   every write, and window edges need care with the prefix-sum approach.
#
# - Multi-threaded add_trade: the per-symbol list mutation needs a lock (or
#   a lock-free structure); reads (moving_average) either take a read lock
#   or tolerate slightly stale data depending on requirements — ask which.
#
# - Testing: unit tests per method (empty window, single trade, trade
#   exactly at the window boundary — is `as_of - window_seconds` inclusive
#   or exclusive? this problem statement fixed that as exclusive lower /
#   inclusive upper, and that's exactly the kind of boundary an interviewer
#   will probe), plus a property-style test that moving_average with a huge
#   window equals a plain average over everything.
