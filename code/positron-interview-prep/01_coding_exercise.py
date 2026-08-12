# %% [markdown]
# MOCK LIVE-CODING EXERCISE (~30-35 min, talk out loud the whole time)
#
# Set a timer. Do NOT look at SOLUTIONS.py until you've either finished or
# genuinely stalled for 5+ minutes. Narrate as if an interviewer is
# listening: state assumptions, name edge cases before you hit them, think
# about complexity out loud.
#
# ---------------------------------------------------------------------------
# PROBLEM: TradeAnalyzer
#
# You're building a small in-memory component for a crypto exchange that
# ingests a live stream of trades and answers rolling analytics queries.
#
# A trade is (timestamp: int seconds, symbol: str, price: float, volume: float)
#
# Implement a class `TradeAnalyzer` with:
#
#   1. add_trade(timestamp, symbol, price, volume) -> None
#        Record a trade. Trades may arrive slightly out of order (timestamps
#        are not guaranteed strictly increasing), but never more than a few
#        seconds late.
#
#   2. moving_average(symbol, window_seconds, as_of) -> float | None
#        Volume-weighted average price for `symbol` over trades with
#        as_of - window_seconds < timestamp <= as_of.
#        Return None if there are no trades for that symbol in the window.
#
#   3. top_symbols_by_volume(n, as_of, window_seconds) -> list[str]
#        The n symbols with the highest total volume traded in the window,
#        ordered descending. Ties broken alphabetically.
#
# Interviewer follow-ups to expect (think about these as you design):
#   - What's the time complexity of each call, and how would you improve it
#     if `moving_average` is called far more often than `add_trade`?
#   - How would this change if trades arrive from multiple threads?
#   - How would you test this?
#
# Start simple and correct. Optimize only after it works and you've said
# out loud what the bottleneck is.
# ---------------------------------------------------------------------------

# %%
from collections import defaultdict
from dataclasses import dataclass


@dataclass
class Trade:
    timestamp: int
    symbol: str
    price: float
    volume: float


class TradeAnalyzer:
    def __init__(self):
        # TODO: pick your data structure(s)
        pass

    def add_trade(self, timestamp: int, symbol: str, price: float, volume: float) -> None:
        # TODO
        pass

    def moving_average(self, symbol: str, window_seconds: int, as_of: int):
        # TODO
        pass

    def top_symbols_by_volume(self, n: int, as_of: int, window_seconds: int) -> list[str]:
        # TODO
        pass


# %%
# Scratch area — build a quick manual test as you go (this IS how you'd do
# it live: small example, run it, eyeball the result, adjust).
analyzer = TradeAnalyzer()
analyzer.add_trade(100, "BTC", 61000, 1.0)
analyzer.add_trade(101, "ETH", 3400, 5.0)
analyzer.add_trade(105, "BTC", 61200, 0.5)

print(analyzer.moving_average("BTC", window_seconds=10, as_of=105))
print(analyzer.top_symbols_by_volume(n=2, as_of=105, window_seconds=10))
