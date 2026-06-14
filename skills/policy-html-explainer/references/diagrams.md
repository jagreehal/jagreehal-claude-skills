# Diagrams

Diagrams are a *second view* of a rule, never the only place it appears. The same rule must be
written out in text above or below the diagram, so the page still works when printed in greyscale
or read by a screen reader. Every node label, branch, and caption obeys the accuracy rules: a
diagram may not introduce a threshold, branch, or permission the source doesn't state.

All diagrams are inline CSS or inline SVG. No libraries, no `<script>` fetching a CDN, no Mermaid
runtime. The template ships ready-made markup for each pattern below — copy it.

## When each diagram earns its place

| The theme has… | Use | Don't use it when… |
|----------------|-----|--------------------|
| A decision with branches ("is X true?") | **Decision tree** | There's only one path — just say "do X" |
| A numeric threshold or tiered limit | **Threshold ladder** | The source states no number |
| A clear allowed-vs-forbidden contrast | **Do / don't cards** | The rule is nuanced, not binary |
| A sequence with a deadline | **Timeline** | There's no ordering or clock |

If a theme is just "do this", give it no diagram. A decorative diagram adds reading cost for no
comprehension gain — the opposite of the skill's goal.

## Decision tree

For a rule whose outcome depends on a yes/no condition (often an exception). The classic trap:
inventing a third branch like "if it seems secure". If the policy gives two outcomes, draw two.

```html
<figure class="diagram">
  <div class="tree">
    <div class="node">Has IT enrolled this device in MDM?</div>
    <div class="branch">
      <div class="leaf yes"><span class="tag">Yes</span> You may access customer data on it.</div>
      <div class="leaf no"><span class="tag">No</span> You <strong>must not</strong> — use a managed device.</div>
    </div>
  </div>
  <figcaption>"Secure in my own opinion" is not a branch. Only IT enrolment counts.</figcaption>
</figure>
```

Use the caption to close off invented branches explicitly — it's where you tell the reader what is
*not* an option.

## Threshold ladder

For tiered numeric rules. Keep every number, comparator (`over`/`under`/`≥`), and modal exactly as
the source states them. Don't normalise "£25" to "25 pounds" or turn `should` into `must`.

```html
<figure class="diagram">
  <div class="ladder">
    <div class="rung"><span class="level">Over £25</span><span>Receipt <strong>required</strong>.</span></div>
    <div class="rung"><span class="level">Under £25</span><span>Receipt <strong>may</strong> be omitted; description <strong>should</strong> be included.</span></div>
  </div>
  <figcaption>Thresholds shown exactly as the policy states them.</figcaption>
</figure>
```

If the source is silent on where a boundary sits, **don't draw one**. Write "The policy is not
explicit on this point" in text instead of inventing a rung.

## Do / don't cards

For a binary allowed/forbidden rule. Each card carries a glyph (✓/✕) and a word ("Do"/"Don't") so
meaning doesn't depend on the green/red colour alone.

```html
<figure class="diagram">
  <div class="dodont">
    <div class="card do"><h4>Do</h4><ul><li>Use an IT-enrolled (MDM) device.</li></ul></div>
    <div class="card dont"><h4>Don't</h4><ul><li>Decide for yourself a device is "secure enough".</li></ul></div>
  </div>
</figure>
```

Don't list an exception in the "Do" card as if it were the general rule. The general rule and its
narrow exception are different things — the exception belongs in the Exceptions callout.

## Timeline

For sequences with a deadline. Make the clock's start explicit (a common ambiguity — "from
discovery" vs "from confirmation").

```html
<figure class="diagram">
  <div class="timeline">
    <div class="step"><span class="when">T+0</span> — discovery. The clock starts now.</div>
    <div class="step"><span class="when">Within 24h</span> — report to Information Security.</div>
  </div>
  <figcaption>The clock starts at discovery, not confirmation.</figcaption>
</figure>
```

## If you need a freehand diagram

For anything the four patterns don't cover (an org chart, a data flow), use inline `<svg>` with a
`<title>` and `<desc>` for screen readers, `currentColor` or the CSS tokens for strokes (so it
follows light/dark and prints), and text labels inside the SVG rather than in a separate legend.
Keep it to the same restrained palette. Still restate the rule in text — the SVG is the second view.

## Accessibility checklist for any diagram

* [ ] The rule it shows is also written in plain text nearby.
* [ ] Meaning doesn't depend on colour alone (glyphs + labels present).
* [ ] SVG has `<title>`; CSS diagrams use real text, not empty coloured divs.
* [ ] No node, branch, threshold, or caption states anything the source policy doesn't.
* [ ] It survives greyscale print.
