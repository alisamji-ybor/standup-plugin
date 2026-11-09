#!/usr/bin/env bash
# Fetch the Jira data sets summarize-work needs and emit one JSON object:
# { "statusChanges": [...], "created": [...], "blockers": [...], "sprintTickets": [...] }
# sprintTickets entries look like { key, issueType, summary, status, comments: [{author, created, body}] }
set -uo pipefail

since="${1:?usage: fetch-jira-data.sh <since YYYY-MM-DD> <until YYYY-MM-DD>}"
until_date="${2:?usage: fetch-jira-data.sh <since YYYY-MM-DD> <until YYYY-MM-DD>}"

status_changes=$(acli jira workitem search \
  --fields 'issuetype,summary,status' \
  --jql "project = \"YP6M\" AND status CHANGED DURING (\"$since\", \"$until_date\") AND assignee = currentUser()" \
  --json | jq -c 'map({key, "issueType": .fields.issuetype.name, "summary": .fields.summary, "status": .fields.status.name})')

created=$(acli jira workitem search \
  --fields 'summary,issuetype' \
  --jql "project = \"YP6M\" AND creator = currentUser() AND created >= \"$since\" AND created < \"$until_date\"" \
  --json | jq -c 'map({key, "summary": .fields.summary, "issueType": .fields.issuetype.name})')

# TODO: sprint_tickets and blockers can probably be combined in a single query.
blockers=$(acli jira workitem search \
  --fields 'issuetype,summary,status' \
  --jql 'project = "YP6M" AND assignee = currentUser() AND status = "Blocked" AND sprint in openSprints()' \
  --json | jq -c 'map({key, "issueType": .fields.issuetype.name, "summary": .fields.summary, "status": .fields.status.name})')

sprint_tickets=$(acli jira workitem search \
  --fields 'issuetype,summary,status' \
  --jql 'project = "YP6M" AND assignee = currentUser() AND sprint in openSprints() AND (status ="Blocked" OR updated >= "'$since'")' \
  --json | jq -c 'map({key, "issueType": .fields.issuetype.name, "summary": .fields.summary, "status": .fields.status.name})')
sprint_tickets="${sprint_tickets:-[]}"
[ -z "$sprint_tickets" ] && sprint_tickets="[]"

sprint_keys=$(jq -r '.[].key // empty' <<< "$sprint_tickets")

# acli's `comment list --json` pre-renders ADF comment bodies to plain text and
# joins block-level nodes (paragraphs, headings) with a space instead of a newline,
# so multi-paragraph comments come out looking like one run-on line. `workitem view
# --fields comment` returns the raw ADF body instead; render it ourselves so
# paragraph/heading/list/code-block structure survives as newlines.
adf_to_text_filter='
  def inline_text:
    if .type == "text" then .text
    elif .type == "hardBreak" then "\n"
    elif has("content") then ([.content[] | inline_text] | join(""))
    else "" end;
  def block_text:
    if .type == "codeBlock" then ([.content[]?.text] | join(""))
    elif .type == "bulletList" or .type == "orderedList" then
      ([.content[] | "- " + inline_text] | join("\n"))
    elif .type == "blockquote" then ("> " + inline_text)
    elif .type == "rule" then "---"
    elif .type == "table" then ([.content[]? | block_text] | join("\n"))
    elif .type == "tableRow" then ([.content[]? | inline_text] | join(" | "))
    else inline_text end;
  [.fields.comment.comments[]
    | {
        author: .author.displayName,
        created,
        body: (if (.body | type) == "string" then .body
               else ([.body.content[]? | block_text] | join("\n\n"))
               end)
      }
  ]
  | sort_by(.created) | reverse | .[0:5]
  | map({author, created, body})
'

sprint_tickets_with_comments="[]"
while IFS= read -r ticket_key; do
  [ -z "$ticket_key" ] && continue
  raw_view=$(acli jira workitem view "$ticket_key" --fields comment --json)
  ticket_comments=$(jq -c "$adf_to_text_filter" <<< "${raw_view:-null}")
  ticket_comments="${ticket_comments:-[]}"
  ticket_meta=$(jq -c --arg key "$ticket_key" 'map(select(.key == $key))[0]' <<< "$sprint_tickets")
  sprint_tickets_with_comments=$(jq -c \
    --argjson acc "$sprint_tickets_with_comments" \
    --argjson meta "$ticket_meta" \
    --argjson comments "$ticket_comments" \
    -n '$acc + [$meta + {comments: $comments}]')
done <<< "$sprint_keys"

status_changes="${status_changes:-null}"
created="${created:-null}"
blockers="${blockers:-null}"
[ -z "$status_changes" ] && status_changes=null
[ -z "$created" ] && created=null
[ -z "$blockers" ] && blockers=null

jq -ncM \
  --argjson statusChanges "$status_changes" \
  --argjson created "$created" \
  --argjson blockers "$blockers" \
  --argjson sprintTickets "$sprint_tickets_with_comments" \
  '{statusChanges: $statusChanges, created: $created, blockers: $blockers, sprintTickets: $sprintTickets}'

