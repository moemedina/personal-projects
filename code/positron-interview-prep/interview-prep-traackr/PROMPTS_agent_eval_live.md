# Live-session prompt playbook — agent + eval pipeline build

Paste-ready prompts for the actual interview. Each one has a one-line note
on when to reach for it. Read them once before the call so you're adapting,
not reading them cold under pressure.

Remember: they explicitly asked you to narrate the prompt *and* how you
validate the output. The validation sentence after each answer matters as
much as the prompt itself.

---

### 1. Scaffold the structure (use in the first ~5 min of live coding)

> I'm building a small agent that classifies customer feedback as "good"
> (keep doing) or "bad" (actionable), then summarizes it. Give me a minimal
> Python structure: an `LLMClient` interface with one `complete(prompt) ->
> str` method, a `FeedbackAgent` class that uses it, and dataclasses for the
> input/output. No implementation of the LLM call itself — I'll mock it so
> I can test without an API key. Keep it to what I could reasonably write
> in 10 minutes.

**Validate:** read every line before running it; confirm the interface has
exactly the seam you need (so a real client swaps in without touching
`FeedbackAgent`), not more abstraction than the problem needs.

---

### 2. Generate the golden set (once the skeleton is in place)

> Give me 8-10 short, realistic customer feedback examples for an
> influencer-marketing SaaS company's beauty and technology clients — a mix
> of clearly positive ("keep doing") and clearly actionable ("bad")
> feedback, plus one or two genuinely ambiguous/hedged ones. Include my
> hand-picked label for each so I can use it as a golden set.

**Validate:** re-label them yourself, don't just accept the suggested
labels — you're the ground truth here, not the model. Say that out loud:
"I'm overriding this label because..." if you disagree with one.

---

### 3. Draft the actual classification prompt (the one the agent sends)

> Draft the prompt text I'd send to a real LLM to classify one feedback
> entry as good/bad and produce a one-sentence summary, returned as strict
> JSON matching a fixed schema. I want to talk through why structured
> output matters here.

**Validate:** check the schema is unambiguous (no "maybe good, maybe bad"
category) and that the prompt gives the model enough context (industry,
what "actionable" means) to not guess.

---

### 4. Draft the judge rubric (for the evaluation pipeline)

> I need an LLM-as-judge prompt that scores whether a classification
> (good/bad) and summary are correct, given the original feedback text and
> my human label. It should also flag if the summary hallucinates something
> not in the original text. Draft the rubric/prompt text, not code.

**Validate:** this is the point to say out loud — "before I trust this
judge's scores, I'd run it against a small human-labeled sample first and
check it agrees with me, the same way I'm checking the classifier itself."

---

### 5. Critique, don't rewrite (once you have working eval code)

> Here's my `eval_classifications` function: [paste code]. Does it handle
> the case where the results and golden dicts don't have the same keys, or
> where there are zero examples of the positive class? Point out gaps,
> don't rewrite it — I want to fix it myself.

**Validate:** implement the fix yourself, and say why each gap matters
(e.g., zero-division on an empty class isn't hypothetical — it happens
constantly in early-stage golden sets).

---

### 6. Tradeoffs / closing discussion (last 5-10 min)

> Given this is currently an in-memory batch with a mocked LLM, help me
> think out loud about: what changes if this scales to real production
> traffic (latency/cost of judge calls, batch vs. real-time), and what's
> the minimal viable version of the RAG chatbot extension I described,
> without letting me over-scope it.

**Validate:** treat this as a discussion aid, not an answer to read
verbatim — you already have real opinions on this (see the field-guide
artifact's architecture section); use the response to sharpen your own
answer, not replace it.
