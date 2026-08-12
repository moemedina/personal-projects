# %% [markdown]
# MOCK LIVE-CODING EXERCISE #2 — role-specific (~25-30 min)
#
# Why this one: the JD explicitly calls out "establish best-in-class
# evaluation practices... golden datasets, offline/online evaluation plans,
# regression suites... error analysis" as a core responsibility, and this
# round is with a Principal Engineer — expect emphasis on clean, testable
# code over algorithmic cleverness. This is the single most likely *shape*
# of problem for that combination.
#
# ---------------------------------------------------------------------------
# PROBLEM: EvalHarness
#
# Traackr classifies social posts as "brand-relevant" or not (binary). You're
# building the harness that scores a model's predictions against a hand-
# labeled golden set, and flags when a new model version regresses vs. the
# last known-good baseline — the core loop of a regression suite.
#
# Implement:
#
#   1. score(predictions: dict[str, bool], golden: dict[str, bool]) -> dict
#        Returns {"precision": float, "recall": float, "f1": float, "n": int}
#        over the ids common to both dicts. Handle the zero-denominator
#        edge cases (no predicted positives, no actual positives) explicitly
#        — don't let them raise ZeroDivisionError.
#
#   2. error_analysis(predictions, golden) -> dict
#        Returns {"false_positives": [ids], "false_negatives": [ids]} —
#        exactly the ids a human reviewer would want to look at first.
#
#   3. check_regression(current: dict, baseline: dict, tolerance: float = 0.02) -> list[str]
#        Compares current vs. baseline metrics (same keys as score()'s
#        output, minus "n"). Returns the names of metrics that dropped by
#        more than `tolerance` (absolute). Empty list = safe to ship.
#
# Interviewer follow-ups to expect (rehearse answering these out loud):
#   - This is precision/recall on exact-match labels. How would this change
#     for an LLM-generated free-text output instead of a binary label?
#   - How would you build the golden set in the first place, and keep it
#     trustworthy as the product evolves?
#   - What's the difference between this offline regression check and what
#     you'd monitor once the model is live in production?
# ---------------------------------------------------------------------------

# %%
def score(predictions: dict[str, bool], golden: dict[str, bool]) -> dict:
    # TODO
    pass


def error_analysis(predictions: dict[str, bool], golden: dict[str, bool]) -> dict:
    # TODO
    pass


def check_regression(current: dict, baseline: dict, tolerance: float = 0.02) -> list[str]:
    # TODO
    pass


# %%
# Scratch area — build this as you go.
golden = {"p1": True, "p2": True, "p3": False, "p4": False, "p5": True}
predictions = {"p1": True, "p2": False, "p3": False, "p4": True, "p5": True}

metrics = score(predictions, golden)
print(metrics)
print(error_analysis(predictions, golden))
print(check_regression(metrics, {"precision": 0.9, "recall": 0.9, "f1": 0.9}))
