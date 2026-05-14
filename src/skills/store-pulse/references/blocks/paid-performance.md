# Block: paid-performance

A per-platform table for paid ad spend and return — Google Ads, Facebook, and Instagram (each a separate Noibu toolkit).

## What it shows

| Column | Format | Source |
|---|---|---|
| Paid Ad Platform | String | Connected ad platform name |
| Spend | Currency | From the ad platform API |
| Sessions | Integer | Noibu sessions tagged to the platform via UTM |
| Conversions | Integer | Noibu sessions where `CHECKOUT_COMPLETED = true` AND tagged to the platform |
| Revenue | Currency | Sum of `CHECKOUT_COMPLETE_TOTAL_VALUE` for those converted sessions |
| ROAS | Multiplier | Revenue ÷ Spend |

This block is the only one that combines data from two sources per row: spend comes from the ad platform's own API; sessions, conversions, and revenue come from Noibu (matched via UTM).

## Data source dependencies

Supported platforms in v1: Google Ads, Facebook, and Instagram (each a separate Noibu integration toolkit). The block always renders **three rows** — one for each — regardless of connector state:

- **Connected platforms** show real data (spend, sessions, conversions, revenue, ROAS).
- **Unconnected platforms** show a "Connect" button inline in the row. Clicking it triggers a Noibu integration install via `noibu_connect` with the appropriate toolkit slug (`googleads`, `facebook`, or `instagram`). Once the user completes the Noibu auth flow and reloads the dashboard, the row populates.

> **Connector source.** Data-source integrations (Google Ads, Facebook, Instagram, Shopify, etc.) are managed through Noibu's connection system — never through Cowork's MCP registry.

This way the block never leaves the operator wondering "why is paid empty?" — it tells them exactly what's missing and offers the fix in place. Setup never asks about ad-platform connectors; the artifact handles it lazily.

## MCP calls

**Per platform — fetch spend.**

For Google Ads:
```
noibu_googleads_search_stream_gaql({
  query: "SELECT campaign.id, metrics.cost_micros FROM campaign WHERE segments.date BETWEEN '<start>' AND '<end>'"
})
```
Sum `cost_micros / 1_000_000` to get spend.

For Facebook and Instagram: equivalent through Meta's Marketing API via Noibu's facebook/instagram toolkits respectively. Confirm exact tool names when wiring up.

**For Noibu attribution — sessions, conversions, revenue per platform.**

One Noibu query, with a filter for the platform's UTM source patterns:

```json
{
  "queryInput": {
    "measures": [
      { "aggregate": { "measureAlias": "sessions", "measureFunc": "COUNT", "target": { "field": "SESSION_ID" } } },
      {
        "aggregate": {
          "measureAlias": "conversions",
          "measureFunc": "COUNT",
          "target": { "field": "SESSION_ID" },
          "filters": [{ "fieldName": "CHECKOUT_COMPLETED", "operator": "EQUALS", "comparisonValues": ["true"] }]
        }
      },
      {
        "aggregate": {
          "measureAlias": "revenue",
          "measureFunc": "SUM",
          "target": { "field": "CHECKOUT_COMPLETE_TOTAL_VALUE" }
        }
      }
    ],
    "filters": [
      { "fieldFilter": { "fieldName": "UTM_SOURCE", "operator": "IS_ANY_OF", "comparisonValues": ["<platform_utm_sources>"] } }
    ]
  }
}
```

Per-platform UTM source patterns:
- Google Ads: `["google", "googleads"]` with `utm_medium` ∈ `["cpc", "ppc", "paid"]`
- Facebook: `["fb", "facebook", "meta"]` with `utm_medium` ∈ `["cpc", "paid_social", "paidsocial"]`
- Instagram: `["ig", "instagram"]` with `utm_medium` ∈ `["cpc", "paid_social", "paidsocial"]`

Compute `roas = revenue / spend` client-side (avoid divide-by-zero — if spend is 0, show ROAS as `—`).

## Methodology tooltips

- **ROAS** (column header) → "Return on ad spend — revenue from attributed orders divided by ad spend."
- **Conversions** (column header) → "Last-touch attributed via UTM and matched to your store's order data. Will diverge from each ad platform's native conversion count due to attribution-window differences."

Don't add tooltips to Spend, Sessions, or Revenue — they're self-explanatory.

## Polarity

ROAS, Conversions, and Revenue are higher-is-better. Spend is neutral — don't apply a polarity color.

## Important attribution note

Sessions and Conversions/Revenue come from Noibu's own attribution (last-touch via UTM, matched to actual orders in the merchant's checkout). These will diverge from each ad platform's native reporting because:

1. Ad platforms use post-impression and view-through attribution windows (sometimes 7+ days) that Noibu doesn't.
2. Ad platforms count modeled conversions, not just observed ones.
3. UTM tracking is imperfect (lost params, custom domains, etc.).

This is why the methodology tooltip is important. Operators who compare Store Pulse's paid numbers to their Google Ads dashboard will see different figures and need to know why.

## Empty state

If a platform has zero spend in the window, show the row with `$0.00` spend and `—` for ROAS (don't divide by zero). Don't suppress the row — empty paid days are real and worth seeing.
