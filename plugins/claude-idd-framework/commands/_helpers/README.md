---
header:
  - src: README.md
  - "@(#)": IDD Helper Library Documentation Index
title: IDD Helper Libraries
description: Quick reference for IDD command helper functions
version: 0.5.0
created: 2025-10-15
authors:
  - atsushifx
changes:
  - 2025-10-15: Initial version
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

# IDD Helper Libraries

Quick reference documentation for IDD command helper functions.

## Overview

This directory contains concise documentation for bash helper functions used by IDD commands (`/idd-issue`, `/idd-pr`, `/idd-commit-message`). The actual implementations are in `.claude/commands/_libs/`.

## Available Libraries

### Environment Management

- **[_idd-env.md](_idd-env.md)**: Repository root detection, temp directory management
- Functions: `_setup_repo_env()`, `_get_temp_dir()`, `_ensure_dir()`

### File Operations

- **[_idd-file-ops.md](_idd-file-ops.md)**: File I/O, validation, editing
- Functions: `_require_file()`, `_extract_title()`, `_view_file()`, `_edit_file()`, `_get_file_timestamp()`

### Session Management

- **[_idd-session.md](_idd-session.md)**: Stateful workflow tracking
- Functions: `_save_last_file()`, `_load_last_file()`, `_save_session()`, `_load_session()`, `_has_session()`

### Git Operations

- **[_idd-git-ops.md](_idd-git-ops.md)**: GitHub CLI wrappers
- Functions: `_gh_issue_create()`, `_gh_issue_update()`, `_gh_pr_create()`, `_git_commit_with_message()`, `_extract_issue_number_from_url()`

### I/O Utilities

- **[_io-utils.md](_io-utils.md)**: Error output utilities
- Functions: `error_print()`

## Usage Pattern

### In Slash Commands

```bash
# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_libs/idd-env.lib.sh"
source "$SCRIPT_DIR/_libs/idd-git-ops.lib.sh"

# Use helper functions
_setup_repo_env
ISSUE_DIR=$(_get_temp_dir "idd/issues")
_ensure_dir "$ISSUE_DIR"

NEW_URL=$(_gh_issue_create "$TITLE" "$BODY_FILE")
```

### Dependency Chain

```
io-utils.lib.sh (base)
  ├── idd-env.lib.sh
  ├── idd-file-ops.lib.sh
  ├── idd-session.lib.sh
  └── idd-git-ops.lib.sh
```

All libraries except `io-utils.lib.sh` depend on `error_print()` for error handling.

## Design Principles

1. **Single Responsibility**: Each library handles one domain
2. **Error Handling**: Consistent error output via `error_print()`
3. **Cross-Platform**: Git Bash (Windows) and Unix-like systems
4. **Return Codes**: 0=success, 1=failure (consistent across all functions)
5. **Documentation**: JSDoc-style comments with `@param`, `@return`, `@example`

## Token Reduction Strategy

These helper libraries reduce token consumption by:

1. **Extraction**: 486 lines of inline helpers → 5 separate libraries
2. **Reference**: Commands reference helpers without full expansion
3. **Reusability**: Shared functions across multiple commands
4. **Documentation**: Concise markdown (20-30 lines each) for Claude reference

Expected token reduction: 75-80% for commands like `/idd-issue`.
