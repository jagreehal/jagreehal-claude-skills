---
name: ui-design-principles
description: "Design system principles for distinctive, implementation-ready interfaces. Context before design, show don't tell, every state documented."
version: 1.0.0
---

# UI Design Principles

Create distinctive, implementation-ready interfaces.

## Core Principle

Design with distinctive identity. Generic Bootstrap-looking interfaces fail to communicate brand or product differentiation.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Context before design | Research product, users, market first |
| Show, don't tell | Visual artifacts, not written descriptions |
| Implementation-ready | Every state documented, developers unblocked |
| Diverse exploration | Opposite ends of spectrums, not color variations |

## Discovery Requirements

### Never Skip Discovery

Before designing, answer:

| Question | Why |
|----------|-----|
| What type of product? | E-commerce ≠ SaaS ≠ dev tools |
| Who are the users? | Demographics, technical level, accessibility |
| What's the strategic goal? | Trust? Innovation? Speed? |
| What constraints exist? | Brand guidelines, accessibility, technical |

### Context Research

```
WRONG - Jump to design
"Here's a login page design with blue buttons"

CORRECT - Context first
Product: Developer tool (CLI companion)
Users: Developers, technical, keyboard-heavy workflows
Competitors: [screenshots with notes on patterns]
Strategic goal: Professional trust, technical credibility
Constraints: WCAG AA, dark mode preference in user research

Based on context, exploring 3 directions...
```

## Visual Direction Exploration

### What "Completely Diverse" Means

Explore opposite ends of design spectrums:

| Spectrum | End A | End B |
|----------|-------|-------|
| Era | Futuristic | Retro |
| Shape | Geometric/Sharp | Organic/Round |
| Color | Vibrant/Saturated | Muted/Desaturated |
| Weight | Bold/High contrast | Elegant/Subtle |
| Density | Minimal/Sparse | Expressive/Rich |
| Tone | Playful | Serious |
| Spacing | Tight/Dense | Spacious/Airy |
| Mode | Light | Dark |

### WRONG - Not Diverse

```
Direction A: Blue accent, rounded corners, light mode
Direction B: Green accent, rounded corners, light mode
Direction C: Purple accent, rounded corners, light mode
```

**Problem:** Only varying color.

### CORRECT - Completely Diverse

```
Direction A: Futuristic
- Sharp geometric edges
- Vibrant accent colors
- High contrast
- Minimal, data-dense

Direction B: Professional Classic
- Subtle rounded corners
- Muted, sophisticated palette
- Generous whitespace
- Traditional hierarchy

Direction C: Technical/Terminal
- Monospace typography
- Dark mode default
- High information density
- Developer-familiar patterns
```

## Implementation-Ready Design

### Every State Documented

| State | Must Define |
|-------|-------------|
| Default | Base appearance |
| Hover | Desktop interaction |
| Focus | Keyboard navigation (MUST be visible) |
| Active/Pressed | Click/tap feedback |
| Disabled | Unavailable state |
| Loading | Async operations |
| Error | Validation failures |
| Empty | No data state |

### WRONG - Missing States

```
Button design shows only default appearance
Form shows only filled state
List shows only populated state
```

### CORRECT - Complete Specification

```
Button states:
- Default: bg-blue-600 text-white
- Hover: bg-blue-700
- Focus: ring-2 ring-blue-400 ring-offset-2
- Active: bg-blue-800
- Disabled: bg-gray-300 text-gray-500 cursor-not-allowed
- Loading: spinner icon, pointer-events-none

Form field states:
- Empty: placeholder visible, border-gray-300
- Filled: value visible, border-gray-300
- Focus: border-blue-500, ring
- Error: border-red-500, error message below
- Disabled: bg-gray-100, cursor-not-allowed
```

## Design System Tokens

### Required Token Categories

| Category | Examples |
|----------|----------|
| Colors | Primary, secondary, semantic (error, success) |
| Typography | Scale, weights, line heights |
| Spacing | Consistent scale (4, 8, 12, 16, 24, 32, 48) |
| Borders | Radius scale, widths |
| Shadows | Elevation levels |
| Motion | Duration, easing curves |

### Token Example

```css
:root {
  /* Colors */
  --color-primary: #2563eb;
  --color-primary-hover: #1d4ed8;
  --color-error: #dc2626;
  --color-success: #16a34a;

  /* Typography */
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-6: 1.5rem;

  /* Borders */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.1);
}
```

## Accessibility Requirements

### Non-Negotiable

| Requirement | Standard |
|-------------|----------|
| Text contrast | 4.5:1 for normal, 3:1 for large text |
| Interactive contrast | 3:1 for UI components |
| Focus visible | Always visible focus indicator |
| Keyboard navigation | All interactions keyboard accessible |
| Color independence | Never rely on color alone |

### WRONG - Color Only

```
Error state: Red border only
Success state: Green checkmark only
```

### CORRECT - Multiple Indicators

```
Error state: Red border + error icon + error message text
Success state: Green checkmark + "Saved successfully" text
```

## Component Checklist

For every component, define:

- [ ] All interactive states (hover, focus, active, disabled)
- [ ] All data states (empty, loading, error, populated)
- [ ] Responsive behavior
- [ ] Accessibility requirements
- [ ] Spacing (internal and external)
- [ ] Typography specifications
- [ ] Color specifications (light and dark mode if applicable)

## Integration

| Skill | Relationship |
|-------|--------------|
| `design-principles` | Apply software design to UI patterns |
| `documentation-standards` | Document design decisions |
| `data-visualization` | Chart and graph design |

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| Generic Bootstrap look | No distinctive identity |
| "Diverse" = color variations | Not exploring design space |
| Missing states | Blocks developers |
| Color-only encoding | Accessibility failure |
| Skipping discovery | Context drives appropriate design |
| Written descriptions only | Show, don't tell |
| "Figure it out in dev" | Design should answer questions |
| AI-generated look | Purple gradients, generic fonts |

## Quick Reference

Before presenting design:
- [ ] Did I research context first?
- [ ] Are my directions genuinely diverse?
- [ ] Are all states documented?
- [ ] Is accessibility built in?
- [ ] Can developers implement without questions?
- [ ] Did I show visual artifacts, not just descriptions?
