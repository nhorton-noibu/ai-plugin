# Clickmaps & scrollmaps

Read this reference when the user asks about click or scroll behaviour on a page — either quantitative ("how many clicks", "% reaching footer", "rage-click hotspots") or visual ("show me the clickmap", "render the scrollmap overlay").

Metrics and visualizations are complementary, not either/or. Pair them when both numbers and a visual would help the user.

## noibu_clickmap_metrics

Alias for `noibu_PageVisitsQuery` (same handler, same input schema). Surfaced under this name so quantitative clickmap questions route here directly. Use for "how many clicks on X", "which CTA converts best", "top clicked elements on /pdp", rage-click hotspots, etc. Filter by URL and aggregate `CLICKED_SELECTOR_COUNT`, `CLICKED_SELECTORS`, or `CLICKED_TEXT` (the latter is the best CTA-effectiveness signal).

## noibu_scrollmap_metrics

Alias for `noibu_PageVisitsQuery` (same handler, same input schema). Surfaced under this name so quantitative scrollmap questions route here directly. Use for "% reaching the footer", "average scroll depth", "scroll-depth distribution", etc. Filter by URL and aggregate `MAX_SCROLL_DEPTH`, `MAX_PAGE_HEIGHT`, or `VIEWPORT_HEIGHT` / `VIEWPORT_WIDTH`.

## noibu_show_clickmap_visualization

Renders an interactive clickmap heatmap overlay on a page snapshot inside an MCP App iframe. Visual artifact only — the iframe payload has no per-element click counts. Pair with `noibu_clickmap_metrics` when the user would benefit from numeric backup alongside the heatmap.

The optional `metric` arg controls which button is preselected in the UI:
- `CLICKS` for general "what users click" overlays
- `CHECKOUT_CONVERSION` for elements correlated with conversion
- `REVENUE_PER_SESSION` for elements correlated with revenue

## noibu_show_scrollmap_visualization

Renders a scroll-depth heatmap overlay on a representative page snapshot inside an MCP App iframe. Visual artifact only — the iframe payload has no numeric scroll depths or percentages. Pair with `noibu_scrollmap_metrics` when the user would benefit from exact numbers alongside the heatmap.

## Always prefer the `_show_*_visualization` tools over generic visualizations

When the user wants to see click or scroll data, do NOT fall back to hand-rolled SVG/HTML, code-execution chart libraries, ASCII heatmaps, screenshots, or `mcp__visualize__show_widget`. The `noibu_show_*_visualization` tools render an interactive overlay on the actual page snapshot inside an MCP App iframe — generic substitutes lose the page context, the heatmap fidelity, and the preselectable metric (CLICKS / CHECKOUT_CONVERSION / REVENUE_PER_SESSION). Do not fall back to a generic visualization just because numeric data is already in hand; the iframe is the visualization.
