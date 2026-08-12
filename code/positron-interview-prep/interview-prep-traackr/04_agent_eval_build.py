# %% [markdown]
# CONFIRMED LIVE TASK (~1 hour, real interview): "Build a small agent and an
# evaluation pipeline for it — live. We're less interested in a polished
# final product and more in how you think through the architecture."
#
# Agent: classify customer feedback as "good" (keep doing) or "bad"
# (actionable), then summarize it. Eval: measure whether the classification
# is any good.
#
# THIS FILE IS THE NARROW SLICE YOU ACTUALLY TYPE LIVE. The datalake
# ingestion, batch orchestration, vector-search RAG chatbot, and second
# judge stay in your verbal architecture walkthrough — see PROMPTS_agent_eval_live.md
# and the field-guide artifact for how to frame that split explicitly.
#
# Rehearse this file cold, then check 04_SOLUTION.py.

# %%
from abc import ABC, abstractmethod
from dataclasses import dataclass
import json
import re


class LLMClient(ABC):
    """The seam that makes the real model call swappable. Everything below
    this line only ever talks to this interface — never to a concrete
    provider — so `MockLLMClient` here becomes `AnthropicClient` later
    without touching FeedbackAgent."""

    @abstractmethod
    def complete(self, prompt: str) -> str:
        ...


class MockLLMClient(LLMClient):
    """Deterministic keyword-based stand-in — NOT a real LLM. Lets the
    agent + eval harness run with no API key, which is realistically what
    you'd also want live if the sandbox doesn't have one wired up."""

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
    industry: str  # "beauty" | "technology"
    text: str


@dataclass
class ClassificationResult:
    id: str
    category: str  # "good" | "bad"
    summary: str


class FeedbackAgent:
    """TODO: implement using self.llm — don't call MockLLMClient directly
    inside these methods, only through the LLMClient interface."""

    def __init__(self, llm: LLMClient):
        self.llm = llm

    def classify_and_summarize(self, entry: FeedbackEntry) -> ClassificationResult:
        # TODO: build the prompt, call self.llm.complete(), parse the JSON
        # response, return a ClassificationResult.
        pass

    def run_batch(self, entries: list[FeedbackEntry]) -> dict:
        # TODO: classify every entry, return
        # {"results": [...], "by_category": {"good": [...], "bad": [...]}}
        pass


# %%
# Golden set — hand-labeled, deliberately includes one hedged/ambiguous
# entry (b5) that a naive classifier plausibly gets wrong. That's the point:
# a harness that always scores 100% isn't rehearsing anything.
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
    # TODO: precision / recall / f1 / accuracy, treating `positive_label`
    # ("bad" — the actionable class) as the positive class. Think about
    # WHY recall on "bad" matters more than raw accuracy for this product.
    pass


def error_analysis(results: list[ClassificationResult], golden: dict) -> dict:
    # TODO: return {"false_positives": [ids], "false_negatives": [ids]} —
    # same shape as 03_SOLUTION.py, applied to this task.
    pass


# %%
agent = FeedbackAgent(MockLLMClient())
batch = agent.run_batch(SAMPLE_ENTRIES)
print(batch)

metrics = eval_classifications(batch["results"], GOLDEN)
print(metrics)
print(error_analysis(batch["results"], GOLDEN))
