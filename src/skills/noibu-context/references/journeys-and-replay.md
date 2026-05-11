# Journeys & session replay

Read this reference when the user asks about navigation paths, funnels, drop-off between specific pages, or when they explicitly want to watch / see / view a session replay.

## noibu_JourneyPaths

Navigation paths AND funnel reach around an ordered sequence of URL anchors (1–15 steps). Returns paths sessions took before (backward) and/or after (forward) the matched sequence, ranked by session count, plus per-step funnel reach (`anchorStepReach`).

USE for three question types:

1. **Navigation flow around a single page** — "what do users visit before/after page X":
   - "What sequences of pages do users visit after / before /checkout?"
   - "Show the navigation paths around the home page"
   - "What's the most common journey from product pages to checkout?"
   Use a single-step anchor; `anchor.mode` is moot for one step (pick either).

2. **Funnel / conversion analysis** — "how many users got from A → B → C":
   - "How many users go product → cart → checkout → confirmation?"
   - "What's the drop-off between login and account creation?"
   - "Where in the cart-to-purchase flow do most users abandon?"
   Use a multi-step anchor with `anchor.mode = LOOSE`. Real funnel sessions
   have intermediate page views; STRICT undercounts conversion.

3. **Direct-transition analysis** — "do users go directly from A to B":
   - "When users hit /cart, do they immediately go to /checkout, or browse more?"
   - "Did users follow /login → /account → /orders without detours?"
   Use a multi-step anchor with `anchor.mode = STRICT`.

DO NOT use for:

- Per-page traffic / engagement / web vitals → `noibu_PageVisitsQuery`
- Session-level aggregates (conversion rate, revenue, AOV) → `noibu_QuerySessions`
- "Where do users drop off" without specific anchor pages →
  `noibu_PageVisitsQuery` filtered by `IS_EXIT_PAGE=true`

## noibu_session_replay

Renders ONE page visit from a session as a video inside Claude's UI, and returns the session's full page-visit metadata (URLs, durations, key events per visit). May return a `jazzUrl` for the full session — use it only if present; never construct or mention a Noibu console link otherwise.

USE ONLY when the user **explicitly** asks to watch / see / view a session replay or video. Examples of when to call it:

- "Show me the session replay for sessionId=…"
- "Can I watch that session?"
- "I want to see where they got stuck in checkout"
- "Play back session X"

DO NOT use this tool as a data source for session summarization or analysis. The metadata it returns (page visits, events) is a convenience for UI navigation, NOT an analytics shortcut. For session summaries, cohort analysis, or "what did these users do" questions across multiple sessions, use `noibu_PageVisitsQuery` filtered by `SESSION_ID` — it's cheaper, aggregates cleanly, and doesn't render a video for each session.

Specifically:
- Do NOT call `noibu_session_replay` N times to pull event data for N sessions. That's what `noibu_PageVisitsQuery` is for.
- Do NOT call it just to "see what happened in the session" — use `noibu_PageVisitsQuery` for that.

**Page visit selection:**
- When `pageVisitIndex` is omitted, the tool auto-selects the most important page visit based on signal strength (errors, ecommerce events, navigation, time on page). The selected index is exposed as `importantIndex` in the response so you can explain why that page visit was chosen.
- Only specify `pageVisitIndex` when the user has expressed interest in a specific page visit (e.g., "show me page visit 3").

**Multiple replays:**
- When showing multiple replays from the same session, call the tool once per page visit and write the summary immediately after each replay before calling the tool for the next. This produces: [iframe] → summary → [iframe] → summary, rather than batching all summaries at the end.
