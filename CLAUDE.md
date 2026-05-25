# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **CRITICAL NOTE**: All editing operations in this repository **MUST use MCP tools** (lsmcp, serena-mcp, codex-mcp) to minimize token consumption. **DO NOT use Read() + Edit() workflow** for documentation or code files. Use `get_symbols_overview()`, `search_for_pattern()`, and `replace_range()` instead. See "Mandatory MCP Usage for Documentation Editing" section below for detailed requirements. This rule is **NON-NEGOTIABLE** and must be followed for all file editing tasks.

## Repository Overview

**claude-idd-framework** is a comprehensive development framework for AI coding agents (Claude Code). It provides unified development standards, writing rules, custom slash commands, and custom agents to enhance AI-assisted development workflows.

This repository contains:

1. **Documentation**: Development standards, writing rules, and quality guidelines
2. **Custom Tools**: Slash commands and agents for Claude Code
3. **Shell Script Implementation**: Practical utilities developed using BDD methodology

The primary purpose is to establish consistent development practices across projects using Claude Code, with `scripts/xcp.sh` serving as a reference implementation of BDD-driven shell script development.

## Repository Structure

```bash
.claude/
├── commands/             # Custom slash commands for Claude Code
│   ├── idd-commit-message.md  # Generate Conventional Commits messages
│   ├── idd-issue.md           # Create structured GitHub Issues (main command)
│   ├── idd-pr.md              # Generate Pull Request drafts
│   ├── sdd.md                 # Spec-Driven Development workflow
│   ├── serena.md              # Serena MCP integration
│   ├── validate-debug.md      # 6-stage quality validation workflow
│   ├── idd/                   # IDD subcommands
│   │   └── issue/             # Issue management subcommands
│   │       ├── new.md         # Issue creation subcommand
│   │       ├── list.md        # Issue listing subcommand
│   │       ├── load.md        # GitHub Issue import
│   │       ├── edit.md        # Issue editing subcommand
│   │       ├── push.md        # GitHub push
│   │       └── branch.md      # Branch creation ✅ PRODUCTION READY (v1.6.0)
│   ├── _helpers/              # Helper command definitions
│   │   ├── _get-summary.md      # Title/summary validation & generation
│   │   ├── _edit-summary.md     # Interactive summary editing
│   │   ├── _get-issue-types.md  # AI-based type determination
│   │   └── _select-from-list.md # Interactive list selection
│   ├── _libs/                 # Shared shell libraries for commands
│   │   ├── filename-utils.lib.sh
│   │   ├── idd-env.lib.sh
│   │   ├── idd-file-ops.lib.sh
│   │   ├── idd-git-ops.lib.sh
│   │   ├── idd-session.lib.sh
│   │   ├── idd-subcommand-session.lib.sh
│   │   └── io-utils.lib.sh
│   └── __tests__/             # Tests for slash commands
│       ├── __helpers/         # Test helper functions
│       ├── unit/              # Unit tests
│       └── functional/        # Functional tests

└── agents/               # Custom agents for Claude Code
    ├── bdd-coder.md                # BDD implementation with strict Red-Green-Refactor
    ├── commit-message-generator.md # Conventional Commits message generation
    ├── issue-generator.md          # Structured GitHub Issue drafts
    └── pr-generator.md             # Pull Request draft generation

docs/
├── writing-rules/        # Writing guidelines (generic)
│   ├── 01-writing-rules.md           # Prohibited patterns & project-specific notation
│   ├── 02-frontmatter-guide.md       # Frontmatter metadata rules
│   ├── 03-document-template.md       # Document templates
│   ├── 04-custom-slash-commands.md   # Slash command authoring guide
│   └── 05-custom-agents.md           # Agent authoring guide

├── for-AI-dev-standards/ # AI development standards (project-specific)
│   ├── 01-setup-and-onboarding.md         # Environment setup & onboarding
│   ├── 02-core-principles.md              # Core principles & MCP mandatory rules
│   ├── 03-mcp-tools-usage.md              # MCP tools complete guide
│   ├── 04-code-navigation.md              # Project navigation & code search
│   ├── 05-bdd-workflow.md                 # BDD workflow & Red-Green-Refactor cycle
│   ├── 06-coding-conventions.md           # Coding conventions & MCP patterns
│   ├── 07-test-implementation.md          # Test implementation & BDD hierarchy
│   ├── 08-quality-assurance.md            # Quality gates & automated checks
│   ├── 09-document-quality-assurance.md   # Document quality criteria
│   ├── 10-templates-and-standards.md      # Source code templates & JSDoc rules
│   ├── 11-bdd-implementation-details.md   # atsushifx-style BDD implementation details
│   └── 12-shell-script-development.md     # Shell script BDD patterns

scripts/                  # Shell script implementations
├── xcp.sh                        # eXtended CoPy utility (main project) ✅ COMPLETE
├── libs/                         # Shared libraries
│   ├── logger.lib.sh            # Structured logging library (log_info, log_error, etc.)
│   └── io-utils.lib.sh          # I/O utilities (error_print) 🆕 NEW
├── merge-json.sh                # JSON merge utility 🆕 NEW (2025-10-14)
├── prepare-commit-msg.sh        # Git hook for commit message generation
├── setup-idd.sh                 # IDD framework setup script
├── __tests__/                   # shellspec test files (modular structure)
│   ├── unit/                    # Unit tests
│   │   ├── xcp-utils.spec.sh
│   │   ├── logger.lib.spec.sh
│   │   ├── io-utils.lib.spec.sh     # 🆕 NEW
│   │   ├── merge-json.unit.spec.sh  # 🆕 NEW
│   │   └── prepare-commit-msg-output.unit.spec.sh
│   ├── functional/              # Functional tests
│   │   ├── xcp-validation.functional.spec.sh
│   │   ├── xcp-backup.functional.spec.sh
│   │   └── xcp-copy-helpers.functional.spec.sh
│   ├── integration/             # Integration tests
│   │   ├── xcp-copy.integration.spec.sh
│   │   └── prepare-commit-msg-*.integration.spec.sh (3 files)
│   └── e2e/                     # E2E tests
│       ├── xcp-main.e2e.spec.sh
│       └── prepare-commit-msg-codex.e2e.spec.sh
└── specs/spec_helper.sh         # shellspec test helpers

configs/                  # Configuration files (reference only)
```

## Essential Commands

### Git Hooks Setup

```bash
# Install lefthook hooks (required after initial clone)
pnpm run prepare
```

### Git Hooks

This repository uses **lefthook** for Git hooks:

- **pre-commit**: Runs gitleaks to prevent committing secrets
- **prepare-commit-msg**: Auto-generates commit message suggestions via `scripts/prepare-commit-msg.sh`
- **commit-msg**: Validates commit messages with commitlint (Conventional Commits format)

## Key Development Practices

### 1. MCP Tools are Mandatory

**ALL development tasks MUST use MCP tools (lsmcp, serena-mcp, codex-mcp) for:**

- Understanding project structure and existing code patterns
- Searching symbols, files, and patterns
- Analyzing impact of changes before implementation
- Verifying code integrity after changes
- **Token-efficient code navigation and editing**

Before editing ANY file, use MCP tools to understand existing patterns and conventions.

#### Token Reduction Best Practices

MCP tools enable significant token savings through targeted operations:

**Avoid Full File Reads**

- Use `get_symbols_overview` instead of reading entire files
- Use `find_symbol` with `include_body=true` for specific symbols only
- Use `search_for_pattern` with context lines instead of grepping full files

**Progressive Information Gathering**

1. Start with high-level overview (`list_dir`, `get_project_overview`)
2. Narrow down with symbol search (`search_symbols`, `find_symbol`)
3. Read specific symbols only when necessary (`get_symbol_details`)

**Symbol-Based Editing**

- Use `replace_symbol_body` instead of Read + Edit workflow
- Use `insert_after_symbol` / `insert_before_symbol` for targeted insertions
- Use `replace_range` or `replace_regex` for precise edits

**Delegate Complex Tasks**

- Use `codex-mcp` for multi-step workflows that would consume many tokens
- Offload exploration and analysis tasks to specialized agents
- Let Codex handle iterative refinement processes

**Example Workflow**

```bash
# BAD: Token-heavy approach
Read entire_file.sh              # 500 lines × tokens
Edit entire_file.sh              # Full file content again

# GOOD: Token-efficient approach
get_symbols_overview(entire_file.sh)  # Only symbol list
find_symbol("target_function")        # Only the function body
replace_symbol_body("target_function", new_body)  # Direct replacement
```

#### Mandatory MCP Usage for Documentation Editing

**CRITICAL RULE**: When editing documentation files (`.md` files in `.claude/commands/`, `docs/`, etc.), you **MUST** use MCP tools instead of Read/Edit:

**Required workflow:**

1. **Use `get_symbols_overview()`** or **`search_for_pattern()`** instead of `Read()` for initial inspection
2. **Use `replace_range()`** or **serena-mcp editing tools** instead of `Read() + Edit()` workflow
3. **Only use `Read()` as a last resort** when MCP tools cannot provide the needed information

**Why this matters:**

- Documentation files are often 200-400 lines
- `Read() + Edit()` consumes 2× tokens for the same content
- MCP tools provide targeted access with 70-80% token reduction

**Example:**

```bash
# ❌ BAD: Token-heavy approach (do NOT do this)
Read .claude/commands/idd/issue/list.md  # 327 lines, ~8000 tokens
Edit .claude/commands/idd/issue/list.md  # Full file content again, ~8000 tokens
# Total: ~16000 tokens

# ✅ GOOD: Token-efficient approach (do this instead)
get_symbols_overview(.claude/commands/idd/issue/list.md)  # Structure only, ~200 tokens
search_for_pattern("subcommand_session", paths_include_glob="**/*.md", output_mode="content")  # ~500 tokens
replace_range(.claude/commands/idd/issue/list.md, start_line=52, end_line=145, new_content="...")  # ~1000 tokens
# Total: ~1700 tokens (89% reduction)
```

This rule ensures maximum token efficiency and faster response times. Violation of this rule will result in unnecessary token consumption and slower performance.

### 2. Documentation Standards

#### Writing Rules (Critical)

- **NEVER** use bullet points with bold emphasis (`- **Item**: description`)
  - Use headings instead (`### Item`)
- **Parentheses**: Always use half-width `()` not full-width `()`
- **No excessive decoration**: Avoid emojis, exclamation marks (except README.md overview)
- **No verbose preambles**: Avoid phrases like "以下に説明します" (explained below)
- **Objective tone**: Technical writing should be factual, not subjective

#### Frontmatter Requirements

All Markdown files must include YAML frontmatter with:

```yaml
---
header:
  - src: [filename]
  - @(#): [brief description]
title: claude-idd-framework
description: [document purpose]
version: 1.0.0
created: YYYY-MM-DD
authors:
  - atsushifx
changes:
  - YYYY-MM-DD: [change description]
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

#### Document Quality Checklist

Before completing any documentation work, verify:

1. **Heading hierarchy**: h1 → h2 → h3 (no skipping levels)
2. **Sentence quality**: Clear, concise, appropriate length
3. **Markdown syntax**: Code blocks have language tags, consistent list formatting
4. **Frontmatter**: All required fields present and properly formatted
5. **Project-specific rules**: Half-width parentheses, unified technical terms, proper link format

### 3. Custom Tools Workflow

#### Custom Slash Commands

Use these commands directly in Claude Code:

- `/idd-commit-message`: Generate Conventional Commits messages from staged changes
- `/idd-issue`: Create structured GitHub Issues (main command, deprecated - use subcommands below)
- `/idd:issue:new`: Create new issue drafts with AI-generated summary
- `/idd:issue:list`: List and select issue drafts interactively
- `/idd:issue:load`: Import GitHub Issues to local drafts
- `/idd:issue:edit`: Edit issue drafts interactively
- `/idd:issue:push`: Push issue drafts to GitHub
- `/idd:issue:branch [new|commit] [options]`: Create Git branches from issues (two-stage workflow: propose → create) ✅ PRODUCTION READY
- `/idd-pr`: Generate Pull Request drafts from branch changes
- `/sdd [init|req|spec|tasks|coding|commit]`: Spec-Driven Development workflow
- `/validate-debug`: Run 6-stage comprehensive quality validation

#### Custom Agents

Launch these agents via the Task tool for specialized workflows:

- `bdd-coder`: Strict BDD implementation (Red-Green-Refactor, 1 message = 1 test)
- `commit-message-generator`: Conventional Commits message generation
- `issue-generator`: Structured GitHub Issue draft creation
- `pr-generator`: Pull Request draft generation

### 4. Complete IDD Issue Management Workflow

The IDD Issue management system provides a complete workflow from issue creation to branch implementation:

**All commands are production-ready (2025-10-27):**

1. **Create or Import Issue**
   - `/idd:issue:new`: Create new issue with AI-generated summary and type detection
   - `/idd:issue:load [number]`: Import existing GitHub Issue to local draft

2. **Manage Issues**
   - `/idd:issue:list`: List and select issue drafts interactively
   - `/idd:issue:edit`: Edit selected issue with interactive codex-mcp assistance

3. **Push to GitHub**
   - `/idd:issue:push`: Push issue draft to GitHub (creates new or updates existing)

4. **Create Branch**
   - `/idd:issue:branch new`: Generate branch proposal with intelligent domain detection
   - `/idd:issue:branch new --domain [domain]`: Override domain detection
   - `/idd:issue:branch new --base [branch]`: Specify base branch (default: main/master)
   - `/idd:issue:branch commit`: Create and switch to proposed branch

**Example workflow:**

```bash
# Step 1: Create issue
/idd:issue:new
# → Creates: temp/idd/issues/new-20251027-120000-feature-user-login.md

# Step 2: Edit content (optional)
/idd:issue:edit
# → Interactive editing with codex-mcp

# Step 3: Push to GitHub
/idd:issue:push
# → Creates Issue #42, renames to: 42-20251027-120000-feature-user-login.md

# Step 4: Generate branch proposal
/idd:issue:branch new
# → Detects domain from title: "auth"
# → Suggests: feat-42/auth/user-login

# Step 5: Create branch
/idd:issue:branch commit
# → Creates and switches to: feat-42/auth/user-login
# → Ready for implementation
```

**Key Features:**

- **Session Management**: Seamless state tracking across commands (.last.session, .branch.session)
- **AI Integration**: Codex-MCP for summary generation, domain detection, type determination
- **Branch Intelligence**: Automatic domain detection from title [brackets] or content analysis
- **Flexible Options**: Override domain, specify base branch, handle edge cases
- **Production Ready**: Full test coverage (31 examples, 100% passing), comprehensive documentation

### 5. BDD Development (if applicable to future code)

If implementing code in this repository, follow **atsushifx-style BDD**:

**Mandatory principles:**

- **1 message = 1 test**: Never implement multiple tests in a single iteration
- **3-layer BDD structure**: Given/Feature → When → Then
- **RED-GREEN-REFACTOR**: Must verify RED before GREEN, GREEN before REFACTOR

**BDD hierarchy:**

```typescript
describe('Given: prerequisite/Feature', () => {
  describe('When: action/condition', () => {
    it('Then: [tag] - expected result', () => {
      // Arrange (Given details)
      // Act (When details)
      // Assert (Then details)
    });
  });
});
```

**Required tags for Then clauses:**

- `[正常]`: Normal/success cases
- `[異常]`: Error/exception cases
- `[エッジケース]`: Edge cases/boundary values

### 6. Onboarding Process

When starting work in this repository:

```bash
# 1. Update MCP tool memory with current codebase
"lsmcp のメモリを、現在のコードベース/ドキュメントを読んで更新して"
"serena-mcp のメモリを、現在のコードベース/ドキュメントを読んで更新して"

# 2. Read core documentation
Read docs/writing-rules/01-writing-rules.md
Read docs/for-AI-dev-standards/README.md
Read docs/for-AI-dev-standards/02-core-principles.md

# 3. Verify available custom tools
/help
```

## Architecture Highlights

### Documentation-Centric Design

Unlike typical code repositories, this project's "implementation" consists of:

- **Writing Rules** (`docs/writing-rules/`): Generic documentation guidelines applicable across projects
- **AI Dev Standards** (`docs/for-AI-dev-standards/`): AI-specific development standards, MCP tool usage patterns, BDD workflows
- **Custom Tools** (`.claude/`): Reusable slash commands and agents that extend Claude Code capabilities

### MCP Tool Integration

This framework assumes and requires MCP (Model Context Protocol) tools:

- **lsmcp**: Language Server MCP for symbol search, LSP operations, code navigation
- **serena-mcp**: Structured code analysis, symbol indexing, pattern search
- **codex-mcp**: Autonomous coding agent for complex multi-step workflows

All development workflows are designed around MCP tool usage for understanding existing code before making changes. Use codex-mcp to delegate token-intensive tasks that require multiple iterations or extensive exploration.

### Quality-First Approach

Multiple layers of quality assurance:

1. **Git hooks**: Pre-commit secret scanning, commit message validation
2. **Document quality gates**: Manual checklists in `09-document-quality-assurance.md`
3. **Validation workflows**: `/validate-debug` command for comprehensive checks

## Important Constraints

### Tool Independence

- Documentation must remain tool-agnostic where possible
- Avoid hardcoding specific IDE or editor features
- MCP tools are the exception (explicitly required for AI development)

### File Editing Restrictions

- **DO NOT EDIT**: Generated outputs, cache directories, dependency folders
- **EDIT FREELY**: Documentation in `docs/`, custom tools in `.claude/`, configuration in `configs/`

### Commit Message Format

All commits must follow Conventional Commits:

```
type(scope): subject

body

footer
```

Use `/idd-commit-message` or the `commit-message-generator` agent to generate compliant messages.

## Common Workflows

### Creating New Documentation

1. Read `docs/writing-rules/01-writing-rules.md` for prohibited patterns
2. Use `docs/writing-rules/03-document-template.md` as template
3. Follow frontmatter guide in `docs/writing-rules/02-frontmatter-guide.md`
4. Verify against quality checklist in `docs/for-AI-dev-standards/09-document-quality-assurance.md`

### Creating Custom Slash Commands

1. Read `docs/writing-rules/04-custom-slash-commands.md` for authoring rules
2. Create file in `.claude/commands/[name].md`
3. Include proper frontmatter with `allowed-tools`, `argument-hint`, `description`
4. Implement as Python snippet (standard library only)

### Creating Custom Agents

1. Read `docs/writing-rules/05-custom-agents.md` for authoring rules
2. Create file in `.claude/agents/[name].md`
3. Include frontmatter with `name`, `description`, `tools`, `model: inherit`
4. Structure: Agent Overview → Activation Conditions → Core Functionality → Integration Guidelines

### Shell Script Development with BDD

For developing shell scripts (like `xcp.sh`), use the **SDD (Spec-Driven Development) workflow**:

#### Initial Setup

```bash
# 1. Initialize SDD session
/sdd init [namespace]/[module]
# Example: /sdd init scripts/xcp

# 2. Create requirements document
/sdd req
# Write functional requirements in docs/.cc-sdd/[namespace]/[module]/requirements/

# 3. Create specifications
/sdd spec
# Generate detailed specifications from requirements

# 4. Break down into tasks
/sdd tasks
# Generate task breakdown (T1-T10) with BDD verification items
```

#### Implementation Cycle

```bash
# 5. Implement code following BDD
/sdd coding [task-id]
# Example: /sdd coding T7-1
# Follows strict Red-Green-Refactor:
# - Write one failing test (RED)
# - Implement minimal code to pass (GREEN)
# - Refactor while keeping tests green (REFACTOR)

# 6. Commit completed work
/sdd commit
# Generates Conventional Commits message from changes
```

#### Key Principles

- **Test-first**: Write shellspec tests before implementation
- **BDD hierarchy**: Given/When/Then structure with tags ([正常], [異常], [エッジケース])
- **Logger integration**: Use `scripts/libs/logger.lib.sh` for consistent logging
- **Quality gates**: Run `shellcheck` and `shellspec` before committing
- **MCP tools**: Use serena-mcp/lsmcp to understand existing code patterns

#### Reference Implementations

**xcp.sh** (eXtended CoPy utility)

- **Status**: ✅ **100% COMPLETE - PRODUCTION READY** (T1-T10 all implemented and tested)
- **Test Coverage**: 148 examples, 148 passing (100% success rate), 0 failures, 6 skipped (Windows)
- **Implementation**: 662 lines (main script), 1687 lines (tests), 20+ functions
- **Test/Code Ratio**: 2.5:1 (comprehensive coverage)
- **Latest Updates (2025-10-12)**:
  - Simplified helper functions, removed wrapper-only helpers
  - Stabilized copy logic with improved error handling
  - Expanded modular tests with better organization
  - Relocated shellspec tests for clarity
- **Core Features**:
  - Multiple operation modes (skip, overwrite, update, backup)
  - Dry-run mode for safe testing
  - Recursive directory copying with symlink handling (find-based two-phase approach)
  - Error tracking and fail-fast mode
  - Comprehensive logging (quiet/verbose modes)
  - Full CLI argument parsing with help/version support
- **Architecture**:
  - Modular design with clear separation of concerns
  - Read-only validation functions separated from side-effect functions
  - Mode-driven flexible behavior control
  - Early error return pattern throughout
- **Production Ready**: Fully documented with shdoc headers, shellcheck clean, ready for deployment

**merge-json.sh** (JSON merge utility) - 🆕 NEW (2025-10-14)

- **Status**: Recently implemented, following BDD principles
- **Implementation**: 213 lines
- **Purpose**: Merge two JSON configuration files with shallow merge strategy
- **Core Features**:
  - Shallow merge (top-level keys only)
  - Last-wins strategy for key conflicts
  - Array concatenation (file1 + file2)
  - Nested objects replaced entirely (no deep merge)
  - jq dependency checking with error_print
- **Exit codes**: 0 (success), 1 (invalid args), 2 (file not found), 3 (JSON parse error), 4 (not object), 5 (write error)
- **Use case**: Merging MCP configuration files
- **Integration**: Uses `logger.lib.sh` error_print for error messages
- **Test Coverage**: Unit tests in `merge-json.unit.spec.sh`

**logger.lib.sh** (Structured logging library)

- **Lines**: 201 lines
- **Purpose**: Structured logging with timestamps, error tracking, and flag control
- **Features**: Multiple log levels (INFO, VERBOSE, ERROR, DRY-RUN), error counting/retrieval, quiet/verbose modes
- **Usage**: xcp.sh for comprehensive logging needs

**io-utils.lib.sh** (I/O utilities library) - 🆕 NEW (2025-10-14)

- **Lines**: 61 lines
- **Purpose**: Lightweight I/O utilities without logging overhead
- **Function**: `error_print()` - Simple stderr output utility (supports heredoc and arguments)
- **Design**: Responsibility separation - simple I/O vs structured logging
- **Usage**: merge-json.sh, prepare-commit-msg.sh for basic error messages

## Troubleshooting

### MCP Tool Errors

```bash
# Verify project root path
"プロジェクトルートのパスを確認して"

# Rebuild symbol index
"lsmcp でシンボルインデックスを再構築して"

# Re-run onboarding
"serena-mcp でオンボーディングを再実行して"
```

### Documentation Quality Issues

1. Read `docs/for-AI-dev-standards/09-document-quality-assurance.md` for quality criteria
2. Read `docs/writing-rules/01-writing-rules.md` for prohibited patterns
3. Manually verify checklist items in quality assurance doc

### Custom Tool Errors

```bash
# Check command help
/[command-name] help

# Read command documentation
Read .claude/commands/[command-name].md
Read .claude/agents/[agent-name].md

# Verify frontmatter configuration
# Check allowed-tools, argument-hint, etc.
```

## See Also

- **README.md**: Basic repository overview
- **docs/for-AI-dev-standards/README.md**: AI development standards index
- **docs/writing-rules/README.md**: Writing guidelines index
- **CONTRIBUTING.md**: Contribution guidelines
