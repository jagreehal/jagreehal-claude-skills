# Output format (HTML)

The output is one self-contained `.html` file built from
[`assets/policy-template.html`](../assets/policy-template.html). This file defines the page
structure; the template implements it. Don't hand-roll the CSS — copy the template and fill it in.

## Page order

1. **Masthead** — policy name, who it's for, source reference, reading time, policy version.
2. **Table of contents** (`nav.toc`) — anchor links to every theme and section. Collapses in print.
3. **Executive summary** (`section.summary`) — *long policies only.* The obligations, deadlines,
   and exceptions as scannable bullets with mandatory language intact. Each bullet links to its
   theme. Omit for a short policy.
4. **Themes** (`section.theme`) — one per rule cluster, in the order below.
5. **Exceptions & approvals** — every exception and approval route, as `callout.exception` blocks.
6. **Needs human review** — `callout.review` flags for anything ambiguous, legal, or out of scope.
7. **Understanding checklist** (`section.understand`) — comprehension items, not an attendance box.
8. **Ask-your-owner prompt** and **footer** — where to go when a case isn't covered; the
   "official policy wins" disclaimer.

## The five blocks inside each theme

Every theme renders the same five blocks, in this order. The classes carry the visual distinction
that keeps quoted policy separate from your words:

| Block | Class | Purpose | Accuracy note |
|-------|-------|---------|---------------|
| Situation | `.block.scenario` | A believable "this happened to you" moment | Invented scenario — never bends a rule to fit |
| What this means | `.block` + `.label` | Plain-English paraphrase | May rephrase, must not change obligation/threshold |
| The actual policy | `blockquote.policy` | **Verbatim** rule + source ref | Word for word. Wrap modals in `<span class="modal">` |
| What you should do | `.block` + `.label` | Concrete actions | Actions the policy supports, nothing invented |
| Why it exists | `.block.why` | The risk or reason behind the rule | The *reason*, not a new rule |

A diagram (see [diagrams.md](diagrams.md)) sits between "what you should do" and "why" when the
theme earns one. Not every theme does.

## The verbatim policy block is load-bearing

`blockquote.policy` is the only place source text appears unchanged. It's styled in monospace with
an accent left-border so a reader can see at a glance "this is the rule, not someone's summary".
Rules:

* Paste the source text exactly. Don't fix its grammar, voice, or "extreme" words.
* Wrap `must` / `shall` / `may` / `should` / `must not` in `<span class="modal">` so they stay
  visually prominent — but do **not** change the word.
* Put the section/clause reference in `<span class="ref">` at the end.
* Keep placeholders (`[organization name]`) and defined terms exactly as written.

## Two-tier depth

Mirror `policy-story-explainer`: lead long policies with the executive summary (so a reader can act
without scrolling the whole page), then the full theme-by-theme version. A short policy needs only
the themes. The summary never drops a `must`/`shall`, a threshold, or an exception to save space.

## Filename and opening

Save as `<policy-slug>-explained.html`. Give the user the exact open command, e.g.:

```bash
open acceptable-use-policy-explained.html        # macOS
xdg-open acceptable-use-policy-explained.html    # Linux
start acceptable-use-policy-explained.html       # Windows
```
