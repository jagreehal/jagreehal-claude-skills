---
name: documentation-standards
description: "User-centered documentation quality framework. Eight quality dimensions, document type requirements, and review checklist. Documentation exists to serve readers, not demonstrate knowledge."
version: 1.0.0
---

# Documentation Standards

Documentation exists to serve readers, not to demonstrate knowledge.

## Core Principle

Every documentation decision starts with: "What does the reader need?"

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Reader first | Not code-centered - user task-centered |
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

### WRONG - Incomplete

```javascript
client.send(message)
```

**Missing:** imports, initialization, error handling, output

### CORRECT - Complete

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

## Integration

| Skill | Relationship |
|-------|--------------|
| `concise-output` | Applies brevity to documentation |
| `design-principles` | Domain naming in docs |
| `validation-boundary` | Document schemas at boundaries |

## Review Checklist

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

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| "See source code" | Document it or don't ship it |
| `{ /* config */ }` examples | Placeholders can't be run |
| Commit logs as changelog | Write for humans |
| Undefined jargon | Readers don't share your context |
| Only happy paths | Errors happen |
| Walls of text | Readers scan, not read |
