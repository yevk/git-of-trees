# Git of Trees (GoT)

GoT is an opinionated Git Worktrees tool.

## Prerequisites
- zsh
- https://github.com/BurntSushi/ripgrep
- https://github.com/junegunn/fzf
- https://github.com/charmbracelet/gum

## Installation

1. Clone the repo or download `got.zsh`
2. Source `got.zsh` from your `.zshrc`

## Usage

### `got clone`

Clone and prepare a repository for working with worktrees.

### `got add`

Add a new worktree.

Worktrees can be based off `master` or another branch.

Use inside a worktree enabled repository.

### `got del`

Delete an existing worktree and the associated branch.

Use inside a worktree enabled repository.

### `got list`

List existing worktrees.

### `got cd`

Change to another worktree directory.
