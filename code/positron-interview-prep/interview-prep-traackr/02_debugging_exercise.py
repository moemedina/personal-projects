# %% [markdown]
# MOCK DEBUGGING EXERCISE (~15-20 min)
#
# Scenario handed to you: "This function is supposed to flag suspicious
# trades — ones whose price jumps more than `threshold_pct` from the
# rolling average of the last `window` trades for that symbol. QA says it's
# flagging way too many normal trades as suspicious. Find out why and fix
# it."
#
# Rules for the drill:
#   1. Don't just read the code and spot it by eye (you may — but practice
#      the process too). Use the Positron debugger: set a breakpoint inside
#      `flag_suspicious_trades`, run the cell in Debug mode, step through
#      with the sample data below, inspect variables at each step.
#   2. Narrate: "here's what I expect this variable to be... here's what it
#      actually is... that's the divergence."
#   3. Only after you've found and understood the root cause, check
#      02_SOLUTION.py for the explanation.

# %%
from dataclasses import dataclass


@dataclass
class Trade:
    symbol: str
    price: float


def flag_suspicious_trades(trades: list[Trade], window: int = 3, threshold_pct: float = 5.0, history=[]):
    """Return the list of trades whose price deviates from the trailing
    rolling average (per symbol) by more than threshold_pct percent."""
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
# Run 1: looks fine in isolation.
batch_1 = [
    Trade("BTC", 61000),
    Trade("BTC", 61050),
    Trade("BTC", 61100),
    Trade("BTC", 61080),
]
print("batch 1 flagged:", flag_suspicious_trades(batch_1))

# %%
# Run 2: a *separate* request, later, after BTC has genuinely moved to a
# new price level (think: next trading day). Nothing suspicious happens
# inside this batch on its own — prices are flat around 80000, moving
# ~0.06% trade to trade. QA's bug report reproduces here: put your
# breakpoint above and step through THIS call.
batch_2 = [
    Trade("BTC", 80000),
    Trade("BTC", 80050),
]
print("batch 2 flagged:", flag_suspicious_trades(batch_2))
# Expected by QA: [] (nothing suspicious). Actual: both trades flagged.
