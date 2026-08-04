---
name: summarize-work
description: Summarize your recent work into a standup update (what you did yesterday, blockers, open PRs) using Jira as the source. This skill takes an explicit date range — it does no date math itself. `$since` (inclusive) and `$until` (exclusive) must be passed in as `YYYY-MM-DD` when you invoke it, e.g. `/summarize-work 2026-07-23 2026-07-24` for "yesterday" relative to 2026-07-24.
disable-model-invocation: false
user-invocable: true
arguments: [since, until]
argument-hint: "[since] [until]"
allowed-tools: Bash(acli jira workitem search *) Bash(jq *)
model: haiku
---

## Data

### Issues with a status change between $since and $until
!`acli jira workitem search --fields 'issuetype,summary,status' --jql 'project = "YP6M" AND status CHANGED DURING ($since, $until) AND assignee = currentUser()' --json | jq -c 'map({key, "issueType": .fields.issuetype.name, "summary": .fields.summary, "status": .fields.status.name})'`

### Issues created by you between $since and $until
!`acli jira workitem search --fields 'summary,issuetype' --jql 'project = "YP6M" AND creator = currentUser() AND created >= $since AND created < $until' --json | jq -c 'map({key, "summary": .fields.summary, "issueType": .fields.issuetype.name})'`

### Issues currently blocking you
!`acli jira workitem search --fields 'issuetype,summary,status' --jql 'project = "YP6M" AND assignee = currentUser() AND status = "Blocked"' --json | jq -c 'map({key, "issueType": .fields.issuetype.name, "summary": .fields.summary, "status": .fields.status.name})'`

## Your task

If any of the three data blocks above look like an error (not JSON) instead of results, stop and tell the user to re-run the skill with two valid dates, e.g. `/summarize-work 2026-07-23 2026-07-24`. Don't guess at dates yourself.

Otherwise, using only the data above, write a standup update with exactly these three sections, in this order:

### What I did yesterday
- One bullet per distinct issue key across the "status change" and "created by you" data sets combined — not one bullet per data set or per row.
- Skip any issue whose status is "To Do" or "Backlog".
- For an issue whose status is "Done" or "Closed", phrase the bullet in past tense as completed work.
- For any other status, phrase the bullet in progressive tense, making clear the work is still in progress (not finished).
- Synthesize: combine what's known about each issue (type, summary, status) into one concise bullet in your own words. Don't just restate raw field values verbatim.
- If there's no data left after the above, write "No tracked activity in this period."

### Blockers
- One bullet per issue in the "currently blocking you" data set, formatted as `KEY: summary`.
- If that data set is empty, write "No blockers."

### Open PRs
- Always write: "Not tracked yet — no GitHub source configured for this skill."

Don't add any other sections, commentary, or invented details. Keep bullets terse — this is a standup update, not a report.
