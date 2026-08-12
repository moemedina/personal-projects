# %% [markdown]
# Explanation: 02_debugging_exercise.py
#
# ROOT CAUSE: mutable default argument.
#
#     def flag_suspicious_trades(trades, window=3, threshold_pct=5.0, history=[]):
#
# `history=[]` is evaluated ONCE, when the function is defined — not once
# per call. Every call that doesn't explicitly pass `history` shares that
# *same* list object. batch_1's four trades never get cleared, so batch_2
# starts with them still sitting at the front of `history`.
#
# Debugger trail that would have surfaced this in ~2 minutes:
#   - Breakpoint on `recent = ...` inside the loop, stepped through batch_2's
#     first trade.
#   - `history` at that point has length 5, not 1 — immediate red flag,
#     since batch_2 was supposed to start fresh.
#   - `id(history)` compared across the batch_1 and batch_2 calls is
#     identical -> confirms it's the same object, not a copy.
#
# THE FIX: never use a mutable default argument. Default to None and create
# the list inside the function.

# %%
from dataclasses import dataclass


@dataclass
class Trade:
    symbol: str
    price: float


def flag_suspicious_trades(trades, window: int = 3, threshold_pct: float = 5.0, history=None):
    if history is None:
        history = []
    flagged = []
    for trade in trades:
        history.append(trade)
        recent = [t.price for t in history if t.symbol == trade.symbol][-window:]
        avg = sum(recent) / len(recent)
        deviation_pct = abs(trade.price - avg) / avg * 100
        if deviation_pct > threshold_pct:
            flagged.append(trade)
    return flagged


# %%
batch_1 = [Trade("BTC", 61000), Trade("BTC", 61050), Trade("BTC", 61100), Trade("BTC", 61080)]
batch_2 = [Trade("BTC", 80000), Trade("BTC", 80050)]

assert flag_suspicious_trades(batch_1) == []
assert flag_suspicious_trades(batch_2) == []  # now correctly clean
print("fixed")

# %% [markdown]
# Second-order issue worth mentioning out loud even though it's not the
# reported bug: `history` also grows unbounded for the lifetime of the
# process even after the fix removes cross-call contamination — if this
# were a real service, per-symbol history should be trimmed to `window` (or
# the caller should own history's lifetime explicitly) rather than an
# ever-growing list, which is what let the stale-data bug hide in the first
# place. A good answer flags this even if the interviewer only asked about
# the flagging bug.
