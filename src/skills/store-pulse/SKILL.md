---
name: store-pulse
description: A live, at-a-glance overview of your store's health — surfaced as a Cowork dashboard artifact tracking your key ecommerce metrics. Use to check on how the overall store is doing, set up or customize what the dashboard tracks, or schedule a recurring summary.
---

# Store Pulse

A daily-driver ecommerce dashboard.

## Modes

**Detect existing setup before deciding what to do.** Call `mcp__cowork__list_artifacts` and look for an artifact with id `store-pulse-dashboard`. The artifact is the only source of truth — its presence means Store Pulse is set up, its absence means it's not. The artifact carries the full config baked in as `SP_CONFIG`.

When the artifact exists, **read `SP_CONFIG.domain.name` out of its HTML** before routing. The user's request may name a specific store (e.g. "Store Pulse for mejuri.com", "set this up for my widgets store") — if so, compare it to the existing artifact's domain.

Routing:

| Artifact exists? | User intent | Flow |
|---|---|---|
| Yes | Open-ended ("/store-pulse", "show me my dashboard") | **Open** |
| Yes | Specific change to the existing dashboard ("change the domain", "add a block", "update my schedule") | **Reconfigure** |
| Yes | Names a different domain than `SP_CONFIG.domain.name` | **Reconfigure — domain change** (see flow below) |
| No | Any | **Setup** |

When intent is unclear and an artifact exists, default to **Open**. Don't silently overwrite a working setup. Critically: if the user asks for Store Pulse on a new domain while an artifact for a different domain exists, do NOT route to Open and silently use the wrong data — that's the failure mode "all the data was for the wrong store." Route to Reconfigure — domain change so the artifact gets swapped over and the user knows about it.

---

## Open flow

The user already has Store Pulse set up. Goal: show them where to find the live artifact, then give them a quick read of how the store is doing right now with an inline editorial summary, then offer concrete threads to pull on. **Do not re-render or update the artifact** — Cowork's API doesn't expose a "surface this artifact" call that doesn't also rewrite the HTML, and rewriting on every Open trigger is wasteful churn.

1. **Read the config from the artifact.** Extract `const SP_CONFIG = {...}` from the existing artifact's HTML (use `mcp__cowork__list_artifacts` to find the artifact's path, then Read that file). If the artifact doesn't exist, re-route to Setup.

2. **Point them to the existing artifact:**

   Render a visual callout block using `show_widget`. On the left, show an arrow icon pointing left surrounded by a soft shape. To the right of the icon, 2 lines of text (below). For the text style, use a slightly lighter color and a regular font weight (400); for the bold parts, use one level heavier (500).
   
   - Main text: Look in your sidebar for a live artifact called **Store Pulse Dashboard**
   - Secondary text (smaller, greyed out): or find it in the **Live artifacts** area

   After the visual callout, add an extra paragraph gap before writing more content.

3. **Fetch a lightweight 24-hour snapshot.** Just enough to write a very short editorial summary — headline KPIs for the last 24 hours and the prior 24 hours (for deltas). Use the queries in `references/blocks/core-kpis.md`. Don't fetch every block; just core-kpis is enough for the summary. Tell the user what you’re doing.

4. **Write the editorial summary inline in chat.** 2-3 bullet points; lead with the most notable thing. Mix wins and concerns. Be specific with numbers but not exhaustive — no sub-bullets, no headers, no bold, italic, or markdown formatting. Same voice the dashboard's own editorial summary uses.

5. **Offer next-step threads via AskUserQuestion** (single-select):

   - Header: "Where to next?"
   - Question: "Pick a thread to pull on."
   - Options: 3 investigation prompts **drawn from the summary you just wrote** — each should target a specific signal the summary surfaced (a drop, a surprise, a notable trend, an outlier). Provide these in the same order they were listed in the editorial summary bullets. Frame as something to investigate, e.g. "Why did conversion fall 8pp?" or "What's driving the AOV jump?".
   - 4th option: "Edit my dashboard"

   If the summary surfaced fewer than 3 distinct threads, round out with general defaults: "Where's the biggest revenue opportunity?", "What changed since last week?".

6. **Routing the user's pick:**

   - **An investigation prompt** → Treat it as a fresh analysis question. Don't try to answer from the dashboard's data alone — start a real investigation by letting your normal skill-selection kick in (an installed Noibu analysis skill if one matches the topic; otherwise direct exploration of the relevant Noibu data). Don't reference Store Pulse's internal block names in your handoff — frame the question in the user's terms.
   - **"Edit my dashboard"** → Run **Reconfigure flow**. Ask what they want to change (blocks, domain, schedule) and only walk the relevant branch.

---

## Setup flow

Open with this exact sentence:

> "Setting up your Store Pulse dashboard — a live artifact that shows your key store metrics, ready whenever you want to check in. Let's personalize it with a few quick questions."

Then run these steps in order.

### 1. Domain

Call `noibu_ListDomains` to see what's actually available in the user's Noibu account. Then branch on what the user said:

- **User named a specific domain** (e.g. "/store-pulse for mejuri.com", "set this up for my widgets store"):
  - **Find a match in the returned list.** Compare case-insensitively, and accept reasonable variants (`mejuri.com` ↔ `www.mejuri.com`). If a match is found → use that one's UUID + name. Do NOT use a different domain just because the user's intent was unclear.
  - **If no match is found**, the user's named domain is not in their Noibu account. Tell them honestly:
    > "I don't see [domain they named] in your Noibu account. The domains available here are: [list]. Did you mean one of these, or do you need to connect [domain they named] to Noibu first?"
    Then stop and wait for their reply. Do not silently fall back to a different domain.
- **User didn't name a domain** (just "/store-pulse" or "set up Store Pulse"):
  - **One result** → use it.
  - **Multiple results** → ask which one via AskUserQuestion.

Save the chosen domain to `config.domain` as `{ id: <uuid>, name: <human name from Noibu> }`. Never invent a domain name; only use what `noibu_ListDomains` returned. Never claim "[domain] resolved" unless the name actually matches the user's input.

### 2. Optional blocks

- Always include `core-kpis` and `purchase-funnel` — don't ask.
- Ask once (multi-select, all three default-off):

  > "Your dashboard will include Core KPIs (sessions, engagement, conversion, AOV, revenue per session) and a Purchase Funnel by default. Anything else you'd like to add?"
  >
  > - **Top products** — top 5 by traffic with add-to-cart rate
  > - **Channel performance** — sessions and conversion by traffic source
  > - **Paid ad performance** — spend, ROAS, conversions per ad platform (connect from the dashboard later)

- Read `references/blocks/<id>.md` for each picked block before continuing.

### 3. Render the artifact

Config gets baked into the artifact's HTML as `const SP_CONFIG = {...}` via the `__CONFIG_JSON__` placeholder. The artifact is the only persistent store — don't write config to disk. Schedule is NOT in `SP_CONFIG`; if step 4 sets one up, those values bake into the cron prompt instead.

Config shape:

```json
{
  "version": 1,
  "domain": { "id": "uuid", "name": "www.example.com" },
  "blocks": ["core-kpis", "purchase-funnel", "..."]
}
```

Procedure:

1. Read `assets/dashboard.html`.
2. Run `scripts/render_dashboard.py` to substitute `__CONFIG_JSON__` with the config JSON exactly. Don't modify any other part of the HTML.
3. Call `mcp__cowork__create_artifact` with `id: "store-pulse-dashboard"`, `html_path: <the substituted file>`, `mcp_tools: ["noibu_search_sessions", "noibu_googleads_search_stream_gaql"]`.

Use the template verbatim — the renderers, labels, funnel step names, and per-cell empty states (including "Connect Google Ads" handling on the paid block) are all built in. Don't call discovery tools (`mcp__mcp-registry__list_connectors`, `noibu_list_connections`) during this step, and don't surface tool output to the user. If `create_artifact` fails, retry with the same HTML.

Confirm: "Store Pulse is set up. The dashboard is live in your sidebar — open it whenever you want to check the store."

### 4a. (Post-render) Offer the scheduled report

Ask and stop your turn — wait for the user's reply before rendering anything in step 4b.

> "Want me to set up a recurring Store Pulse report? I can send it on whatever cadence works for you — email or Slack."

### 4b. (Only after explicit user confirmation) Render the scheduling form

If they declined, skip to step 5a — don't bring up scheduling again. If they confirmed:

1. Read the `## Scheduling form widget` section of `references/schedule.md` for the form HTML. Pass that HTML verbatim — don't reconstruct from memory, don't trim, don't rename ids or classes (the form's JS depends on every selector).
2. Render it by calling **`mcp__visualize__show_widget`** with title `schedule_store_pulse`. This is the only renderer that makes the form's `sendPrompt` button auto-send; embedding the HTML inline in chat or via `create_artifact` will only pre-fill the input. If you haven't loaded the visualize module yet in this session, call `mcp__visualize__read_me` with `modules: ["interactive"]` once first (silently).
3. When the user submits, `sendPrompt` fires with `Schedule Store Pulse report: frequency=X, day=Y, time=Z, delivery=email and slack, detail=summary`. Parse all five fields, then ask for each picked delivery's target:
   - **Email** → "What email address should the draft be addressed to?"
   - **Slack** → "Which Slack channel should it post to?" Use `slack_search_channels` to help. If that errors, tell them once: "You'll need the Slack connector — install it at https://claude.ai/directory/connectors/slack" and stop.
4. Create a single cron via `mcp__scheduled-tasks__create_scheduled_task` — the prompt template, snapshot-window math, and channel-specific message bodies all live in `references/schedule.md`. Bake the user's frequency / day / time / deliveries / detail level directly into the cron prompt at create-time; the cron is its own source of truth and the dashboard doesn't display anything schedule-related. **Do not update the artifact** — the schedule lives entirely in the cron task, not in `SP_CONFIG`. Re-rendering the artifact just for a schedule change is wasted churn.

5. Confirm with the user, **including the permission note** — the cron needs to be run manually once so it has permission to send on the user's behalf. Without this, the first scheduled run will fail or stall on a permission prompt the user isn't there to see. Example confirmation:
   > "Scheduled — your Store Pulse report will go out [readable summary, e.g. 'every Monday at 9am to #ops-pulse and anna@example.com']. One heads-up: you'll need to run the task once manually from your scheduled tasks to grant the permissions it needs to send on your behalf. After that first run, it'll deliver on its own."

If the user clicks Skip on the form, acknowledge and move on to step 5a (skip the cron creation and confirmation note).

### 5a. (Post-schedule) Ask whether to dig into the data

Whether the user scheduled a recurring report or skipped it, ask **and then stop your turn** — wait for their reply before doing anything in step 5b.

> "Want to dig into the data? I can surface a quick read of how the store is doing right now and some threads worth investigating."

Don't fetch the snapshot, don't write a summary, don't pre-render a question — none of that happens until the user says yes.

### 5b. (Only after explicit user confirmation) Surface the summary and threads

If they declined ("no thanks", "later", silence pivot), acknowledge briefly and end. Don't bring it up again.

If they confirmed:

1. **Fetch a lightweight 24-hour snapshot** — headline KPIs for the last 24 hours and the prior 24 hours (for deltas). Same query as Open flow step 2; see `references/blocks/core-kpis.md`.

2. **Write the editorial summary inline in chat.** 2-3 sentences, plain prose, lead with the most notable thing. No bullets, no headers, no markdown.

3. **Offer next-step threads via AskUserQuestion** (single-select):

   - Header: "Where to next?"
   - Question: "Pick a thread to pull on."
   - Options: 3 investigation prompts **drawn from the summary you just wrote** — each targeting a specific signal (a drop, a surprise, a notable trend, an outlier).
   - 4th option: "Not right now"

   If the summary surfaced fewer than 3 distinct threads, round out with general defaults: "Where's the biggest revenue opportunity?", "What changed since last week?".

4. **Routing the user's pick:**

   - **An investigation prompt** → Treat it as a fresh analysis question (same handoff pattern as Open flow). Don't answer from the snapshot alone; let your normal skill-selection pick the right approach based on the topic. Frame the question in the user's terms.
   - **"Not right now"** → acknowledge briefly and end.


---

## Reconfigure flow

Walk the relevant branch only. For block/domain changes: read `SP_CONFIG` from the existing artifact, mutate, re-render via `scripts/render_dashboard.py`, call `mcp__cowork__update_artifact`. Never recreate the artifact unless it's missing.

- **Block change** → modify `blocks`, update artifact.
- **Domain change** → Store Pulse is single-domain in v1, so changing the domain *replaces* the existing dashboard. First, call `noibu_ListDomains` and check that the new domain exists in the user's Noibu account (use the matching logic from Setup step 1 — case-insensitive, accept `www.` variants). If it's not there, tell the user what IS available and stop. If it is there, confirm before mutating:
  > "Switching your Store Pulse from [current_domain] to [new_domain] — this replaces the existing dashboard's data source. The metrics for [current_domain] will no longer be visible here. Continue?"
  After the user confirms, update `SP_CONFIG.domain` to the new `{ id, name }`, re-render, and update the artifact. If a scheduled cron exists, also update its prompt via `mcp__scheduled-tasks__update_scheduled_task` (the domain values are baked in).
- **Scheduled report change** (frequency / channel / time / target / detail level) → `mcp__scheduled-tasks__update_scheduled_task` with a new pre-substituted prompt. Don't touch the artifact — schedule lives in the cron task, not `SP_CONFIG`.
- **Disable scheduled report** → delete the cron task. Don't touch the artifact.
- **Artifact missing / "I deleted my dashboard"** → config is gone with it. Re-run Setup.

---

## File map

```
store-pulse/
├── SKILL.md
├── references/
│   ├── blocks/{core-kpis,purchase-funnel,top-products,channel-performance,paid-performance}.md
│   └── schedule.md
├── scripts/
│   └── render_dashboard.py
└── assets/
    └── dashboard.html
```

For block specs (metrics, queries, tooltips), read `references/blocks/<id>.md`. For scheduled-report setup (windows, cron expressions, channel message formats, cron prompt template), read `references/schedule.md`.
