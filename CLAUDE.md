# Claude Plugin for `acli`

## Claude Code Documentation

- Resolve relative links (e.g. `/en/skills`) against the docs index.
- Fetch the matching full URL when working on a specific plugin component (skills, agents, hooks, MCP servers, etc.).

## `acli` Conventions

- When an `acli` command offers an output or input format option, use ADF or JSON.
- ADF schema: https://go.atlassian.com/adf-json-schema
- Any skill, agent, or hook that produces ADF must validate its output against that schema before passing it to `acli`.
- **Jira only:** additionally verify every node and mark appears in https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/. Reject anything not listed there.

