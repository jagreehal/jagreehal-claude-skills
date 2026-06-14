---
name: spine-framework
description: Evaluates and improves technical articles against the SPINE framework (Stakes, Point, Illustration, Nuance, Exit, plus Voice and Clean) to verify they carry a real insight, prove it, and land. Use when writing or reviewing blog posts, tutorials, technical documentation, or any draft article, or when scoring an article's quality.
version: 1.4.0
---

# SPINE Framework

## Overview

SPINE is a rubric for technical writing: Stakes, Point, Illustration, Nuance, Exit, with Voice and Clean layered on top. It exists because most technical articles fail in predictable, fixable ways: no insight, unproven claims, no admitted limits, and a conclusion that trails off. SPINE names each failure so you can catch it before publishing.

The principle is **substance first, polish last**: every great article needs a strong spine before it needs nice prose. The iron law: **no insight, no article.** A grammatically perfect piece with nothing non-obvious to say is still a 4/10. SPINE is an evaluation lens, not an article structure. It tells you whether the elements are present; it does not dictate headings.

## When to Use

- Writing a blog post, tutorial, or technical article
- Reviewing or editing a draft for quality
- Scoring an article before publishing
- Deciding whether a piece has a real point worth shipping

**When NOT to use:** Reference documentation structure (use [documentation-standards](../documentation-standards/SKILL.md)); preserving an author's voice during line edits (use [structured-writing](../structured-writing/SKILL.md)); code or system design (use [design-principles](../design-principles/SKILL.md)).

**Related:** [documentation-standards](../documentation-standards/SKILL.md) for reference docs and information-carrying headings, [structured-writing](../structured-writing/SKILL.md) for voice-preserving edits, [concise-output](../concise-output/SKILL.md) which aligns with the Clean section.

## SPINE Is for Evaluation, Not Structure

**NEVER:** use the SPINE acronym as headings in articles (e.g., "S: Stakes", "P: Point").

**ALWAYS:** use information-carrying headings that describe actual content (e.g., "Why Your JWT Implementation Is Vulnerable", "The Retrieval Bias Problem").

SPINE evaluates whether articles contain these elements; it doesn't dictate article structure. Headings must be relevant to content, not framework labels.

## The Hierarchy

When elements conflict, prioritize in this order:

| Priority | Element | Core Question |
|----------|---------|---------------|
| 1 | **Point** | What's the non-obvious insight? |
| 2 | **Stakes** | Why should anyone care? |
| 3 | **Illustration** | Does the proof actually prove? |
| 4 | **Nuance** | What could go wrong? |
| 5 | **Exit** | Did you land the plane? |
| 6 | **Voice** | Authority without arrogance? |
| 7 | **Clean** | Mechanical polish? |

**Iron Law:** No insight = no article. Point comes before everything.

---

## S: Stakes (Reader Contract)

An article without clear stakes is a lecture no one asked for.

### The First 30 Seconds

- MUST: Make WHO this is for explicit in the first 5–10 lines
- MUST: State a concrete, felt problem (not abstract)
- MUST: Define what the reader will DO (not just understand)
- MUST: Set scope boundaries ("This covers X, not Y")
- SHOULD: Name assumed knowledge ("Assumes familiarity with X")

### Litmus Tests

- Could a reader decide in 20 seconds if this is for them?
- Is the problem something they've *already experienced* (not hypothetical)?
- Would they feel stupid if they shared it and it wasn't relevant to the recipient?

### Bad vs Good

| Bad | Good |
|-----|------|
| "Let's explore balanced retrieval." | "You'll learn a retrieval pattern that prevents confirmation bias in RAG systems." |
| "Authentication is important." | "Your JWT implementation probably has one of these three vulnerabilities." |
| "This post is about caching." | "By the end, you'll know when Redis makes things slower, not faster." |

---

## P: Point (Core Insight)

A grammatically perfect article with no insight is still a 4/10.

### Requirements

- MUST: State the core insight in ONE sentence without "how"
- MUST: Challenge a default belief or common practice
- MUST: Place the insight in the first 20% of the article
- MUST: Repeat the insight at least twice (intro + conclusion)
- SHOULD: Name a pattern readers feel but haven't articulated

### Insight Categories

| Type | Example |
|------|---------|
| Challenges belief | "Microservices make most systems slower to develop, not faster" |
| Exposes mistake | "Your 'secure' password hashing is probably using the wrong work factor" |
| Names the pattern | "Retrieval isn't neutral — query framing creates epistemic bias" |
| Reveals mechanism | "Why code review catches bugs but not bad design" |

### Litmus Tests

- Would a senior engineer want to read more after just the thesis sentence?
- Does the insight make someone uncomfortable or defensive? (Good sign.)
- Could this insight be a tweet that gets mass engagement?

---

## I: Illustration (Proof That Proves)

Abstract correctness isn't enough. Show it working.

### Accuracy & Proof Requirements

- MUST: Back all claims with running code OR verified trusted web sources
- MUST: Code examples actually run and produce the shown output
- MUST: Cite external sources with URLs (no "some say" or "experts believe")
- MUST: Remove claims you cannot prove with code or trusted sources
- MUST: Source all statistics from verified sources with citations
- NEVER: Make up examples, outputs, or claims
- NEVER: Use hypothetical scenarios as proof
- NEVER: Fabricate data or results
- NEVER: Include unverified statistics ("studies show" without citation)

**Iron Law:** If you can't prove it with running code or a verified source, remove it.

### Examples

- MUST: Include at least one end-to-end example (problem → solution)
- MUST: Show output, don't describe it
- MUST: Use realistic data (no `foo`/`bar`)
- MUST: Tie the example directly back to the stated problem
- SHOULD: Include a comparison (naive approach → failure → improved approach)

### Code Quality

- MUST: Test code before publishing (it actually runs)
- MUST: Show output generated by running the code shown (not fabricated)
- MUST: Make code copy-paste friendly (no screenshots, no invisible characters)
- MUST: Show error handling or explicitly mark it as elided
- MUST: Show interfaces/types, not just imply them
- MUST: Verify all code examples produce the claimed results
- SHOULD: Specify dependencies and versions
- SHOULD: Distinguish pseudocode from real code
- NEVER: Use inconsistent naming across sections
- NEVER: Show output that doesn't match actual code execution

### Diagrams & Visuals

- MUST: Reference every diagram in text or provide a caption
- MUST: Make diagrams legible at 50% zoom
- MUST: Explain something text alone wouldn't
- NEVER: Use color as the only differentiator (accessibility)
- NEVER: Duplicate what prose already says clearly

### Litmus Test

Could a reader implement this after reading, without googling?

---

## N: Nuance (Intellectual Honesty)

Experts trust authors who admit weaknesses. Amateurs hide them.

### Failure Modes

- MUST: Name the failure mode that will bite readers first
- MUST: Discuss at least 2 failure modes total
- MUST: Include "This breaks when..."
- SHOULD: Address false positives/negatives (if applicable)

### Tradeoffs

- MUST: Acknowledge costs (latency, complexity, maintenance, cognitive load)
- MUST: State clearly when NOT to use this
- SHOULD: Mention alternative approaches
- SHOULD: Steelman the opposite position

### Litmus Tests

- Would you mass-send this to your former team?
- Did you include the caveat you'd add verbally when presenting?
- If this approach failed for a reader, would they blame you or themselves?

---

## E: Exit (Land the Plane)

Most articles fail here. They trail off instead of concluding.

### Strong Endings

- MUST: Restate the insight, not the content
- MUST: Make clear exactly when to use this pattern
- MUST: Provide a crystal-clear one-sentence takeaway
- MUST: Echo the opening promise (callback)
- SHOULD: Make extensions/next steps feel additive, not tacked on
- SHOULD: Make the final paragraph sound like domain expertise, not a recap
- NEVER: End with "I hope this was helpful!"
- NEVER: End with "There's much more to explore."

### The Callback Test

- MUST: Conclusion echoes the opening promise
- MUST: If you deleted the middle 50%, intro and conclusion would still connect

### Bad vs Good Endings

| Bad | Good |
|-----|------|
| "In conclusion, we covered X, Y, and Z." | "The next time retrieval feels 'off,' check your query framing before your embeddings." |
| "I hope this was helpful!" | "This pattern costs you 40ms. It buys you answers your users actually trust." |
| "There's much more to explore." | "Start with the bias detection query. Most teams find something in the first hour." |

---

## Voice: Authority Without Arrogance

10/10 articles sound confident, not loud.

### Tone

- MUST: Use declarative sentences ("This fails because..." not "It might be problematic...")
- MUST: Make every adjective measurable or remove it
- MUST: Explain WHY it works, not just that it works
- SHOULD: Engage disagreement, not dismiss it
- NEVER: Use marketing fluff ("game-changing", "revolutionary", "powerful", "robust")
- NEVER: Moralize ("developers should...", "you need to...")

### Reader Respect

- MUST: Match depth to the stated audience (don't explain imports to senior engineers)
- SHOULD: Define jargon or deliberately gatekeep (both valid; be intentional)
- NEVER: Include "throat-clearing" paragraphs (preamble that delays the point)
- NEVER: Restate what was just said (unless reframed)
- NEVER: Use filler transitions ("Now let's take a look at...")

### Litmus Test

Would a senior engineer trust this without knowing who wrote it?

---

## Clean: Mechanical Polish

These don't add value, but violations subtract trust immediately.

### Language & Grammar

- MUST: Choose US or UK English and use it consistently
- MUST: No spelling errors
- MUST: No missing articles ("the", "a", "an")
- MUST: No sentence fragments (unless intentional for emphasis)

### Punctuation & Style

- MUST: Consistent hyphenation throughout
- MUST: Lists use parallel grammar (all verbs or all nouns)
- MUST: Code blocks use consistent formatting and indentation
- SHOULD: No em dashes unless explicitly part of brand style
- SHOULD: No emoji unless explicitly appropriate for the platform

### Structure

- MUST: Headings form a logical outline on their own
- MUST: Headings use information-carrying words (describe content, not framework labels)
- MUST: Each section answers ONE question
- MUST: Sections start with a claim, not background
- SHOULD: No paragraph exceeds 4–5 lines (desktop)
- NEVER: Use the SPINE acronym (S, P, I, N, E) as headings in articles
- NEVER: Include sections that exist "because it feels right"

### Hygiene

- MUST: All links work (no rot, no "click here")
- MUST: All claims verifiable (running code or trusted sources)
- SHOULD: Note date sensitivity if time-bound
- SHOULD: Credit ideas from others explicitly

---

## Common Rationalizations

| Rationalization | Reality |
|------------|---------|
| "The writing is clean, so it's a good article" | Clean is the lowest-priority element. Without a Point, polish is lipstick on a 4/10. |
| "The insight is obvious once you read the whole thing" | If the reader can't get it from the first 20%, they won't read the whole thing. State it up front. |
| "I'll describe the output instead of running the code" | Described output is fabricated until proven. Run it and paste the real result. |
| "Admitting failure modes makes me look unsure" | The opposite. Naming the limits is what makes experts trustworthy. |
| "Using SPINE as headings keeps me organized" | It tells readers nothing. Headings must carry information, not framework labels. |

## Red Flags

- No statable one-sentence insight, or the insight is buried past the first 20%
- Claims with no running code and no cited source
- Output described rather than shown, or output that doesn't match the code
- No "this breaks when..." section, zero admitted failure modes
- A conclusion that recaps content instead of restating the insight
- Endings like "I hope this was helpful!" or "There's much more to explore."
- Marketing fluff: "game-changing", "revolutionary", "powerful", "robust"
- SPINE letters used as article headings
- `foo`/`bar` placeholder data instead of realistic examples

## Pre-Flight Checklist

Run before publishing. Six questions, five minutes.

| # | Question | Pass? |
|---|----------|-------|
| 1 | Can I state the core insight in one sentence without "how"? | [ ] |
| 2 | Did I run every code block and verify the output matches? | [ ] |
| 3 | Can I prove every claim with running code or a verified trusted source? | [ ] |
| 4 | Did I say when NOT to use this? | [ ] |
| 5 | Does the intro make a promise the conclusion keeps? | [ ] |
| 6 | If the reader implements this and it fails, will they blame me or themselves? | [ ] |

## Scoring Guide

| Score | Description |
|-------|-------------|
| **10** | Strong insight, honest about limits, reader could implement immediately |
| **8–9** | Solid insight, good examples, minor gaps in nuance or polish |
| **6–7** | Useful content but the insight is obvious or examples are weak |
| **4–5** | Correct information, no insight, reads like documentation |
| **1–3** | Unclear purpose, untested code, or misleading claims |
