# acli — Claude Code plugin

A Claude Code plugin that bundles skills and agents for driving [`acli`](https://developer.atlassian.com/cloud/acli/), Atlassian's CLI, to work with Jira and Confluence.

## What you get

- **Skills** for common Jira and Confluence workflows (issue creation, transitions, search, page reads/edits, etc.).
- **Agents** that compose those skills into higher-level tasks (triage, status rollups, cross-referencing tickets and pages).

All operations go through `acli`, so anything the plugin can do, you can reproduce by hand at the shell.

## Requirements

- [Claude Code](https://code.claude.com)
- [`acli`](https://developer.atlassian.com/cloud/acli/) installed and authenticated against your Atlassian site

## Install

This plugin is currently developed in-tree. Point Claude Code at the plugin directory or install it from a marketplace once published.

## Status

Version `0.1.0` — early development. Skills and agents are being added incrementally.
