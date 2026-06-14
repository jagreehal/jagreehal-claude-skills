<!-- markdownlint-disable MD024 MD025 -->
<!-- cSpell:ignore Northwind -->

# Few-shot examples

Worked examples for `policy-story-explainer`. All source policies below are generic and invented —
use them as patterns, not as policy. Each example isolates one thing the skill must get right.

The repeated `### A realistic situation` / `### What the policy is saying` headings and the
document-within-a-document in §6 are the template applied faithfully, so duplicate-heading and
single-h1 lint rules are disabled for this file by design.

---

## 0. A single theme, end to end

> **Source:** Employees **must** report any suspected data breach to the Information Security team
> within **24 hours** of discovery.

### A realistic situation

Imagine you accidentally email a spreadsheet of customer details to the wrong supplier. You spot
the mistake that afternoon and aren't sure whether anyone has opened it.

### What the policy is saying

You **must not** wait to see whether the mistake becomes a bigger problem. Customer data may have
been exposed, so the Information Security team needs to know quickly.

### The actual policy point

Suspected data breaches **must** be reported to the Information Security team within **24 hours**
of discovery.

### What you should do

Report it as soon as you realise. Include what was sent, who received it, when it happened, and
whether you have tried to recall or delete the message.

### Why it matters

Fast reporting gives the organisation time to contain the issue, assess the risk, and meet any
legal or regulatory reporting duties.

---

## 1. Fidelity traps (WRONG vs CORRECT)

Short before/after pairs. The WRONG version reads fine but quietly changes the policy — exactly
the failure a story-led rewrite must avoid.

### Trap A — softening a mandatory modal

> **Source:** Staff **must** complete security training within 14 days of joining.

❌ **WRONG:** "Try to get your security training done in your first couple of weeks."
*(Drops `must` → sounds optional; "couple of weeks" blurs the 14-day threshold.)*

✅ **CORRECT:** "You **must** complete security training within **14 days** of joining. It is not
optional, and the clock starts on your first day."

### Trap B — turning an exception into general permission

> **Source:** Personal devices **must not** be used to access customer data, except where IT has
> enrolled the device in mobile device management (MDM).

❌ **WRONG:** "You can use your own phone for customer data as long as it's reasonably secure."
*(Widens a narrow IT-controlled exception into a self-assessed general right.)*

✅ **CORRECT:** "As a rule you **must not** touch customer data on a personal device. The **only**
exception is a device IT has enrolled in MDM — your own judgement about whether it's 'secure
enough' does not count."

### Trap C — inventing a rule to make the example concrete

> **Source:** Reasonable travel expenses are reimbursable.

❌ **WRONG:** "Meals up to £30 a day and standard-class rail are covered." *(Invents a £30 cap and
a rail class the source never states.)*

✅ **CORRECT:** "Reasonable travel expenses are reimbursable. **The policy is not explicit on**
what counts as 'reasonable' or whether any per-day cap applies — check with your manager before
assuming a limit."

### Trap D — collapsing should / may / must

> **Source:** Claims over £25 **require** a receipt. Claims under £25 **should** include a
> description but **may** omit the receipt.

❌ **WRONG:** "Always attach a receipt and a description." *(Promotes `should`/`may` to `must` and
erases the £25 threshold.)*

✅ **CORRECT:** "Over **£25**, a receipt is **required**. Under **£25**, you **should** still
describe what it was for, but you **may** leave the receipt out."

---

## 2. Same rule, three audiences (audience tuning)

> **Source:** Expense claims **must** be submitted within 30 days of the expense being incurred.
> Late claims will not be reimbursed, except where the employee was on approved long-term sick
> leave.

**For employees** — light, action-first:
> Got a receipt? Claim it within **30 days** — you **must**, or you won't get the money back. The
> one get-out is if you were on approved long-term sick leave during that window.

**For managers / approvers** — medium, decision-focused:
> The **30-day** deadline is a hard cut-off, not a guideline. If someone submits late, the default
> is no reimbursement — you do **not** have discretion to waive it, *except* for staff on approved
> long-term sick leave. Route anything outside that exception to [policy owner].

**For auditors / compliance** — heavy, traceability-first:
> Obligation: claims **must** be submitted ≤30 days from the date incurred (§4.2.2). Sole stated
> exception: approved long-term sick leave; no other basis for late reimbursement appears in the
> source. Evidence to retain: submission date vs incurred date, and sick-leave approval where the
> exception is invoked.

The rule, the deadline, and the exception are identical in all three. Only depth and framing move.

---

## 3. Two-tier output (executive summary + story)

For a long policy, lead with a scannable summary, then the story-led detail.

> **Executive summary — Data Breach Reporting**
>
> - You **must** report a suspected breach to the Information Security team within **24 hours** of discovery.
> - "Suspected" is enough — you do **not** wait for confirmation.
> - Include: what was exposed, who received it, when, and any recall/delete attempt.
> - No stated exception to the 24-hour window.
>
> **Full version — Theme 1: Reporting a suspected breach**
>
> *A realistic situation:* You email a customer spreadsheet to the wrong supplier and spot it
> that afternoon.
>
> *What the policy is saying:* You **must not** wait to see if it becomes a problem. Customer data
> may be exposed, so the Information Security team needs to know fast.
>
> *The actual policy point:* Suspected data breaches **must** be reported to the Information
> Security team within **24 hours** of discovery.
>
> *What you should do:* Report it as soon as you realise. Include what was sent, who received it,
> when it happened, and whether you have tried to recall or delete the message.
>
> *Why it matters:* Fast reporting gives the organisation time to contain the issue, assess the
> risk, and meet any legal or regulatory reporting duties.

The summary restates every obligation, number, and exception. It compresses prose, never policy.

---

## 4. Narrative continuity across a long document

One recurring person and org, escalating as the policy bites. (Source rules abbreviated.)

**Theme 1 — Access (Source: access to production data requires a documented business need.)**
> *Maya, a new analyst at Northwind,* asks for access to the production customer table. The policy
> says access **requires** a documented business need — so her request alone isn't enough until
> the reason is written down and approved.

**Theme 2 — Use (Source: production data must not be copied to local machines.)**
> Two weeks in, *Maya* wants to pull that table into a spreadsheet on her laptop to work offline.
> The policy says production data **must not** be copied to local machines — the offline copy is
> exactly what the rule prohibits, regardless of how convenient it is.

**Theme 3 — Incident (Source: suspected exposure must be reported within 24 hours.)**
> *Maya* later realises a colleague did keep a local copy that synced to a personal cloud drive.
> Now the **24-hour** breach-reporting clock applies — and it started when she discovered it, not
> when the copy was made.

Same character, rising stakes, three different rules — none bent to fit the story.

---

## 5. Handling templates: `shall` + placeholders

Templates use binding `shall` and `[placeholders]`. Preserve both: never soften `shall`, and never
fill in, reorder, or re-inflect a placeholder.

> **Source:** Every AI system that is *[built or bought]* by *[organization name]* **shall** meet
> a defined fairness metric appropriate to its context. No AI system **shall** endanger human life.

❌ **WRONG:** "Whatever AI Acme *[builds or buys]* shall hit a fairness target, and no system shall
put people at risk." *(Fills `[organization name]` with "Acme"; re-inflects `[built or bought]`
into `[builds or buys]`; broadens the exact scope "endanger human life" into the vaguer "put
people at risk".)*

✅ **CORRECT:**
> *The actual policy point:* Every AI system that is *[built or bought]* by *[organization name]*
> **shall** meet a defined fairness metric appropriate to its context, and no AI system **shall**
> **endanger human life**.
>
> *What the policy is saying:* For any AI that *[organization name]* acquires under *[built or
> bought]*, a fairness metric set for that specific use is mandatory. A second, absolute rule sits
> on top: no AI system **shall endanger human life**.
>
> *Why it matters:* "Shall" is an obligation, not an aim, and "endanger human life" is the exact
> scope — not "risk" in general. The placeholders stay verbatim; fill one in or change its wording
> and the rule reads as if a choice has already been made when it hasn't.

---

## 6. Complete miniature policy (three themes + wrapper)

A shortened but **complete** output: executive summary, document shell, three full themes with
Maya/Northwind continuity (access → copy → incident), and closing sections. It mirrors the
[output-format.md](output-format.md) template exactly. Source rules are invented.

### Source (extract)

> **§3.1 Access:** Access to production customer data **requires** a documented business need,
> approved by the data owner.
> **§3.2 Local copies:** Production data **must not** be copied to local machines or personal
> cloud storage.
> **§4.1 Reporting:** Suspected exposure of customer data **must** be reported to the Information
> Security team within **24 hours** of discovery.

### Story-led output

The block below is the literal output, rendered with the same headings as the template.

# Northwind Data Handling Policy: Story-led Explanation

## Executive summary

- Production customer data access **requires** a documented business need, approved by the data owner (§3.1).
- Production data **must not** be copied to local machines or personal cloud storage (§3.2).
- Suspected customer-data exposure **must** be reported to the Information Security team within **24 hours** of discovery (§4.1).
- No stated exception to the local-copy prohibition or the 24-hour reporting window.

## Who this is for

Analysts and engineers at Northwind who work with production customer data.

## The policy in one paragraph

Northwind limits who can reach production customer data, forbids keeping offline or personal copies, and requires fast reporting when exposure is suspected. Access needs a written reason and owner approval; convenience does not override the copy ban; discovery starts the reporting clock.

---

## 1. Getting access to production data (§3.1)

### A realistic situation

Maya, a new analyst at Northwind, needs the production customer table for a fraud review. She messages the data owner on Slack asking for access.

### What the policy is saying

A request alone is not enough. Access **requires** a documented business need and the data owner's approval before she can touch production customer data.

### The actual policy point

Access to production customer data **requires** a documented business need, approved by the data owner (§3.1).

### What you should do

Write down why you need access and who approved it before the grant. Keep that record with the access request.

### Why it matters

Production customer data is high-risk. A documented need and owner sign-off create an audit trail if access is later questioned.

---

## 2. Keeping production data off your laptop (§3.2)

### A realistic situation

Two weeks later, Maya wants to export the table to a spreadsheet on her laptop so she can work on a train without VPN. The export would be a local copy.

### What the policy is saying

Production data **must not** live on local machines or personal cloud storage — even for short-term convenience or offline work.

### The actual policy point

Production data **must not** be copied to local machines or personal cloud storage (§3.2).

### What you should do

Work in approved environments only. If you need offline analysis, ask the data owner or Information Security for an approved method — do not copy the data yourself.

### Why it matters

Local and personal-cloud copies are hard to revoke, easy to mis-share, and often outside Northwind's monitoring. The ban targets that risk directly.

---

## 3. Reporting a suspected exposure (§4.1)

### A realistic situation

A month later, Maya discovers a colleague kept a local copy of the customer table that synced to a personal cloud drive. Customer data may now be outside Northwind's control.

### What the policy is saying

The moment exposure is suspected, the clock starts. You **must** tell the Information Security team within **24 hours** of discovery — you do not wait to confirm how far the data spread.

### The actual policy point

Suspected exposure of customer data **must** be reported to the Information Security team within **24 hours** of discovery (§4.1).

### What you should do

Report it as soon as you suspect exposure. Include what data was involved, where it went, when you discovered it, and any steps already taken to contain it.

### Why it matters

Fast reporting gives the organisation time to contain the exposure, assess the risk, and meet any legal or regulatory reporting duties. The 24 hours runs from discovery, not from when the copy was first made.

---

## Important exceptions or edge cases

- §3.1: access hinges on documented business need **and** data-owner approval — both are required.
- §4.1: the 24-hour clock runs from discovery of suspected exposure, not from when the data first left an approved environment.

## Things that may need clarification

- The source does not say what form "documented business need" must take (ticket, email, formal request).
- The source does not list approved remote-access alternatives to local copies.
- §4.1 reporting duties may need legal/compliance review for regulatory alignment.

## Quick checklist

- [ ] Documented business need and data-owner approval before production access
- [ ] No local or personal-cloud copies of production data
- [ ] Report suspected exposure within 24 hours of discovery

---

## 7. Aspirational vs binding in the same clause

When a clause mixes "strive to" with lettered **shall** items, keep the aim separate from the
obligations. Do not flatten them into one strength level.

> **Source (II.B.1):** Every AI system that is *[built or bought]* by *[organization name]* shall
> strive to achieve appropriate levels of trustworthy characteristics, as defined by the NIST AI
> RMF. **(b) Safety:** No AI system **shall** endanger human life, health, property, or the
> environment. **(g) Fairness:** All AI systems **shall** meet a defined metric of fairness
> appropriate to their context and **shall** manage all forms of harmful bias. *(NIST AI RMF)*

❌ **WRONG:** "Northwind's AI should be trustworthy, safe, and fair — safety and fairness are
goals to work toward." *(Fills the placeholder; turns every **shall** into aspiration; drops
the NIST citation.)*

✅ **CORRECT — the actual policy point:**

> Every AI system that is *[built or bought]* by *[organization name]* **shall strive to achieve**
> appropriate levels of trustworthy characteristics, as defined by the NIST AI RMF. Per **(b)**, no
> AI system **shall** endanger human life, health, property, or the environment. Per **(g)**, all
> AI systems **shall** meet a defined metric of fairness appropriate to their context and **shall**
> manage all forms of harmful bias. *(NIST AI RMF)*

✅ **CORRECT — what the policy is saying:**

> The opening line is an aim: systems **shall strive to** hit appropriate trustworthiness levels
> per the NIST AI RMF. Items **(b)** and **(g)** are harder floors — **shall** obligations on
> safety and fairness, not things to "work toward" in the same sense.

✅ **CORRECT — why it matters:**

> Treating **(b)** as aspirational would imply an acceptable level of endangerment. It does not.
> "Shall strive" and "shall meet / shall manage" must stay distinct.
