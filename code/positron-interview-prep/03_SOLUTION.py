# %% [markdown]
# Reference solution for 03_coding_exercise_eval_harness.py

# %%
def score(predictions: dict[str, bool], golden: dict[str, bool]) -> dict:
    ids = predictions.keys() & golden.keys()
    tp = sum(1 for i in ids if predictions[i] and golden[i])
    fp = sum(1 for i in ids if predictions[i] and not golden[i])
    fn = sum(1 for i in ids if not predictions[i] and golden[i])

    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) else 0.0

    return {"precision": precision, "recall": recall, "f1": f1, "n": len(ids)}


def error_analysis(predictions: dict[str, bool], golden: dict[str, bool]) -> dict:
    ids = predictions.keys() & golden.keys()
    return {
        "false_positives": sorted(i for i in ids if predictions[i] and not golden[i]),
        "false_negatives": sorted(i for i in ids if not predictions[i] and golden[i]),
    }


def check_regression(current: dict, baseline: dict, tolerance: float = 0.02) -> list[str]:
    regressed = []
    for metric in baseline:
        if metric == "n":
            continue
        if metric in current and current[metric] < baseline[metric] - tolerance:
            regressed.append(metric)
    return regressed


# %%
golden = {"p1": True, "p2": True, "p3": False, "p4": False, "p5": True}
predictions = {"p1": True, "p2": False, "p3": False, "p4": True, "p5": True}

metrics = score(predictions, golden)
assert metrics == {"precision": 2 / 3, "recall": 2 / 3, "f1": 2 / 3, "n": 5}

errors = error_analysis(predictions, golden)
assert errors == {"false_positives": ["p4"], "false_negatives": ["p2"]}

regressed = check_regression(metrics, {"precision": 0.9, "recall": 0.9, "f1": 0.9})
assert set(regressed) == {"precision", "recall", "f1"}

assert score({}, golden) == {"precision": 0.0, "recall": 0.0, "f1": 0.0, "n": 0}
print("ok")

# %% [markdown]
# Follow-up talking points — these matter more than the code for this
# particular role, so rehearse them out loud, not just the implementation:
#
# - Exact-match labels -> LLM free text: precision/recall on booleans
#   doesn't transfer directly. Options: (a) constrain the LLM to structured
#   output (a schema/enum) so you're back to exact-match scoring, (b) use a
#   rubric-based LLM-as-judge with a *human-validated* sample to check the
#   judge itself isn't drifting, (c) semantic similarity as a soft signal,
#   never the sole gate. Say explicitly that you'd validate the judge against
#   human labels before trusting it, not just assume it works.
#
# - Building the golden set: stratified sampling across known hard cases
#   (ambiguous brand mentions, sarcasm, multiple brands in one post), not
#   just random sampling — random sampling under-represents the cases that
#   actually break the model. Keep it versioned, re-review periodically as
#   the product/label definition shifts (label drift, not just model drift).
#
# - Offline regression check vs. production monitoring: offline is a gate
#   *before* ship — deterministic, same golden set every run, blocks a bad
#   deploy. Production monitoring is continuous, on live unlabeled traffic —
#   proxy signals (prediction distribution shift, confidence scores, sampled
#   human review) since you don't have ground truth in real time. Mention
#   alerting/rollback as the natural next step from "detects drift" to
#   "acts on it."
