---
name: policy-story-explainer
description: Rewrites long policy, compliance, HR, legal, operational, or governance documents into accurate, digestible story-led explanations. Use when the user wants a policy document made more relatable, scenario-based, easier to understand, or turned into realistic examples without watering down the original content.
version: 1.1.0
---

# Policy Story Explainer

## Purpose

Turn dry policy documents into clear, relatable explanations using realistic scenarios, plain-English summaries, and direct links back to the original policy. Improve understanding without weakening, changing, or oversimplifying the policy.

## Core principles

* Preserve the original meaning, obligations, restrictions, thresholds, exceptions, definitions, and consequences.
* Do not invent policy rules that are not present in the source.
* Do not remove nuance just to make the content easier to read.
* Use realistic scenarios to explain how the policy applies in everyday situations.
* For each theme, explain why the rule exists in practical human terms: what risk, harm, failure, or obligation the policy is trying to prevent.
* Make clear what is policy, what is explanation, and what is example.
* Flag ambiguity instead of guessing.
* Avoid giving legal advice unless the source explicitly provides it.

## Workflow

0. Before rewriting, read [references/output-format.md](references/output-format.md),
   [references/writing-style.md](references/writing-style.md), and
   [references/examples.md](references/examples.md). For long or high-stakes policies,
   follow the miniature complete output in examples §6 as the shape to match.
1. Read the policy carefully.
2. Identify the key rules, duties, permissions, exceptions, risks, and consequences.
3. Group related sections into understandable themes.
4. For each theme, write: a relatable scenario, a plain-English explanation, the relevant policy rule, what the person should do, why the rule exists, and what could go wrong if ignored.
5. Preserve source references such as section numbers, headings, page numbers, or clause names where available.
6. Highlight any areas that need human/legal/compliance review.

## Accuracy rules

These are the heart of the skill. When rewriting policy content:

* Keep "must" as "must", "shall" as "shall", "may" as "may", "should" as "should". `shall` is mandatory — never soften it to "should", "will try to", or "aims to".
* Distinguish aspirational wording ("strive to", "aim to") from binding obligations ("shall", "must") even when they sit in the same clause.
* Keep numbers, dates, time limits, approval levels, and thresholds exactly as written.
* Keep defined terms and quoted definitions exactly if they affect interpretation.
* Preserve template placeholders verbatim (e.g. `[organization name]`, `[bought, built, used, or sold]`). Do not invent a name, reorder, re-inflect, or pick one option from a placeholder list.
* Preserve source references, including section numbers, clause letters, and footnote citations.
* Do not merge separate rules if doing so changes the meaning.
* Do not turn exceptions into general permission.
* Do not make a policy sound optional if it is mandatory.
* If the source is unclear, write: "The policy is not explicit on this point."

## Output

For long policies, lead with a one-page **executive summary** (obligations, deadlines, and exceptions as scannable bullets, mandatory language intact), then the **full story-led version**. For a short policy, the full version alone is fine. The summary restates rules in plain English; it never drops a `must`/`shall`, a threshold, or an exception.

See [references/output-format.md](references/output-format.md) for the full-version template and section structure.

## Writing style

Warm, clear, and human, but precise. Pitch scenarios and depth to the audience (employees, managers, or auditors), reuse one small recurring cast across a long document, and strip AI tells from the narrative sections only — never from quoted policy, definitions, or the executive summary.

See [references/writing-style.md](references/writing-style.md) for the prefer/avoid list, the audience-tuning table, narrative-continuity rules, and the anti-slop checklist.

## Examples

See [references/examples.md](references/examples.md): a single theme end to end (§0), WRONG-vs-CORRECT fidelity traps (§1), audience-tuned variants (§2), the two-tier output (§3), narrative continuity (§4), template/placeholder handling (§5), a complete miniature policy (§6), and aspire-vs-`shall` in one clause (§7).

## When to ask for clarification

Ask the user for clarification if:

* the audience is unclear
* the document has no headings or structure
* the user wants a specific tone
* the policy has legal, safeguarding, medical, financial, or regulatory implications
* the user asks to make the policy "less strict" or "friendlier" in a way that could change its meaning

For sensitive legal, safeguarding, medical, financial, or regulatory content, surface review needs rather than resolving them yourself.

## Final review checklist

Before responding, check:

* [ ] The rewritten version preserves the policy meaning.
* [ ] Scenarios are realistic, relevant, and pitched at the stated audience.
* [ ] Mandatory requirements remain mandatory (`must`/`shall` intact).
* [ ] Thresholds, placeholders, and source references are unchanged.
* [ ] Exceptions and approval steps are included, and no exception is widened into general permission.
* [ ] Any ambiguity is flagged.
* [ ] Narrative prose reads naturally, with AI tells cut; quoted policy left exactly as written.
* [ ] The result is genuinely easier to read than the original — someone would understand it rather than skip it.
* [ ] For long docs: an executive summary leads, and it drops no obligation or threshold.
* [ ] No unsupported policy advice has been added.
