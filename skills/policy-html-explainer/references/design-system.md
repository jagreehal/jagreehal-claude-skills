# Design system

The look is defined once in the `<style>` block of
[`assets/policy-template.html`](../assets/policy-template.html). This file explains the intent so you
can extend it without breaking the rules. The aesthetic is **calm and editorial** — a document
someone reads, not a dashboard. Restraint is the point: the design lowers reading cost, it doesn't
compete with the content.

## Tokens

All colour, spacing, and type live in CSS custom properties on `:root`, with a
`prefers-color-scheme: dark` override. Change the theme by editing tokens, not individual rules.

| Token | Role |
|-------|------|
| `--accent` | Policy blocks, actions, primary structure. Calm green by default. |
| `--ok` / `--danger` | Do / don't, allowed / prohibited. Only for genuine allow-vs-forbid contrast. |
| `--warn` | Exceptions and review flags. |
| `--ink` / `--muted` | Body text / secondary text. |
| `--maxw` | Measure (`760px`). Keep it — long lines hurt readability. |

Re-theming for a client's brand: change `--accent` and the soft variants. Keep the do/don't and
warn colours semantically distinct from the accent so meaning survives the re-skin.

## Typography

* System font stack for UI; the same stack for body — no web fonts (keeps the file self-contained).
* Body 17px / line-height 1.65, measure capped at ~70 characters. Comfortable, document-like.
* Verbatim policy is **monospace** on purpose: it signals "this is the exact rule" and stops a
  reader mistaking a quote for a paraphrase.
* One `<h1>` (the policy name). Themes are `<h2>`, sub-parts `<h3>`/`<h4>`. Never skip a level —
  heading order is how screen readers and the print outline navigate.

## Visual hierarchy of trust

The single most important job of the styling is to keep four things visually distinct so a reader
always knows what they're looking at:

1. **Verbatim policy** — monospace, accent left-border, bordered box. The source of truth.
2. **Explanation** — normal prose under a small uppercase label.
3. **Scenario** — italic, prefixed "Imagine". Clearly hypothetical.
4. **Why** — muted, left-rule. Reasoning, not rule.

If a redesign makes any two of these look the same, it has broken the skill, however pretty it is.

## Accessibility (required, not optional)

* **Contrast:** body and UI text meet WCAG AA (≥ 4.5:1) in both light and dark. If you add a colour,
  check it. Don't rely on colour alone — do/don't cards also carry ✓/✕ glyphs and text labels.
* **Keyboard:** a skip link, real `<a>`/`<input>` elements, visible focus. Everything reachable by
  Tab in a logical order.
* **Structure:** one `<main>`, landmark `<nav>`/`<header>`/`<footer>`, `aria-labelledby` on major
  sections, `aria-live` on the checklist counter.
* **Diagrams:** every diagram restates a rule that's also in text, so a screen-reader user loses
  nothing. Give SVG diagrams a `<title>`; give CSS diagrams meaningful text content (not just
  coloured boxes).
* Respect `prefers-reduced-motion` if you add any motion (the template uses none beyond smooth
  scroll, which honours the setting).

## Print

Policies get printed and signed. The `@media print` block must keep working:

* TOC, skip link, and the live progress counter hide.
* Colours flatten to ink-on-white; links lose their colour; checklist boxes become printable outlines.
* `break-inside: avoid` keeps themes, the summary, and diagrams from splitting across pages.
* Test it: open print preview before delivering. If a diagram or quote breaks across a page badly,
  fix it — the printed copy is often the one people actually read.

## Self-contained rule

No external requests of any kind: no CDN CSS/JS, no web fonts, no remote images, no analytics. The
only `<script>` is the inline checklist counter, and the page is fully usable with JavaScript off.
This keeps the file emailable, offline-capable, and safe to open behind a corporate proxy.
