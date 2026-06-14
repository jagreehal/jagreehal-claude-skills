---
name: policy-html-explainer
description: Turns a policy, compliance, HR, legal, operational, or governance document into a single, self-contained, beautiful HTML page that explains each rule through a relatable scenario, plain-English meaning, the verbatim policy, and why it exists — with diagrams, decision trees, and an understanding-first checklist. Use when the user wants a policy rendered as a shareable, printable web page people will actually read instead of skimming and ticking a box.
version: 1.0.0
---

# Policy HTML Explainer

## Purpose

Produce a single HTML file that makes a policy genuinely understandable. Each rule is shown as a
**situation → what it means → the actual policy → what to do → why it exists**, supported by
diagrams (decision trees, threshold ladders, do/don't cards). The page is the goal: a document
people open, read, and understand — not one they skim before checking "done".

This is the visual sibling of [`policy-story-explainer`](../policy-story-explainer/SKILL.md). That
skill owns the *content* rules (accuracy, story structure, audience tuning). This skill owns
*rendering* that content as HTML. **The accuracy rules below are not optional and not relaxed by
the visual format.**

## Core principles

* **Understanding is the path of least resistance.** The design exists to lower the cost of
  reading, not to decorate. If a diagram does not help someone act correctly, leave it out.
* **Accuracy outranks aesthetics.** A prettier sentence that changes a `must` to a `should`, blurs
  a threshold, or widens an exception is a defect, not a polish.
* **Show the seams.** A reader must always be able to tell apart: the verbatim policy, your
  plain-English explanation, the invented scenario, and the "why". Use distinct visual blocks so
  the quoted rule is never mistaken for your paraphrase.
* **Self-contained and portable.** One `.html` file, no network dependencies, no build step. It
  opens offline, prints cleanly, and can be emailed as-is.
* **The checklist confirms comprehension, not attendance.** End with "I understand…" items tied to
  the rules above them — never a hollow "I have read this policy" attestation.

## Inherited content rules (non-negotiable)

Apply every accuracy rule from `policy-story-explainer` before styling anything:

* Keep `must`/`shall`/`may`/`should` exactly as written. `shall` is mandatory — never soften it.
* Keep numbers, dates, time limits, approval levels, and thresholds exactly as written.
* Preserve defined terms, quoted definitions, and template placeholders (e.g. `[organization name]`)
  verbatim. Diagrams must not resolve a placeholder or pick one option from a list.
* Do not invent rules, caps, or thresholds to make a diagram concrete. If the source is silent,
  render "The policy is not explicit on this point" — do not draw a number that isn't there.
* Do not turn an exception into general permission, and do not merge separate rules.
* Flag legal, safeguarding, medical, financial, or regulatory content for human review instead of
  resolving it yourself.

See `policy-story-explainer/references/examples.md` for the WRONG-vs-CORRECT fidelity traps these
rules prevent. Every trap there applies equally to the diagram captions and node labels here.

## Workflow

0. Read [references/output-format.md](references/output-format.md),
   [references/design-system.md](references/design-system.md), and
   [references/diagrams.md](references/diagrams.md). Copy
   [assets/policy-template.html](assets/policy-template.html) as the starting point — do not hand-roll
   the CSS.
1. Do the content work first, exactly as `policy-story-explainer` prescribes: read the policy,
   identify rules / duties / permissions / exceptions / consequences, and group them into themes
   with a small recurring cast.
2. For each theme, write the five blocks (situation, what it means, the actual policy verbatim,
   what to do, why it matters).
3. Decide which themes earn a diagram. A theme earns one when it has: a decision with branches
   (→ decision tree), a numeric threshold or tiered limit (→ threshold ladder), a clear allowed /
   not-allowed contrast (→ do/don't cards), or a sequence with a deadline (→ timeline). Themes that
   are just "do X" need no diagram.
4. Fill the template: header, executive summary (long policies), sticky table of contents, one
   section per theme, exceptions callout, "needs review" flags, and the understanding checklist.
5. Save to a single self-contained `.html` file and give the user one command to open it
   (e.g. `open policy-explained.html` on macOS).
6. Run the final review checklist below before delivering.

## Output

A single `.html` file. For long or high-stakes policies, lead the page with a one-screen executive
summary (obligations, deadlines, exceptions as scannable items with mandatory language intact),
then the full theme-by-theme version. For a short policy, the themes alone are fine.

Default filename: `<policy-slug>-explained.html`. Tell the user the exact command to open it.

See [references/output-format.md](references/output-format.md) for the page structure and
[references/design-system.md](references/design-system.md) for the visual rules and block styles.

## Diagrams

Diagrams are inline SVG or CSS — no external libraries, no `<script>` fetching a CDN. Each diagram
restates a rule that is already written out in text directly above or below it; the diagram is a
second view, never the only place a rule appears (so the page still makes sense in print and to a
screen reader). Every node label and caption obeys the accuracy rules — a decision-tree branch
cannot invent a threshold the policy never stated.

See [references/diagrams.md](references/diagrams.md) for copy-paste patterns: decision tree,
threshold ladder, do/don't cards, deadline timeline, and accessibility requirements.

## When to ask for clarification

Ask before building if:

* the audience is unclear (it changes scenario depth and which diagrams help)
* the policy has legal, safeguarding, medical, financial, or regulatory implications
* the user wants specific branding, colours, or a logo
* the source has no structure to theme around
* the user asks to make the policy "friendlier" in a way that could change its meaning

## Final review checklist

Before delivering the HTML, check:

* [ ] The HTML is a single self-contained file: no external CSS/JS/font/image requests; it opens offline.
* [ ] Verbatim policy blocks are visually distinct from explanation, scenario, and "why".
* [ ] Mandatory language (`must`/`shall`) is intact everywhere, including diagram labels and captions.
* [ ] Thresholds, dates, approval levels, and placeholders are unchanged in text **and** in diagrams.
* [ ] No diagram invents a rule, number, or branch the source does not state.
* [ ] Exceptions and approval routes are present; no exception is widened into general permission.
* [ ] Every diagram's rule also appears in text (page works without the diagram, e.g. printed or screen-read).
* [ ] The page is keyboard-navigable, has a logical heading order, and meets contrast (see design-system).
* [ ] It prints cleanly (test print preview): TOC and nav collapse, content reflows, colours degrade safely.
* [ ] The closing checklist confirms understanding of specific rules, not mere attendance.
* [ ] Areas needing legal/compliance review are flagged on the page, not silently resolved.
* [ ] The page is genuinely easier to read than the source — someone would understand it, not skip it.
