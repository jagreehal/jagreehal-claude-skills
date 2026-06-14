---
name: documentation-standards
description: Frames documentation around reader needs using eight quality dimensions, document-type requirements, and a review checklist. Use when writing or reviewing READMEs, API references, tutorials, changelogs, or error messages, when documenting a public API, or when judging whether docs are good enough to ship.
version: 1.1.0
---

# Documentation Standards

## Overview

Documentation serves readers, not the author's knowledge. Every documentation decision starts with one question: "What does the reader need?" Code shows *what* was built; documentation explains *why it was built this way*, *how to use it*, and *what to do when it breaks*. The eight quality dimensions below turn that reader-first principle into checkable criteria so you can judge any document against them instead of by feel.

Master the principles, and templates follow. A document that scores well across all eight dimensions serves its reader regardless of which template it started from.

## When to Use

- Writing a README, API reference, tutorial, or changelog
- Documenting a public API, library interface, or endpoint
- Reviewing existing docs for quality before shipping
- Writing user-facing error messages
- Deciding whether documentation is complete enough to release

**When NOT to use:** Don't document obvious code or restate what the code already says. Don't write docs for throwaway prototypes. Don't add placeholder docs you can't keep accurate: stale docs are worse than none.

**Related:** [structured-writing](../structured-writing/SKILL.md) for capturing content while preserving voice; [system-architecture](../system-architecture/SKILL.md) for ADRs that record decision rationale; [design-principles](../design-principles/SKILL.md) for domain naming carried into docs; [data-visualization](../data-visualization/SKILL.md) for diagrams and tables that replace walls of text.


## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Reader first | User-task-centered, not code-centered |
| No lies | No broken links, untested examples, outdated info |
| Test everything | Every code sample runs, every link resolves |
| Principles over templates | Master principles; templates follow |

## 8 Quality Dimensions

### 1. Clarity

| Criterion | Requirement |
|-----------|-------------|
| Simple words | No unexplained jargon |
| No ambiguous pronouns | "it", "this" have clear referents |
| Active voice | "Create a client" not "A client is created" |
| One idea per sentence | Split complex sentences |
| 15-20 words per sentence | Target average |

### 2. Accuracy

| Criterion | Requirement |
|-----------|-------------|
| All facts verified | Checked against source |
| All code samples tested | Run before publishing |
| All steps reproducible | Follow your own guide |
| No outdated information | Current version only |
| Version-specific labeled | "Added in 2.0" clearly marked |

### 3. Conciseness

| Criterion | Requirement |
|-----------|-------------|
| No filler words | Every word earns its place |
| No redundant explanations | Say it once, clearly |
| Maximum density | Pack information in minimum space |

### 4. Structure

| Criterion | Requirement |
|-----------|-------------|
| Logical progression | What → Why → How |
| Clear headings | Information-carrying words first |
| Appropriate lists | Bullets for scannable content |
| No orphan subsections | Never one subsection alone |

### 5. Usability

| Criterion | Requirement |
|-----------|-------------|
| Designed for scanning | F-pattern, bullets, whitespace |
| Table of contents | For docs >500 words |
| Cross-references | Link related content |
| Findable via search | Uses vocabulary users search |

### 6. Consistency

| Criterion | Requirement |
|-----------|-------------|
| Same term for same concept | Throughout document |
| Consistent formatting | Code blocks, lists, headings |
| Consistent voice | Same tone throughout |

### 7. Completeness

| Criterion | Requirement |
|-----------|-------------|
| Prerequisites stated | What user needs before starting |
| Error cases documented | Not just happy paths |
| Related topics linked | "See also" where relevant |
| No missing steps | Numbered, verifiable |

### 8. Examples

| Criterion | Requirement |
|-----------|-------------|
| Real-world, not toy | Meaningful scenarios |
| Working code (tested) | Actually runs |
| Progressive complexity | Simple → advanced |
| Imports included | Copy-paste ready |

## Document Types

### README

**Purpose:** First impression. "What is this? Should I use it? How do I start?"

**Required sections:**
- Name and description
- Installation
- Basic usage
- License

**WRONG:**
```markdown
## Getting Started

Welcome to our project! We're excited that you're interested...
```

**CORRECT:**
```markdown
## Quick Start

Requires Node.js 18+.

npm install mylib
```

### API Reference

**Purpose:** "What can I call? What do I send? What do I get back?"

**Required for each endpoint:**
- Parameters with types
- Return type
- Error codes with causes AND solutions
- Request/response examples

**WRONG:**
```markdown
### authenticate()
Returns: True if successful
```

**CORRECT:**
```markdown
### authenticate(username, password, mfa_code?)

**Returns:** AuthToken with .token and .expires_at
**Raises:** InvalidCredentialsError, MFARequiredError

**Example:**
try:
    token = authenticate("user@example.com", "pass123")
except MFARequiredError:
    token = authenticate("user@example.com", "pass123", "123456")
```

### Tutorial

**Purpose:** Guided learning from start to finish.

**Required:**
- Numbered steps
- Each step: intro → content → verification
- Working end result
- Time estimate

### Changelog

**Purpose:** "What changed? When? Does it affect me?"

**Required:**
- Semantic versioning
- ISO dates
- Categories: Added, Changed, Fixed, Removed
- Human-written (not commit logs)

## Code Sample Rules

### WRONG: Incomplete

```javascript
client.send(message)
```

**Missing:** imports, initialization, error handling, output

### CORRECT: Complete

```javascript
import { Client, Message } from 'mylib';

const client = new Client({ apiKey: process.env.API_KEY });
const msg = new Message({ to: "user@example.com", body: "Hello" });

try {
  const result = await client.send(msg);
  console.log(`Sent: ${result.id}`); // Output: Sent: msg_123
} catch (error) {
  if (error instanceof RateLimitError) {
    console.log(`Rate limited. Retry after ${error.retryAfter}s`);
  }
}
```

### Code Sample Checklist

- [ ] Imports included
- [ ] Initialization shown
- [ ] Error handling included
- [ ] Output demonstrated
- [ ] Language tag on code block
- [ ] Copy-paste ready
- [ ] Tested and verified

## Writing Principles

### Sentence Level

| Principle | Bad | Good |
|-----------|-----|------|
| Strong verbs | "The error occurs when..." | "Dividing by zero raises..." |
| No "There is" | "There is a method that..." | "The validate() method..." |
| Active voice | "Staff hours are calculated by" | "The manager calculates" |
| Positive statements | "Do not close the valve" | "Leave the valve open" |

### Paragraph Level

| Principle | Requirement |
|-----------|-------------|
| Opening sentence | Front-load the point |
| 3-5 sentences | Max 7 per paragraph |
| One topic | Per paragraph |

### Document Level

| Principle | Requirement |
|-----------|-------------|
| Front-load | Critical info in first two paragraphs |
| Information-carrying headings | "Installation Guide" not "A Guide to Installation" |
| Progressive disclosure | Essential first, advanced on demand |

## Error Messages

Every error message answers:
1. **What went wrong?** (Specific)
2. **How do I fix it?** (Actionable)

**WRONG:**
```
Authentication failed
```

**CORRECT:**
```
Authentication failed. Check that your API key is valid at Settings > API Keys.
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The code is self-documenting" | Code shows *what*. It can't show *why*, what alternatives were rejected, or how to recover from errors. |
| "We'll write docs when the API stabilizes" | The doc is the first test of the design. Writing it stabilizes the API faster. |
| "Nobody reads docs" | Future engineers do, agents do, and your three-months-later self does. |
| "See the source code" | If a reader has to read the source, the doc failed. Document it or don't ship it. |

## Red Flags

- "See source code" instead of actual documentation
- Placeholder examples like `{ /* config */ }` that can't be run
- Commit logs pasted in as a changelog
- Undefined jargon assuming readers share your context
- Only happy paths documented; errors ignored
- Walls of text with no headings, lists, or whitespace
- Broken links or examples that no longer compile

## Verification

After writing or reviewing documentation:

### User-Centered Design
- [ ] Target user identified
- [ ] User goal stated
- [ ] Prerequisites listed
- [ ] Success criteria clear
- [ ] Next steps offered

### Content Quality
- [ ] First sentence explains purpose
- [ ] Active voice used
- [ ] Technical terms defined
- [ ] Assumptions stated explicitly

### Code Examples
- [ ] Imports included
- [ ] Complete and runnable
- [ ] Output shown
- [ ] Error handling included
- [ ] Tested and verified

### Accuracy
- [ ] API signatures match code
- [ ] Examples syntactically correct
- [ ] Version numbers current
- [ ] Links resolve
