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

Clones and prepares a repository for working with worktrees.

The repository is cloned as "bare repository" and a worktree is automatically created for the "master" branch.

### `got add`

Adds a new worktree.

### `got del`

Delete an existing worktree and the associated branch.

Use inside a worktree enabled repository.

### `got list`

List existing worktrees.

### `got cd`

Change to another worktree directory.
