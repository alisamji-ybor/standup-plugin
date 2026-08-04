---
name: summarize-work
description: Summarize your recent work into a standup update (what you did yesterday, blockers, open PRs) using Jira as the source. This skill takes an explicit date range — it does no date math itself. `$since` (inclusive) and `$until` (exclusive) must be passed in as `YYYY-MM-DD` when you invoke it, e.g. `/summarize-work 2026-07-23 2026-07-24` for "yesterday" relative to 2026-07-24.
disable-model-invocation: false
user-invocable: true
arguments: [since, until]
argument-hint: "[since] [until]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/skills/summarize-work/scripts/fetch-jira-data.sh *)
model: haiku
---

## Data

### Jira data for $since (inclusive) to $until (exclusive)
!`${CLAUDE_PLUGIN_ROOT}/skills/summarize-work/scripts/fetch-jira-data.sh $since $until`

This returns one JSON object: `{"statusChanges": [...], "created": [...], "blockers": [...], "sprintTickets": [...]}`.
- `statusChanges`: issues assigned to you with a status change in the window, each `{key, issueType, summary, status}`.
- `created`: issues you created in the window, each `{key, summary, issueType}`.
- `blockers`: issues assigned to you currently in "Blocked" status, each `{key, issueType, summary, status}`.
- `sprintTickets`: every issue assigned to you in the current sprint, each `{key, issueType, summary, status, comments}`, where `comments` is up to the 5 most recent comments as `{author, created, body}` (may be empty).

## Your task

If the data above is not valid JSON, or any of `statusChanges`/`created`/`blockers`/`sprintTickets` is `null` instead of an array, stop and tell the user to re-run the skill with two valid dates, e.g. `/summarize-work 2026-07-23 2026-07-24`. Don't guess at dates yourself.

Otherwise, using only the data above, write a standup update with exactly these three sections, in this order:

### What I did yesterday
- Build the set of issue keys to report: every key in `statusChanges` and `created`, plus every key in `sprintTickets` that has at least one comment whose `created` timestamp falls in `[$since, $until)` (comment-only activity — the ticket's status field itself didn't change).
- For metadata (issue type, summary, status) of a key not present in `statusChanges`/`created`, look it up in `sprintTickets`.
- Skip any issue whose status is "To Do" or "Backlog".
- For an issue whose status is "Done" or "Closed", phrase bullets in past tense as completed work.
- For any other status, phrase bullets in progressive tense, making clear the work is still in progress (not finished).
- Bullet count per key: if the key has one or more in-window comments in `sprintTickets`, emit one bullet per in-window comment that describes a distinct piece of work — don't merge separate activities (e.g. "identified root cause" and "merged the fix") into one bullet. If a single comment covers only one activity, or the key has no in-window comments, emit exactly one bullet for the key. Never split a single activity into multiple bullets, and never merge distinct activities into one.
- Synthesize: for each bullet, combine what's known about that piece of work into one concise line in your own words. Don't just restate raw field values verbatim, and don't quote comment bodies verbatim.
- If there's no data left after the above, write "No tracked activity in this period."

### Blockers
- One bullet per issue in `blockers`, formatted as `KEY: summary`. If that same key appears in `sprintTickets` with comments, and the most recent comment states a reason it's blocked, append a terse reason in your own words, e.g. `KEY: summary — blocked on X`.
- If `blockers` is empty, write "No blockers."

### Open PRs
- Always write: "Not tracked yet — no GitHub source configured for this skill."

Don't add any other sections, commentary, or invented details. Keep bullets terse — this is a standup update, not a report.
