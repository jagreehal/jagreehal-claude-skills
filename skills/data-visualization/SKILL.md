---
name: data-visualization
description: Selects chart types, encodings, rendering technology, and layout algorithms so a visualization communicates accurately and accessibly. Use when building charts, graphs, or dashboards, choosing between SVG/Canvas/WebGL, picking a graph layout, or making a visualization colorblind-safe and screen-reader accessible.
version: 1.1.0
---

# Data Visualization

## Overview

Visualization is communication. Every visual element must serve understanding, and the choices that determine whether it succeeds (which encoding, which chart, which rendering technology, which layout algorithm) are mostly solved problems with established answers. The job is to apply those answers, not reinvent them.

The core principle: choose encodings by perceptual accuracy, use established algorithms, match rendering to data scale, and never rely on color alone. Position is read more accurately than length, length more accurately than angle, angle more than area, area more than color. That ranking drives chart selection. Graph layout (Sugiyama, force-directed, Reingold-Tilford) and rendering thresholds (SVG, Canvas, WebGL) are equally settled. Reach for the library, not a custom implementation.

## When to Use

- Building charts, graphs, dashboards, or any data-driven visual
- Choosing a chart type for a given question or dataset
- Deciding between SVG, Canvas, and WebGL rendering
- Laying out a network, tree, DAG, or Sankey diagram
- Making a visualization colorblind-safe and screen-reader accessible
- Diagnosing why a chart is slow or misleading

**When NOT to use:** General UI styling unrelated to data display (use [ui-design-principles](../ui-design-principles/SKILL.md)), or static infographic art with no underlying data.

**Related:** [design-principles](../design-principles/SKILL.md) for the code behind the chart, [ui-design-principles](../ui-design-principles/SKILL.md) for chart styling and states, [documentation-standards](../documentation-standards/SKILL.md) for recording chart decisions.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Use established algorithms | Check dagre, d3-force, ELK.js before custom |
| Perceptual accuracy | Position beats length beats angle beats area beats color |
| Never color alone | 8% of men are colorblind, so use shape, pattern, labels |
| Match rendering to scale | SVG <1000, Canvas 1000–10000, WebGL >10000 |

## Visual Encoding Hierarchy

Cleveland & McGill (1984), ranked by perceptual accuracy:

1. **Position along a common scale** (most accurate)
2. Position on non-aligned scales
3. Length
4. Angle / slope
5. Area
6. Volume
7. **Color saturation / hue** (least accurate)

**Implication:** Bar charts (position) beat pie charts (angle) beat bubble charts (area). When a comparison matters, encode it with position.

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
| 20–500 | Standard visualization |
| 500–5000 | Consider aggregation |
| 5000+ | Aggregation mandatory, or Canvas/WebGL |

## Design Anti-Patterns

| Anti-Pattern | Why Wrong | Fix |
|--------------|-----------|-----|
| Pie chart >5 slices | Hard to compare angles | Use bar chart |
| 3D charts | Distorts perception | Use 2D |
| Dual unrelated axes | Implies false correlation | Separate charts |
| Non-zero baseline | Exaggerates differences | Start bars at zero |
| Rainbow colormap | Perceptually uneven | Use viridis |
| Color-only encoding | Excludes colorblind readers | Add shape/pattern/label |

## Color

### Palette Types

| Type | Use Case | Examples |
|------|----------|----------|
| Sequential | Low to high values | Blues, viridis |
| Diverging | Diverge from a midpoint | RdBu, BrBG |
| Categorical | Distinct categories | Set2, Tableau10 |

### Colorblind Safety

- Never rely on color alone; pair it with shape, pattern, or labels
- Safe sequential palettes: viridis, cividis, plasma
- Test with Coblis or the Chrome DevTools color-blindness simulator
- 8% of men and 0.5% of women are affected

### Contrast Requirements

| Element | Ratio |
|---------|-------|
| Normal text | 4.5:1 (WCAG AA) |
| Large text | 3:1 |
| UI components | 3:1 |

## Rendering Technology

Match rendering to element count. Crossing a threshold without changing technology is the most common cause of a janky chart.

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

## Layout Algorithms to Libraries

These problems are solved. Never implement from scratch: a hand-rolled layout will be slower, buggier, and worse-looking than the reference algorithm.

| Problem | Algorithm | Library |
|---------|-----------|---------|
| Layered / DAG graphs | Sugiyama | dagre, ELK.js |
| Force-directed networks | Fruchterman-Reingold | d3-force |
| Tree layouts | Reingold-Tilford | d3-hierarchy |
| Treemaps | Squarified | d3-hierarchy |
| Sankey diagrams | — | d3-sankey |
| Large graphs (10k+) | WebGL + spatial index | Sigma.js, G6 |

## Performance Patterns

| Pattern | When |
|---------|------|
| Web Workers | Layout computation; never block the main thread |
| Spatial indexing | Hit detection with a quadtree |
| Level-of-detail | Simplify distant or small elements |
| Viewport culling | Only render what's visible |
| Debouncing | Expensive interactions |
| Aggregation | Too many points to render meaningfully |

## Implementation Anti-Patterns

| Anti-Pattern | Why Wrong | Fix |
|--------------|-----------|-----|
| Custom graph layout | Reinventing a solved problem | Use dagre/ELK |
| 5000 SVG nodes | Poor performance | Use Canvas |
| Layout on the main thread | Blocks the UI | Use a Web Worker |
| No spatial indexing | Slow hit detection | Use a quadtree |
| Rendering off-screen elements | Wasted computation | Viewport culling |

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
| Enter / Space | Select |
| Escape | Cancel / close |

### Alternative Representations

- Provide a data table as a fallback
- Provide text summaries of key insights
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

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "A pie chart looks friendlier" | Readers can't compare angles. If the comparison matters, use a bar chart. |
| "I'll write my own layout, it's just a few nodes" | It's never just a few nodes, and edge-crossing minimization is a research problem. Use dagre. |
| "Color is enough to tell the series apart" | Not for 8% of men. Add shape, pattern, or direct labels. |
| "SVG is fine, it's only a few thousand nodes" | A few thousand SVG nodes will stutter. Move to Canvas past ~1000. |
| "Starting the axis at zero wastes space" | A non-zero baseline exaggerates differences and misleads. Start bars at zero. |

## Red Flags

- A custom graph-layout implementation when dagre/ELK/d3-force would do
- Thousands of SVG DOM nodes instead of Canvas or WebGL
- Layout computation running on the main thread
- Series distinguished by color alone
- Bar charts with a non-zero baseline
- Rainbow / jet colormap instead of a perceptually uniform one
- A chart with no `<title>`/`<desc>`, table fallback, or keyboard support

## Verification

Before shipping a visualization:

- [ ] What question does this answer? → chart type selected accordingly
- [ ] What's the data volume? → rendering technology matches the threshold
- [ ] Is there an established algorithm? → library used, not a custom implementation
- [ ] Colorblind-safe? → encoding uses shape/pattern/label, not color alone
- [ ] Accessible? → title, description, table fallback, keyboard navigation
- [ ] Perceptually honest? → position-based encoding, zero baseline, 2D, single axis meaning

## Resources

| Resource | Use |
|----------|-----|
| data-to-viz.com | Chart selection decision tree |
| colorbrewer2.org | Accessible color palettes |
| D3 Gallery | Implementation patterns |
