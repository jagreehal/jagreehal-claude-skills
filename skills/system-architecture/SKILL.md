---
name: system-architecture
description: "Design systems for change. Trade-off analysis, ADR documentation, pattern selection. Architecture decisions must have documented rationale."
version: 1.0.0
---

# System Architecture

Design systems for change. Every architecture decision answers: "How will this scale and evolve?"

## Core Principle

There are no best practices—only trade-offs in context. The best architecture is the simplest one that meets current needs while enabling future growth.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Trade-offs over absolutes | No "best" - only "best for this context" |
| Simplicity that scales | Earn complexity, don't assume it |
| Decisions with rationale | ADRs for significant choices |
| Boundaries and contracts | Enable teams to move independently |

## Architecture Evaluation

When evaluating architecture, always:

1. **Understand context first**
   - Business requirements
   - Team capabilities
   - Constraints (time, budget, skills)

2. **Identify 2-3 valid approaches**
   - Never present only one option

3. **Analyze trade-offs explicitly**
   - What do you gain?
   - What do you give up?

4. **Think long-term**
   - What will be hard to change later?

5. **Document the decision**
   - Use ADR format

## Architecture Patterns

### When to Use What

| Pattern | When | Trade-offs |
|---------|------|------------|
| Monolith | Small team, unclear domain boundaries, speed matters | Simple deployment, harder to scale teams |
| Modular Monolith | Growing team, clearer boundaries, want deployment simplicity | Structure without operational complexity |
| Microservices | Large org, independent team deployment, clear bounded contexts | Team autonomy, operational complexity |
| Serverless | Event-driven, variable load, minimal ops desire | Scaling built-in, cold start latency |

### WRONG - Follow the Trend

```
"We should use microservices because that's what Netflix does."
```

**Problem:** Following trends without understanding context.

### CORRECT - Context-Driven Decision

```
Given:
- Team of 5 developers
- Single deployment target
- Unclear domain boundaries still evolving

Recommendation: Modular monolith

Rationale: Microservices would add operational complexity
(service mesh, distributed tracing, deployment coordination)
without the benefit of independent team scaling.

When to revisit: If team grows >15 or we identify clear
bounded contexts with different scaling requirements.
```

## Trade-Off Analysis Framework

For every significant decision, document:

| Dimension | Option A | Option B |
|-----------|----------|----------|
| Development speed | | |
| Operational complexity | | |
| Team independence | | |
| Consistency guarantees | | |
| Scaling characteristics | | |
| Cost (infra + people) | | |

## ADR Template

```markdown
# ADR-XXX: [Decision Title]

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD

## Context

[What issue are we facing? What constraints exist?]

## Decision

[What did we decide?]

## Consequences

### Positive
- [Benefit]

### Negative
- [Drawback]

## Alternatives Considered

### [Option Name]
**Why rejected:** [Reason]
```

### Example ADR

```markdown
# ADR-001: Use PostgreSQL for primary data store

**Status:** Accepted
**Date:** 2024-01-15

## Context

We need a primary data store for user data, orders, and inventory.
Requirements: ACID transactions, complex queries, team familiarity.

## Decision

Use PostgreSQL 15 as the primary data store.

## Consequences

### Positive
- ACID guarantees for financial data
- Team has 5+ years PostgreSQL experience
- Rich ecosystem (PostGIS, pg_trgm, etc.)
- Proven at our expected scale (100k users)

### Negative
- Vertical scaling limits (can address with read replicas)
- Schema migrations require coordination

## Alternatives Considered

### MongoDB
**Why rejected:** Team lacks experience, eventual consistency
problematic for order processing.

### DynamoDB
**Why rejected:** Complex queries (reporting) would require
additional infrastructure. Cost unpredictable with access patterns.
```

## Database Selection

| Type | Use When | Trade-offs |
|------|----------|------------|
| Relational (Postgres) | ACID needed, complex queries | Scaling complexity |
| Document (MongoDB) | Flexible schemas, embedded data | Weaker consistency |
| Key-Value (Redis) | Caching, sessions, fast lookups | Limited queries |
| Graph (Neo4j) | Relationship-heavy queries | Specialized |
| Time-Series (InfluxDB) | Metrics, events, IoT | Append-optimized |

## Scalability Patterns

### Order of Consideration

1. **Vertical scaling** - Bigger machine (simplest)
2. **Caching** - CDN → Application → Database
3. **Read replicas** - Separate read/write traffic
4. **Horizontal scaling** - Multiple instances
5. **Sharding** - Partition data (most complex)

### Resilience Patterns

| Pattern | Purpose |
|---------|---------|
| Retry with backoff | Handle transient failures |
| Circuit breaker | Prevent cascade failures |
| Bulkhead | Isolate failure domains |
| Timeout | Bound waiting time |
| Graceful degradation | Partial service over no service |

## API Design Principles

### REST

| Principle | Requirement |
|-----------|-------------|
| Resource modeling | Nouns, not verbs |
| HTTP semantics | GET reads, POST creates, PUT replaces |
| Versioning | URI (/v1/) or header |
| Pagination | Cursor-based for large sets |
| Error responses | Problem Details (RFC 7807) |

### Event-Driven

| Consideration | Guidance |
|---------------|----------|
| Event schema | Version events, use schema registry |
| Ordering | Partition key for ordering guarantees |
| Idempotency | Handle duplicate delivery |
| Dead letter | Handle poison messages |

## Distributed Systems Fundamentals

### CAP Theorem

Choose two: Consistency, Availability, Partition Tolerance.

In practice: During network partition, choose consistency OR availability.

### Consistency Models

| Model | Meaning | Use When |
|-------|---------|----------|
| Strong | All reads see latest write | Financial data |
| Eventual | All reads eventually see latest | Social feeds, caches |
| Causal | Cause-effect ordering preserved | Collaborative editing |

## Integration

| Skill | Relationship |
|-------|--------------|
| `design-principles` | Apply to architecture decisions |
| `pattern-enforcement` | Enforce boundaries with tooling |
| `documentation-standards` | Document architectural decisions |

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| Architecture astronauting | Designing for problems you don't have |
| Premature optimization | Optimize without data |
| Trend following | "Netflix does it" isn't a reason |
| Undocumented decisions | Become mysterious legacy constraints |
| Over-engineering | Complexity without justification |
| Ignoring team capabilities | Architecture must match team |

## Decision Checklist

When making architecture decisions:

- [ ] Did I understand the context first?
- [ ] Did I identify multiple valid approaches?
- [ ] Did I analyze trade-offs explicitly?
- [ ] Did I consider what's hard to change later?
- [ ] Did I document the rationale (ADR)?
- [ ] Does this match team capabilities?
- [ ] Is this the simplest solution that works?
