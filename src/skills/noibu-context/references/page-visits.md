# Page visits analytics

Read this reference when the user asks page-level questions: per-page traffic, time on page, web vitals (LCP/CLS/INP/FCP/TTFB/FID), landing/exit pages, visual errors, scroll depth, or cohort behaviour for a specific URL.

## noibu_PageVisitsQuery

Page-level analytics. One row per page visit. `orderBy` is REQUIRED at the `input` level. Use for:

- Per-page traffic: URL visit counts, per-page engagement, bounce by URL
- User interaction: `CLICKED_SELECTOR_COUNT` (total clicks), `CLICKED_SELECTORS` (CSS
  selectors clicked), `CLICKED_TEXT` (actual text users click — best signal for CTA
  effectiveness, rage-click detection, friction points)
- Page timing: `PAGE_VISIT_DURATION`, `PAGE_VISIT_START_TIME`, `PAGE_VISIT_END_TIME`
- Performance / web vitals — `LCP`, `CLS`, `INP`, `FCP`, `TTFB`, `FID`. **Use
  `QUANTILE_75` first** (the canonical Core Web Vitals statistic — Google's
  CrUX defines the "good / needs-improvement / poor" thresholds at p75, and
  the Noibu Console ranks pages by p75). Only use `MEDIAN` if the user
  explicitly asks for the median, or `QUANTILES` for the full distribution.
- Visual UX defects: `VISUAL_ERROR_COUNT`, `VISUAL_ERROR_SNIPPETS` collection
- Engagement depth: `MAX_SCROLL_DEPTH`, `MAX_PAGE_HEIGHT`, `VIEWPORT_HEIGHT`,
  `VIEWPORT_WIDTH`
- Navigation role: `IS_LANDING_PAGE`, `IS_EXIT_PAGE` (booleans per page visit)
- Page context: `PAGE_TITLE`, `LANGUAGE`, `REFERRING_URL`, `PREV_URL`, `PREV_PAGE_GROUPS` collection
- Page-level conversion: `CHECKOUT_COMPLETED` per-page, which specific pages are visited
  by converting sessions
- Cohort analysis (every page-visit row carries denormalized session context — no JOIN
  needed): `SESSION_BOUNCED`, `SESSION_CONVERSION_FUNNEL_DEPTH`, `SESSION_UTM_*`,
  `SESSION_ORDER_ID`, `SESSION_CUSTOMER_ID`, `SESSION_WS_PATH`
- Segmentation by: URL, `PAGE_TITLE`, `LANGUAGE`, browser, OS, device type, country,
  region, checkout status, `IS_LANDING_PAGE`, `IS_EXIT_PAGE`, `PREV_URL`,
  `SESSION_BOUNCED`, `SESSION_CONVERSION_FUNNEL_DEPTH`, `SESSION_UTM_*`

## Web vitals: aggregate at p75, not the mean

When the user asks "how is my LCP" / "what's my INP" / "which pages are slow", lead with `QUANTILE_75` of the relevant field. The 75th percentile is the canonical Core Web Vitals statistic (Google CrUX defines the good/poor thresholds at p75, and the Noibu Console ranks pages by p75). Do NOT use `AVG` — outliers distort it. Only use `MEDIAN` if the user explicitly asks for the median, or `QUANTILES` when they want the full distribution.

Web vitals and `VISUAL_ERROR_COUNT` live here, not in error tools. "Slow pages", "broken feeling", "UX quality" questions route to this tool — do NOT reach for error tools.
