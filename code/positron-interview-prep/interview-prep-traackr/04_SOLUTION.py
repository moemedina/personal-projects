# %% [markdown]
# Reference solution for 04_agent_eval_build.py

# %%
from abc import ABC, abstractmethod
from dataclasses import dataclass
import json
import re


class LLMClient(ABC):
    @abstractmethod
    def complete(self, prompt: str) -> str:
        ...


class MockLLMClient(LLMClient):
    POSITIVE = ["love", "great", "happy", "appreciate", "intuitive", "better", "resolve", "quick", "nice", "easy", "good"]
    NEGATIVE = ["crash", "disappointed", "crushed", "leaking", "frustrating", "clump", "too strong", "cheaper", "asap", "no response"]

    def complete(self, prompt: str) -> str:
        text = prompt.lower()
        pos = sum(1 for w in self.POSITIVE if w in text)
        neg = sum(1 for w in self.NEGATIVE if w in text)
        category = "bad" if neg > pos else "good"
        match = re.search(r'Feedback: "(.*)"', prompt)
        excerpt = match.group(1) if match else prompt
        summary = excerpt if len(excerpt) <= 60 else excerpt[:57] + "..."
        return json.dumps({"category": category, "summary": summary})


@dataclass
class FeedbackEntry:
    id: str
    industry: str
    text: str


@dataclass
class ClassificationResult:
    id: str
    category: str
    summary: str


class FeedbackAgent:
    def __init__(self, llm: LLMClient):
        self.llm = llm

    def classify_and_summarize(self, entry: FeedbackEntry) -> ClassificationResult:
        prompt = (
            "Classify this customer feedback as 'good' (keep doing) or "
            "'bad' (actionable), and summarize it in one short sentence.\n"
            f"Industry: {entry.industry}\n"
            f'Feedback: "{entry.text}"\n'
            'Respond as JSON: {"category": "good"|"bad", "summary": "..."}'
        )
        raw = self.llm.complete(prompt)
        parsed = json.loads(raw)
        return ClassificationResult(id=entry.id, category=parsed["category"], summary=parsed["summary"])

    def run_batch(self, entries: list[FeedbackEntry]) -> dict:
        results = [self.classify_and_summarize(e) for e in entries]
        by_category = {"good": [], "bad": []}
        for r in results:
            by_category[r.category].append(r)
        return {"results": results, "by_category": by_category}


# %%
SAMPLE_ENTRIES = [
    FeedbackEntry("b1", "beauty", "Absolutely love the new matte lipstick formula, it lasts all day without drying my lips out!"),
    FeedbackEntry("b2", "beauty", "The mascara clumps really badly after just one use, very disappointed."),
    FeedbackEntry("b3", "beauty", "Customer service was quick to resolve my shipping issue, very happy with the support."),
    FeedbackEntry("b4", "beauty", "Packaging arrived crushed and the product inside was leaking everywhere."),
    FeedbackEntry("b5", "beauty", "The scent is nice but honestly a bit too strong for daily wear."),
    FeedbackEntry("t1", "technology", "The onboarding flow for the new app update is so intuitive, great job simplifying it."),
    FeedbackEntry("t2", "technology", "App keeps crashing every time I try to export my data, this needs to be fixed ASAP."),
    FeedbackEntry("t3", "technology", "Battery life on the latest firmware update is noticeably better, really appreciate it."),
    FeedbackEntry("t4", "technology", "Support ticket has been open for two weeks with no response, extremely frustrating."),
    FeedbackEntry("t5", "technology", "Great product, wish it was cheaper though."),
]

GOLDEN = {
    "b1": "good", "b2": "bad", "b3": "good", "b4": "bad", "b5": "bad",
    "t1": "good", "t2": "bad", "t3": "good", "t4": "bad", "t5": "good",
}


def eval_classifications(results: list[ClassificationResult], golden: dict, positive_label: str = "bad") -> dict:
    preds = {r.id: r.category for r in results}
    ids = preds.keys() & golden.keys()
    tp = sum(1 for i in ids if preds[i] == positive_label and golden[i] == positive_label)
    fp = sum(1 for i in ids if preds[i] == positive_label and golden[i] != positive_label)
    fn = sum(1 for i in ids if preds[i] != positive_label and golden[i] == positive_label)
    correct = sum(1 for i in ids if preds[i] == golden[i])

    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) else 0.0
    accuracy = correct / len(ids) if ids else 0.0

    return {"precision": precision, "recall": recall, "f1": f1, "accuracy": accuracy, "n": len(ids)}


def error_analysis(results: list[ClassificationResult], golden: dict) -> dict:
    preds = {r.id: r.category for r in results}
    ids = preds.keys() & golden.keys()
    return {
        "false_positives": sorted(i for i in ids if preds[i] == "bad" and golden[i] != "bad"),
        "false_negatives": sorted(i for i in ids if preds[i] != "bad" and golden[i] == "bad"),
    }


# %%
agent = FeedbackAgent(MockLLMClient())
batch = agent.run_batch(SAMPLE_ENTRIES)

metrics = eval_classifications(batch["results"], GOLDEN)
errors = error_analysis(batch["results"], GOLDEN)
print(metrics)
print(errors)

assert metrics["precision"] == 1.0
assert round(metrics["recall"], 4) == 0.8
assert round(metrics["accuracy"], 4) == 0.9
assert errors == {"false_positives": [], "false_negatives": ["b5"]}
print("ok — the naive keyword mock misses b5 (hedged negative: 'nice but... too strong'),"
      " which is exactly the kind of error a real judge/harness exists to catch.")

# %% [markdown]
# Talking points for the live interview — say these, don't just code them:
#
# - **Why `LLMClient` as an interface, not a direct call**: swapping
#   `MockLLMClient` for a real Anthropic client is a one-class change;
#   `FeedbackAgent` never changes. Also means you can unit-test the agent's
#   logic (prompt construction, batching, aggregation) without hitting a
#   real API, paying for tokens, or being at the mercy of latency during a
#   demo — a real production concern, not just a testing nicety.
#
# - **Why structured JSON output**: parsing free text from an LLM is
#   fragile. Real implementation would use the provider's structured-output
#   / tool-calling mode to *guarantee* the shape, not just ask nicely for
#   JSON in the prompt and hope.
#
# - **Why recall on "bad" is the metric to protect, not accuracy**: missing
#   an actionable complaint (false negative) is worse than over-flagging a
#   positive review for review (false positive) — a human skimming the
#   "bad" bucket costs a minute; a missed actionable complaint costs a
#   customer. Say this explicitly if asked "which metric matters most."
#
# - **The judge needs its own validation**: before trusting an LLM-judge's
#   score, check it against a small human-labeled sample — same idea as
#   this whole exercise, one level up. An unvalidated judge is just vibes
#   with a JSON schema.
#
# - **What's descoped and why**: datalake ingestion, batch orchestration,
#   the vector-search RAG chatbot, a second judge for chatbot responses,
#   and cost/latency telemetry are all real parts of the system — they're
#   the whiteboard narrative, not the live-typed code, because an hour
#   doesn't fit both a system and a demo of the system.
