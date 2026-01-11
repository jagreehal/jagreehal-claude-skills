---
name: data-visualization
description: "Visualization is communication. Chart selection, encoding hierarchy, accessibility, rendering performance. Use established algorithms - these problems are solved."
version: 1.0.0
---

# Data Visualization

Visualization is communication. Every visual element must serve understanding.

## Core Principle

Choose encodings by perceptual accuracy. Use established algorithms. Never rely on color alone.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Use established algorithms | Check dagre, d3-force, ELK.js before custom |
| Perceptual accuracy | Position beats length beats angle beats area beats color |
| Never color alone | 8% of men are colorblind - use shape, pattern, labels |
| Match rendering to scale | SVG <1000, Canvas 1000-10000, WebGL >10000 |

## Visual Encoding Hierarchy

Cleveland & McGill (1984) - ranked by perceptual accuracy:

1. **Position along common scale** (most accurate)
2. Position on non-aligned scales
3. Length
4. Angle/slope
5. Area
6. Volume
7. **Color saturation/hue** (least accurate)

**Implication:** Bar charts (position) > pie charts (angle) > bubble charts (area)

## Chart Selection

### By Question Type

| Question | Chart | Why |
|----------|-------|-----|
| How do values compare? | Bar chart | Position encoding most accurate |
| How has this changed over time? | Line chart | Shows trends, handles many points |
| What's the distribution? | Histogram, box plot | Shows spread, outliers, shape |
| What's the relationship? | Scatter plot | Reveals correlation, clusters |
| What's the part-to-whole? | Stacked bar, treemap | Shows composition |
| What are the connections? | Network graph, Sankey | Shows relationships, flows |
| What's the hierarchy? | Tree, treemap | Shows parent-child structure |

### By Data Volume

| Volume | Approach |
|--------|----------|
| <20 points | Simple charts, direct labeling |
| 20-500 | Standard visualization |
| 500-5000 | Consider aggregation |
| 5000+ | Aggregation mandatory, or Canvas/WebGL |

## Design Anti-Patterns

| Anti-Pattern | Why Wrong | Fix |
|--------------|-----------|-----|
| Pie chart >5 slices | Hard to compare | Use bar chart |
| 3D charts | Distorts perception | Use 2D |
| Dual unrelated axes | Misleading correlation | Separate charts |
| Non-zero baseline | Exaggerates differences | Start at zero |
| Rainbow colormap | Perceptually uneven | Use viridis |
| Color-only encoding | Excludes colorblind | Add shape/pattern |

## Color

### Palette Types

| Type | Use Case | Examples |
|------|----------|----------|
| Sequential | Low to high values | Blues, viridis |
| Diverging | Diverge from midpoint | RdBu, BrBG |
| Categorical | Distinct categories | Set2, Tableau10 |

### Colorblind Safety

- **Never rely on color alone** - use shape, pattern, labels
- Safe sequential: viridis, cividis, plasma
- Test with: Coblis, Chrome DevTools color blindness simulator
- 8% of men, 0.5% of women affected

### Contrast Requirements

| Element | Ratio |
|---------|-------|
| Normal text | 4.5:1 (WCAG AA) |
| Large text | 3:1 |
| UI components | 3:1 |

## Rendering Technology

```
<1000 elements    → SVG
                    - DOM events work naturally
                    - Accessibility (ARIA) supported
                    - CSS styling

1000-10000        → Canvas
                    - Batch rendering
                    - Manual hit testing required
                    - requestAnimationFrame for animation

>10000            → WebGL
                    - GPU acceleration
                    - Sigma.js, deck.gl, regl
```

## Layout Algorithms → Libraries

**These problems are solved. Never implement from scratch.**

| Problem | Algorithm | Library |
|---------|-----------|---------|
| Layered/DAG graphs | Sugiyama | dagre, ELK.js |
| Force-directed networks | Fruchterman-Reingold | d3-force |
| Tree layouts | Reingold-Tilford | d3-hierarchy |
| Treemaps | Squarified | d3-hierarchy |
| Sankey diagrams | — | d3-sankey |
| Large graphs (10k+) | WebGL + spatial | Sigma.js, G6 |

## Performance Patterns

| Pattern | When |
|---------|------|
| Web Workers | Layout computation (never block main thread) |
| Spatial indexing | Hit detection with quadtree |
| Level-of-detail | Simplify distant/small elements |
| Viewport culling | Only render visible |
| Debouncing | Expensive interactions |
| Aggregation | Too many points to render |

## Implementation Anti-Patterns

| Anti-Pattern | Why Wrong | Fix |
|--------------|-----------|-----|
| Custom graph layout | Reinventing solved problem | Use dagre/ELK |
| 5000 SVG nodes | Poor performance | Use Canvas |
| Main thread layout | Blocks UI | Use Web Worker |
| No spatial indexing | Slow hit detection | Use quadtree |
| Rendering off-screen | Wasted computation | Viewport culling |

## Accessibility

### Screen Reader Support

```html
<svg role="img" aria-labelledby="chart-title chart-desc">
  <title id="chart-title">Monthly Sales 2024</title>
  <desc id="chart-desc">Bar chart showing sales increasing
    from $10M in January to $15M in December</desc>
</svg>
```

### Keyboard Navigation

| Key | Action |
|-----|--------|
| Tab | Move between interactive elements |
| Arrow keys | Traverse data points |
| Enter/Space | Select |
| Escape | Cancel/close |

### Alternative Representations

- Data tables as fallback
- Text summaries of key insights
- Don't rely on color alone

## Library Selection

### Charts

| Library | Best For |
|---------|----------|
| D3.js | Custom, highly interactive |
| Observable Plot | Quick exploration |
| Recharts | React integration |
| ECharts | Feature-rich dashboards |
| Chart.js | Simple charts |

### Graphs

| Library | Best For |
|---------|----------|
| dagre | Layered DAGs, flowcharts |
| d3-force | Organic networks |
| Cytoscape.js | Graph analysis |
| Sigma.js | Large graphs (10k+) |

## Integration

| Skill | Relationship |
|-------|--------------|
| `design-principles` | Apply to visualization code |
| `ui-design-principles` | Chart styling and states |
| `documentation-standards` | Document chart decisions |

## Quick Reference

Before implementing visualization:

- [ ] What question am I answering? → Select chart type
- [ ] What's my data volume? → Select rendering technology
- [ ] Is there an established algorithm? → Use the library
- [ ] Is it accessible? → Color, keyboard, screen reader
- [ ] Does it follow perceptual best practices? → Encoding hierarchy

## Resources

| Resource | Use |
|----------|-----|
| data-to-viz.com | Chart selection decision tree |
| colorbrewer2.org | Accessible color palettes |
| D3 Gallery | Implementation patterns |
