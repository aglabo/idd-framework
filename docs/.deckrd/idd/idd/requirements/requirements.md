---
title: "Requirements: IDD command-to-agent-skill migration"
module: "idd/idd"
status: Draft
version: 1.3.0
created: "2026-07-31"
updated: "2026-07-31"
---

> **Normative Statement**
> This document defines binding requirements.
> Implementations MUST conform to this document.
> RFC 2119 keywords apply to this document only.

## 1. Overview

### 1.1 Purpose

Migrate the current command-form IDD workflows into agent skills so the workflows can be invoked as skills while improving maintainability, reducing duplicated orchestration, and making behavior easier to test.

### 1.2 Scope

The scope is the full IDD command set under `plugins/idd-framework/commands`: `/idd:issue:*`, `/idd-pr`, `/idd-commit-message`, `/validate-debug`, and the helper contracts and existing agents those workflows depend on.

The migration target is a set of Codex/Claude-compatible skill artifacts under `plugins/idd-framework/skills`. The skill invocation taxonomy MUST be reorganized from an `idd:*` top-level command family into purpose-first top-level families: `issue`, `branch`, `pr`, and `commit`. Because `:` is not portable in Windows paths, colon-separated invocation names are represented by path segments:

| Skill Invocation Name | Skill Artifact Path | Source Command | Primary Responsibility |
| --------------------- | ------------------- | -------------- | ---------------------- |
| `issue:new` | `plugins/idd-framework/skills/issue/new/SKILL.md` | `/idd:issue:new` | Create Issue drafts |
| `issue:list` | `plugins/idd-framework/skills/issue/list/SKILL.md` | `/idd:issue:list` | List and select Issue drafts |
| `issue:load` | `plugins/idd-framework/skills/issue/load/SKILL.md` | `/idd:issue:load` | Load GitHub Issues as local drafts |
| `issue:edit` | `plugins/idd-framework/skills/issue/edit/SKILL.md` | `/idd:issue:edit` | Edit selected Issue drafts |
| `issue:push` | `plugins/idd-framework/skills/issue/push/SKILL.md` | `/idd:issue:push` | Create or update GitHub Issues |
| `branch:new` | `plugins/idd-framework/skills/branch/new/SKILL.md` | `/idd:issue:branch new` | Create an Issue branch |
| `branch:commit` | `plugins/idd-framework/skills/branch/commit/SKILL.md` | `/idd:issue:branch commit` | Generate commit message flow for the current branch |
| `pr:new` | `plugins/idd-framework/skills/pr/new/SKILL.md` | `/idd-pr new` | Generate a Pull Request draft |
| `pr:view` | `plugins/idd-framework/skills/pr/view/SKILL.md` | `/idd-pr view` | View the current Pull Request draft |
| `pr:edit` | `plugins/idd-framework/skills/pr/edit/SKILL.md` | `/idd-pr edit` | Edit the current Pull Request draft |
| `pr:review` | `plugins/idd-framework/skills/pr/review/SKILL.md` | `/idd-pr review` | Review a Pull Request draft |
| `pr:push` | `plugins/idd-framework/skills/pr/push/SKILL.md` | `/idd-pr push` | Create a GitHub Pull Request |
| `commit:new` | `plugins/idd-framework/skills/commit/new/SKILL.md` | `/idd-commit-message new` | Generate a Conventional Commit message |
| `commit:view` | `plugins/idd-framework/skills/commit/view/SKILL.md` | `/idd-commit-message view` | View the current commit message |
| `commit:edit` | `plugins/idd-framework/skills/commit/edit/SKILL.md` | `/idd-commit-message edit` | Edit the current commit message |
| `commit:push` | `plugins/idd-framework/skills/commit/push/SKILL.md` | `/idd-commit-message commit` | Commit staged changes with the current message |
| `validate:debug` | `plugins/idd-framework/skills/validate/debug/SKILL.md` | `/validate-debug` | Validation and debugging workflow |
| `shared` | `plugins/idd-framework/skills/shared/SKILL.md` | helper commands and shell libraries | Shared helper contracts and adapters |

Existing agents `issue-generator`, `pr-generator`, and `commit-message-generator` remain reusable generation components unless a later specification records an explicit replacement.

**Out of Scope**: Keeping existing IDD slash commands as compatibility invocation wrappers, migrating non-IDD plugin features, replacing GitHub/Git service behavior, replacing `gh` with a connector in this phase, and redesigning the business meaning of the existing Issue, PR, branch, validation, or commit-message workflows.

## 2. Context

- Target Environment: `idd-framework` plugin used from Codex/Claude Code style agent runtimes.
- Related Components: `plugins/idd-framework/commands`, `plugins/idd-framework/agents`, `plugins/idd-framework/commands/_helpers`, `plugins/idd-framework/commands/_libs`, `plugins/idd-framework/skills`, `temp/idd/issues`, `temp/idd/pr`, `temp/commit_message_current.md`, Git, GitHub CLI, Bash, `jq`.
- Primary Stakeholder: AI agent users developing in Codex/Claude Code.
- Compatibility Assumption: Slash command invocation compatibility is intentionally not preserved, but observable workflow behavior SHOULD remain compatible unless a later specification records a replacement.

### System Context Diagram

```text
[User / AI Agent] --> +----------------------------------+ --> [GitHub CLI / GitHub API]
                      | IDD agent skill migration        |
[Existing Commands] ->| plugins/idd-framework/commands   | --> [temp/idd state files]
[Existing Agents] --->| plugins/idd-framework/agents     | --> [Skill runtime / MCP tools]
                      +----------------------------------+
```

## 3. Design Decisions (Summary)

| ID    | Decision                                                             | Linked Record |
| ----- | -------------------------------------------------------------------- | ------------- |
| DR-01 | Convert the full IDD command set into purpose-first nested skills      | N/A           |
| DR-02 | Do not keep slash command compatibility wrappers as invocation paths  | N/A           |
| DR-03 | Allow internal helper adapters that wrap existing Bash/helper logic   | N/A           |
| DR-04 | Prefer maintainability, deduplication, and testability over command-file parity | N/A |
| DR-05 | Continue using `gh`, `git`, Bash, and `jq` for this phase             | N/A           |
| DR-06 | Manage requirement document versions using semantic versioning        | N/A           |
| DR-07 | Replace the `idd` top-level command family with purpose-first families | N/A          |

## 4. Functional Requirements

### REQ-F-001: Skill Artifact Coverage

- EARS Type: feature/config-based

```text
GIVEN the idd-framework plugin contains existing IDD slash command definitions
  WHERE the command-to-agent-skill migration is implemented
THEN the system SHALL provide purpose-first skill artifacts under `plugins/idd-framework/skills`.
```

**Rationale**: The user confirmed that the full IDD command set is in scope.

### REQ-F-001A: Purpose-First Command Name Path Mapping

- EARS Type: feature/config-based

```text
GIVEN an existing IDD command or subcommand is converted to a skill invocation name
  WHERE the command is represented as a skill artifact on disk
THEN the system SHALL use a purpose-first invocation family such as `issue`, `branch`, `pr`, or `commit`, map each colon-separated segment to a nested directory segment, and place the skill definition in `SKILL.md`.
```

**Rationale**: This makes the command system easier to discover by purpose while avoiding non-portable `:` characters in Windows paths.

### REQ-F-001B: IDD Prefix Removal

- EARS Type: unwanted behavior

```text
GIVEN a converted skill has a user-facing invocation name
  NOT DO expose `idd` as the top-level invocation family
THEN the system SHALL expose the invocation through a purpose-first top-level family.
```

**Rationale**: The user requested `issue:new` style commands instead of `idd:issue:new`.

### REQ-F-001C: Branch Top-Level Family

- EARS Type: feature/config-based

```text
GIVEN the existing branch workflow is currently located under the Issue command family
  WHERE the workflow is converted to skill invocations
THEN the system SHALL expose branch workflow operations under the top-level `branch` family.
```

**Rationale**: The user requested `branch` as a top-level command family alongside `issue`, `pr`, and `commit`.

### REQ-F-002: Skill-First Invocation

- EARS Type: unwanted behavior

```text
GIVEN an IDD behavior has been converted to an agent skill
  NOT DO depend on an existing slash command file as a compatibility invocation wrapper
THEN the system SHALL expose that behavior through the corresponding agent skill.
```

**Rationale**: The user selected full migration to skills without slash command wrapper compatibility.

### REQ-F-003: Internal Helper Adapter Boundary

- EARS Type: feature/config-based

```text
GIVEN a converted skill needs behavior currently implemented by helper commands or shell libraries
  WHERE the behavior is reused from existing Bash/helper implementation
THEN the system SHALL call that behavior through an internal adapter contract and SHALL NOT expose that adapter as a slash command compatibility wrapper.
```

**Rationale**: This resolves the boundary between prohibited slash-command wrappers and allowed minimal helper wrappers.

### REQ-F-004: Shared Helper Contract Inventory

- EARS Type: event-driven

```text
GIVEN a helper command or shell library is reused by one or more converted skills
  WHEN the specification for that skill is written
THEN the system SHALL document the helper name, public functions or operations, inputs, outputs, exit codes, required environment variables, required external commands, and path-resolution rules.
```

**Rationale**: Existing workflows depend on `_get-summary`, `_edit-summary`, `_get-issue-types`, `_select-from-list`, and libraries under `_libs`.

### REQ-F-005: State File Contract Preservation

- EARS Type: state-driven

```text
GIVEN an IDD skill performs Issue, PR, branch, or commit-message workflow operations
  WHILE the workflow reads or writes existing local state
THEN the system SHALL preserve the current state file paths, draft filename formats, session keys, update ordering, and recovery behavior.
```

**Rationale**: The existing commands use local files as workflow state, not only as incidental storage.

### REQ-F-006: State Schema Definition

- EARS Type: event-driven

```text
GIVEN a converted skill reads or writes `.last.session`, `.last_draft`, `.branch.session`, PR draft state, or commit-message state
  WHEN the skill specification is produced
THEN the system SHALL define required keys, optional keys, value formats, atomic write expectations, stale-session handling, and failure recovery behavior for that state file.
```

**Rationale**: Preserving only the path is insufficient for compatibility.

### REQ-F-007: Operation-Specific Side Effect Gates

- EARS Type: event-driven

```text
GIVEN an IDD skill is about to perform a mutating operation
  WHEN the operation is a remote write, local Git mutation, local state mutation, draft rename, draft cleanup, or temporary file cleanup
THEN the system SHALL apply the approval or disclosure rule defined for that operation category before execution.
```

**Rationale**: Side effects include more than `gh` and `git` commands; local state updates and cleanup can also affect recovery.

### REQ-F-008: Side Effect Failure Handling

- EARS Type: event-driven

```text
GIVEN a mutating operation fails after one or more prior side effects have succeeded
  WHEN the skill reports the failure
THEN the system SHALL report completed side effects, preserve enough local state for recovery, and avoid claiming the workflow completed successfully.
```

**Rationale**: Existing workflows include multi-step operations such as GitHub issue creation followed by local draft rename.

### REQ-F-009: Existing Error Contract Preservation

- EARS Type: event-driven

```text
GIVEN an IDD skill encounters a known failure condition from the existing command implementation
  WHEN the skill handles the failure
THEN the system SHALL return an equivalent user-facing failure result and SHALL avoid partial state updates that contradict the existing command behavior.
```

**Rationale**: Known failures include missing `jq`, missing `gh`, missing GitHub authentication, missing session, invalid issue files, dirty worktree, branch conflicts, filename conflicts, and remote GitHub failures.

### REQ-F-010: Shared Classification Logic

- EARS Type: state-driven

```text
GIVEN multiple IDD skills need commit type, issue type, branch type, or reasoning classification
  WHILE classification is performed
THEN the system SHALL use a shared classification routine or shared helper contract rather than duplicating inconsistent logic.
```

**Rationale**: `_get-issue-types` is a cross-workflow contract for Issue creation, Issue loading, and branch workflows.

### REQ-F-011: Packaging Compatibility

- EARS Type: event-driven

```text
GIVEN a converted skill artifact is added under `plugins/idd-framework/skills`
  WHEN the plugin is packaged
THEN the system SHALL include the skill artifact and any shared adapter assets in the plugin package metadata and build output.
```

**Rationale**: Skill placement must be explicit before specification can proceed.

### REQ-F-012: Runtime Path Resolution

- EARS Type: event-driven

```text
GIVEN a converted skill invokes a reused Bash/helper implementation
  WHEN the skill resolves repository, plugin, command, helper, or library paths
THEN the system SHALL resolve paths from the active repository root and plugin root without assuming `.claude/commands` is the installed runtime path.
```

**Rationale**: Existing command snippets mention `.claude/commands/_libs`, while this repository stores plugin assets under `plugins/idd-framework/commands/_libs`.

### REQ-F-013: Requirement Version History Policy

- EARS Type: event-driven

```text
GIVEN the requirements document is revised
  WHEN the revision changes scope, artifact topology, external contracts, or normative requirements
THEN the document version SHALL increment the minor version, such as `1.1.0` to `1.2.0`.
```

**Rationale**: The user requested that large revisions be managed as minor version increments.

### REQ-F-014: Requirement Patch Version Policy

- EARS Type: event-driven

```text
GIVEN the requirements document is revised
  WHEN the revision only fixes wording, formatting, typos, or non-normative clarification
THEN the document version SHALL increment the patch version, such as `1.0.0` to `1.0.1`.
```

**Rationale**: The user requested that small revisions be managed as patch version increments.

## 5. Non-Functional Requirements

### REQ-NF-001: Maintainability

The implementation MUST centralize reusable behavior so converted workflows do not contain untracked duplicate classification, state persistence, filename generation, GitHub operation, or Git operation logic.

### REQ-NF-002: Testability

The implementation MUST define parity tests or acceptance checks for converted skills covering existing command behavior for Issue push, Issue branch, filename utilities, issue type classification, PR draft handling, commit message handling, and validation/debug execution.

### REQ-NF-003: Behavioral Compatibility

The implementation SHOULD preserve observable behavior for existing IDD workflows, including draft naming, session persistence, cancellation paths, validation failures, and success messages, except where a later specification explicitly records a replacement.

### REQ-NF-004: Safety

The implementation MUST document mutating operations for each skill and MUST protect remote writes and local Git mutations with explicit user approval.

### REQ-NF-005: Portability

The implementation MUST document runtime prerequisites for Bash, `jq`, `git`, and `gh`, including Windows execution expectations.

## 6. Constraints

### REQ-C-001: No Slash Command Compatibility Wrapper

Converted behavior MUST NOT rely on existing IDD slash command files as compatibility invocation wrappers.

### REQ-C-002: Internal Adapter Allowed

Converted skills MAY use internal adapters to call existing Bash/helper logic. Such adapters MUST be private implementation assets, not user-facing slash command compatibility wrappers.

### REQ-C-003: Skill Output Location

Converted skill artifacts MUST be placed under `plugins/idd-framework/skills` using purpose-first top-level directories: `issue`, `branch`, `pr`, `commit`, `validate`, and `shared`.

### REQ-C-004: External Dependency Continuity

This phase MUST continue to account for the existing `git`, `gh`, Bash, and `jq` assumptions. Moving GitHub operations to a connector is deferred.

### REQ-C-005: Existing Agent Reuse

Existing agents `issue-generator`, `pr-generator`, and `commit-message-generator` SHOULD remain reusable generation components unless a later specification records an explicit replacement.

## 7. User Stories

| Story ID | Role | Goal | Reason | Related Requirements |
| -------- | ---- | ---- | ------ | -------------------- |
| US-001 | AI agent user | Invoke IDD workflows as agent skills | Avoid relying on slash command invocation | REQ-F-001, REQ-F-002 |
| US-002 | idd-framework maintainer | Maintain shared workflow logic in one place | Prevent drift in classification, state, file, Git, and GitHub behavior | REQ-F-003, REQ-F-004, REQ-F-010 |
| US-003 | GitHub workflow user | Confirm side effects before they run | Avoid accidental remote writes, branch creation, or commits | REQ-F-007, REQ-F-008, REQ-NF-004 |
| US-004 | Test author | Compare converted skills against existing command behavior | Detect migration regressions | REQ-NF-002 |
| US-005 | Plugin packager | Include skill artifacts in plugin output | Ensure installed users can invoke the new skills | REQ-F-011 |

## 8. Acceptance Criteria

```gherkin
# AC-001: Skill artifact set exists
# Requirement: REQ-F-001
Scenario: Provide focused IDD skills
  Given the plugin contains existing IDD command workflows
  When  the migration is implemented
  Then  plugins/idd-framework/skills contains purpose-first nested SKILL.md artifacts for issue, branch, pr, commit, validate, and shared workflows

# AC-001A: Purpose-first command names map to directories
# Requirement: REQ-F-001A
Scenario: Map purpose-first command name to nested path
  Given the command name issue:new
  When  the skill artifact path is derived
  Then  the artifact path is plugins/idd-framework/skills/issue/new/SKILL.md

# AC-001B: IDD prefix is removed
# Requirement: REQ-F-001B
Scenario: Expose purpose-first command name
  Given the source command is /idd:issue:new
  When  the converted skill invocation name is derived
  Then  the invocation name is issue:new rather than idd:issue:new

# AC-001C: Branch is top-level
# Requirement: REQ-F-001C
Scenario: Move branch workflow to top-level family
  Given the source command is /idd:issue:branch commit
  When  the converted skill invocation name is derived
  Then  the invocation name is branch:commit

# AC-002: Full command inventory is mapped
# Requirement: REQ-F-001
Scenario: Map all IDD command definitions
  Given plugins/idd-framework/commands contains IDD command definitions
  When  the migration inventory is produced
  Then  /idd:issue:*, /idd-pr, /idd-commit-message, and /validate-debug are mapped to skill responsibilities

# AC-003: No slash command wrapper dependency
# Requirement: REQ-F-002
Scenario: Invoke converted behavior without slash wrapper
  Given an IDD behavior has an agent skill equivalent
  When  a user invokes the converted workflow
  Then  the behavior runs through the agent skill path without requiring a compatibility slash command wrapper

# AC-004: Internal adapter boundary is explicit
# Requirement: REQ-F-003
Scenario: Reuse helper behavior privately
  Given a skill needs existing helper behavior
  When  the skill calls that behavior
  Then  it uses an internal adapter contract that is not exposed as a user-facing slash command wrapper

# AC-005: Helper contract is specified
# Requirement: REQ-F-004
Scenario: Specify reused helper
  Given a skill reuses a helper command or shell library
  When  the skill specification is written
  Then  the helper inputs, outputs, exit codes, environment variables, external commands, and path rules are documented

# AC-006: Issue state schema is preserved
# Requirement: REQ-F-005, REQ-F-006
Scenario: Preserve Issue draft state
  Given an Issue skill creates, loads, selects, edits, branches, or pushes an Issue draft
  When  the workflow updates local state
  Then  the specification defines temp/idd/issues state paths, keys, value formats, update order, and recovery behavior

# AC-007: PR and commit state schema is preserved
# Requirement: REQ-F-005, REQ-F-006
Scenario: Preserve PR and commit draft state
  Given PR or commit-message skills operate on local drafts
  When  the workflow reads or writes a draft
  Then  the specification defines temp/idd/pr and temp/commit_message_current.md state contracts

# AC-008: Remote write is approved
# Requirement: REQ-F-007
Scenario: Confirm GitHub write
  Given an IDD skill is ready to call gh issue create, gh issue edit, or gh pr create
  When  the operation is about to execute
  Then  the user is shown the intended remote write and must approve before execution

# AC-009: Git mutation is approved
# Requirement: REQ-F-007
Scenario: Confirm Git mutation
  Given an IDD skill is ready to create a branch or commit staged changes
  When  the operation is about to execute
  Then  the user is shown the intended Git mutation and must approve before execution

# AC-010: Local state mutation is disclosed
# Requirement: REQ-F-007, REQ-F-008
Scenario: Disclose local state update
  Given an IDD skill will rename a draft, update a session file, or clean up a temporary file
  When  the operation is part of a workflow
  Then  the skill discloses the local state mutation rule and records recovery behavior for failures

# AC-011: Missing dependency is reported
# Requirement: REQ-F-009
Scenario: Report missing GitHub CLI
  Given a workflow requires gh
  When  gh is unavailable or unauthenticated
  Then  the skill reports the dependency or authentication failure without writing inconsistent local state

# AC-012: Classification is consistent
# Requirement: REQ-F-010
Scenario: Shared issue type classification
  Given Issue creation, Issue load, and branch workflow all require type classification
  When  each workflow classifies the same title and summary
  Then  each workflow receives the same commit_type, issue_type, branch_type, and reasoning contract

# AC-013: Plugin package includes skills
# Requirement: REQ-F-011
Scenario: Package converted skills
  Given skill artifacts exist under plugins/idd-framework/skills
  When  the plugin build or packaging process runs
  Then  the resulting plugin package includes the skills and shared adapter assets

# AC-014: Runtime paths do not assume .claude install layout
# Requirement: REQ-F-012
Scenario: Resolve helper library path
  Given a skill reuses a helper library from the plugin
  When  the skill resolves the helper path
  Then  it resolves from repository root and plugin root rather than assuming .claude/commands

# AC-015: Minor version is used for normative changes
# Requirement: REQ-F-013
Scenario: Apply minor version bump
  Given requirements.md is at version 1.1.0
  When  a revision changes skill topology or normative requirements
  Then  the document version becomes 1.2.0

# AC-016: Patch version is used for small changes
# Requirement: REQ-F-014
Scenario: Apply patch version bump
  Given requirements.md is at version 1.0.0
  When  a revision only fixes wording, formatting, typos, or non-normative clarification
  Then  the document version becomes 1.0.1
```

## 9. Open Questions

| Question | Type | Impact Area | Owner |
| -------- | ---- | ----------- | ----- |
| Which existing command tests become mandatory parity tests for each skill | Testing | Regression coverage | TBD |
| Should `validate-debug` discover project scripts dynamically or use a fixed phase-to-script mapping | Specification | Validation workflow | TBD |
| How should editor-based `edit` workflows behave when the runtime cannot open an external editor | UX | Issue/PR/commit edit | TBD |
| Should helper adapters be implemented as shell scripts, skill references, or both | Architecture | Shared adapter design | TBD |
| What exact manifest fields are required for publishing purpose-first nested skills in this plugin package | Packaging | Plugin release | TBD |

## 10. Traceability

| REQ ID | AC IDs | Type |
| ------ | ------ | ---- |
| REQ-F-001 | AC-001, AC-002 | Functional |
| REQ-F-001A | AC-001A | Functional |
| REQ-F-001B | AC-001B | Functional |
| REQ-F-001C | AC-001C | Functional |
| REQ-F-002 | AC-003 | Functional |
| REQ-F-003 | AC-004 | Functional |
| REQ-F-004 | AC-005 | Functional |
| REQ-F-005 | AC-006, AC-007 | Functional |
| REQ-F-006 | AC-006, AC-007 | Functional |
| REQ-F-007 | AC-008, AC-009, AC-010 | Functional |
| REQ-F-008 | AC-010 | Functional |
| REQ-F-009 | AC-011 | Functional |
| REQ-F-010 | AC-012 | Functional |
| REQ-F-011 | AC-013 | Functional |
| REQ-F-012 | AC-014 | Functional |
| REQ-F-013 | AC-015 | Functional |
| REQ-F-014 | AC-016 | Functional |
| REQ-NF-001 | N/A | Non-Functional |
| REQ-NF-002 | N/A | Non-Functional |
| REQ-NF-003 | N/A | Non-Functional |
| REQ-NF-004 | N/A | Non-Functional |
| REQ-NF-005 | N/A | Non-Functional |
| REQ-C-001 | N/A | Constraint |
| REQ-C-002 | N/A | Constraint |
| REQ-C-003 | N/A | Constraint |
| REQ-C-004 | N/A | Constraint |
| REQ-C-005 | N/A | Constraint |

## 11. Change History

| Date | Version | Description |
| ---- | ------- | ----------- |
| 2026-07-31 | 1.0.0 | Initial draft |
| 2026-07-31 | 1.1.0 | Applied risk review findings before specification |
| 2026-07-31 | 1.2.0 | Changed skill topology to nested command-taxonomy paths and added version history policy |
| 2026-07-31 | 1.3.0 | Reorganized skill invocation taxonomy into purpose-first top-level families |
