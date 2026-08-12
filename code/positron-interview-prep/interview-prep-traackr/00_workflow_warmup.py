# %% [markdown]
# WARMUP: Positron workflow drill (Databricks -> Positron muscle memory)
#
# Goal: run through this file top to bottom using ONLY these actions, until
# they feel automatic:
#   - Ctrl+Enter        run current line/cell, cursor stays
#   - Shift+Enter       run current line/cell, cursor advances to next
#   - Click a variable in the "Variables" pane (top right) to inspect it
#   - Click a DataFrame variable's magnifying-glass/table icon to open the
#     Data Viewer (this is your `display(df)` replacement)
#   - The "#%%" marker below turns this .py file into Jupyter-style cells.
#     Positron shows a "Run Cell" / "Run Cell and Advance" codelens above
#     each one, same idea as a Databricks command cell.
#
# Do this drill BEFORE the interview, live, in Positron. Not by reading it.

# %%
import pandas as pd
import numpy as np

# %%
# This is one "cell". Run it with Ctrl+Enter.
# Notice: no display()/print() needed to inspect `x` — check the Variables pane.
x = 42
y = [i**2 for i in range(10)]

# %%
# DataFrames: build one, then open it in the Data Viewer instead of print().
df = pd.DataFrame({
    "symbol": ["BTC", "ETH", "BTC", "SOL", "ETH", "BTC"],
    "price": [61000, 3400, 61250, 145, 3420, 61500],
    "volume": [1.2, 8.4, 0.5, 40.0, 6.1, 2.3],
})
df["notional"] = df["price"] * df["volume"]
df

# %%
# Plots pane: run this, confirm the chart shows up in the Plots tab, not inline.
import matplotlib.pyplot as plt

df.groupby("symbol")["notional"].sum().plot(kind="bar")
plt.title("Notional volume by symbol")
plt.show()

# %%
# Debugger drill: set a breakpoint on the `return` line below (click the
# gutter, left of the line number), then run this cell with the "Debug Cell"
# codelens (not plain Run Cell). Step over/into with F10/F11, inspect
# `running_total` in the Variables pane while paused.
def cumulative_notional(frame: pd.DataFrame) -> float:
    running_total = 0.0
    for notional in frame["notional"]:
        running_total += notional
    return running_total


cumulative_notional(df)

# %%
# Console vs Terminal: this executed in the Console (Python process, keeps
# your variables alive). The Terminal tab is a plain shell — pip installs,
# git, running a whole script with `python file.py`, nothing that needs `df`.
#
# Once steps above feel boring/automatic, move to 01_coding_exercise.py.

# %% 
# Trying a new cell 
mario = 5*8