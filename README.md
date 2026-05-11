# Noibu AI Plugin

This repository contains a Claude plugin that provides two skills to help teams work with Noibu data and onboarding inside Claude/Cowork:
- noibu-context: A routing and reference guide for Noibu’s MCP tools, with detailed guidance on which tool to use for common analytics questions (sessions, page visits, web vitals, click/scroll maps, journeys/replay, errors, and integrations).
- noibu-connect: An interactive onboarding flow that checks and connects key integrations (Noibu MCP, Shopify, Google Ads, Klaviyo/Meta/Instagram, Mailchimp, Google Search Console, Gorgias) with a friendly step‑by‑step experience.

Both skills live under src/skills/ and are packaged as a Claude plugin.

## Prerequisites
- Claude Desktop installed (macOS recommended for dev/sync script).
- jq and zip installed (used by the task that packages the plugin).
- Task runner (go‑task). Install via: brew install go-task/tap/go-task on macOS, or see https://taskfile.dev.
- bash 4+ and rsync if you want to use the live sync script (macOS):
  - brew install bash rsync
- Optional: Claude CLI if you prefer validating from the terminal (claude plugin validate).

## Install (from a packaged zip)
1) Build the plugin archive
   - task pack
   - Output: dist/<plugin-name>-<version>.zip (derived from src/.claude-plugin/plugin.json)
2) Install into Claude Desktop
   - Open Claude Desktop → Settings → Plugins → Install from file…
   - Select the generated zip from the dist/ directory.
3) Restart Claude Desktop if prompted.

## Validate the plugin
- task validate
  - Runs claude plugin validate ./src
  - Ensures the manifest and skill front‑matter are correct before packaging.

## Local development workflow (macOS)
There are two convenient paths while editing files under src/:

### A) Validate + Pack + Reinstall loop (portable)
- Edit skill files under src/skills/…
- task validate
- task pack
- Reinstall the new zip via Claude Desktop → Settings → Plugins → Install from file…

### B) Live‑sync edited skills into an already‑installed plugin (fastest; macOS only)
- Ensure Claude Desktop is installed and that this plugin has been installed at least once.
- Sync all skills:
  - task sync
- Sync a single skill directory (e.g., noibu-context):
  - task sync -- noibu-context
- The sync script will locate the installed plugin’s skills/ directories under: ~/Library/Application Support/Claude
- Requirements: bash 4+, rsync

## Repository layout
- src/skills/noibu-context/: Skill reference and routing guide for Noibu MCP tools.
- src/skills/noibu-connect/: Guided onboarding skill for connecting Noibu and third‑party integrations.
- sync-skills.sh: macOS helper to rsync src/skills/* into the live installed plugin for quick iteration.
- taskfile.yaml: Tasks for validate, pack, clean, and sync.
- dist/: Build artifacts (git-ignored).

## Example usage
You don’t need to remember exact tool names—invoke the skills conversationally in Claude:

### noibu-context examples
- “What’s our checkout completion rate over the last 7 days by country?”
- “Which pages have the worst p75 LCP?”
- “Show me the clickmap for our /checkout page on mobile.”
- “Which traffic sources are converting best this month?”
- “How many users reach the footer on the homepage? Show a scrollmap too.”
- “I pasted this console.noibu.com link—what is it and what should I look at next?”

### noibu-connect examples
- “Help me set up Noibu.”
- “What integrations are connected right now?”
- “Reconnect Google Ads and Mailchimp.”
- “I’m onboarding for the first time—walk me through everything I should connect.”

## Troubleshooting
- The sync script says ‘bash 4+ is required’:
  - Install via brew install bash and ensure /usr/local/bin/bash or /opt/homebrew/bin/bash is first in PATH.
- The sync script can’t find Claude’s support directory:
  - Make sure Claude Desktop is installed and you’ve installed this plugin at least once (the script uses the presence of known skill folders to identify the correct plugin).
- claude plugin validate isn’t found:
  - Install or update the Claude CLI, or run the validate task inside an environment where the CLI is available.
- Packaging fails with jq/zip not found:
  - Install via brew install jq zip on macOS (or your OS package manager).

## Notes
- The version in src/.claude-plugin/plugin.json is used locally; CI may override it when building.
- orderBy is required for the Noibu analytics query tools; see src/skills/noibu-context/SKILL.md for detailed usage patterns.
