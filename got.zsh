#!/usr/bin/env zsh

## styles
ERROR_COLOR=#f7768e
ERROR_MARGIN='1 0'

## gum config
export GUM_INPUT_SHOW_HELP=false

export GUM_CONFIRM_SHOW_HELP=false
export GUM_CONFIRM_PROMPT_FOREGROUND=#7dcfff
export GUM_CONFIRM_SELECTED_BACKGROUND=#385f0d
export GUM_CONFIRM_UNSELECTED_BACKGROUND=#343B58

export FOREGROUND=#a9b1d6
export BORDER_FOREGROUND=#565f89

# command: got clone
#
# Clone and configure a bare repository for worktrees workflow.
__got_clone() {
  local repo=$(
    gum input --prompt "repo: " |
    # provide good UX by accepting URL prepended by "git clone" (e.g. from Bitbucket)
    rg -o "(git clone )?(.+)" -r '$2'
  )

  if [[ -z $repo ]]; then
    __got_print_error "ERROR: repository URL is required"
    return
  fi

  local basename=${repo##*/}
  local default_dir=${basename%.*}

  local dir=$(gum input --prompt "dir: " --value $default_dir)
  dir=${dir:-$default_dir}

  ###

  # use subshell so `set -e` doesn't exit the user's shell on error
  ( set -e
    mkdir "$dir"
    cd "$dir"

    git clone --bare "$repo" .bare
    echo "gitdir: ./.bare" >.git

    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch origin

    # TODO: dynamically get the repo's default branch name
    git worktree add master master

    ###

    __got_print_info "Repo is ready!" \
        "You are now inside the repository root directory." \
        "To add your first worktree, run: got add"
  )

  # must cd into the repo dir again because `cd` inside the subshell does not
  # persist to the user's shell; but only do that if there wasn't an error
  if [[ $? -eq 0 ]]; then 
    cd "$dir"
  else
    __got_print_error "ERROR: Clone failed. You may need to manually remove '$dir'"
  fi
}

# command: got add
#
# Add a new worktree from a base commit-ish.
__got_add() {
  local name=
  local options=()

  while [[ -z $name ]]; do
    name=$(gum input --prompt "name: ")
  done

  local base="origin/master"

  if ! gum confirm "Use master as base?" --default="Yes"; then
    local selected=$(git --no-pager branch -vv -r | fzf --height=20% --reverse --info=inline | cut -d' ' -f3)
    base=${selected:-$base}
  fi

  # -b and --detach are mutually exclusive
  if gum confirm "Detach HEAD?" --default="No"; then
    options+=--detach
  else
    options+=(--no-track -b $name)
  fi

  ###

  local git_dir="$(git rev-parse --git-dir)"
  local root_dir="${git_dir%%/.bare*}"

  ( set -e
    cd $root_dir
    gum spin --title "Fetching..." --spinner points --show-error -- git fetch --prune
    git worktree add ${options[@]} $name $base

    ###

    __got_print_info "Worktree is ready!" \
      "You are now inside the worktree directory."
  )

  [[ $? -eq 0 ]] && cd $root_dir/$name
}

# command: got del
#
# Delete a worktree and its branch 
__got_del() {
  # create an array from the result because need both the worktree and the branch
  local selection=(
    $(git worktree list |
      rg -v "(bare)" | # don't want "bare" to be deleted
      rg -v "\[$(git branch --show-current)\]" | # don't show current branch - can't delete while in the worktree
      fzf --height=20% --reverse --info=inline --multi --bind 'enter:accept-non-empty' | # don't want empty selection
      rg -o "(.*?)\s.*\[(.*?)\]" -r '$1 $2' # format to create an array
    )
  )

  if [[ ${#selection[@]} -eq 0 ]]; then
    return
  fi

  local tree=${selection[1]}
  local branch=${selection[2]}

  echo Deleting...

  ( set -e
    git worktree remove $tree > /dev/null
    git branch -D $branch > /dev/null
  )

  __got_print_info "Worktree $(basename "$tree") deleted!" \
      "The corresponding branch "$branch" was deleted as well."
}

# command: got list
#
# List worktrees
__got_list() {
  git worktree list | rg -v "(bare)" # don't want "bare" to be listed
}

# command: got cd
#
# Select and cd to worktree dir
__got_cd() {
  local tree=$(
    git worktree list |
      rg -v "(bare)"  |# don't want "bare" as an option
      rg -v "\[$(git branch --show-current)\]" | # don't show current branch - can't delete while in the worktree
      fzf --height=20% --reverse --info=inline --multi --bind 'enter:accept-non-empty' | # don't want empty selection
      rg -o "(.*?)\s.*" -r '$1'
  )

  if [[ -z "$tree" ]]; then
    return
  fi

  cd $tree
}

__got_print_usage() {
  echo "Usage: got <command>"
  echo
  echo "Commands:"
  echo "  clone     Clone a repository"
  echo "  add       Add worktree"
  echo "  del       Delete worktree"
  echo "  list      List worktress"
  echo "  cd        Change directory to workree (see Extras below)"
  echo
  echo
  echo "Extras:"
  echo "  To make the "cd" command work, follow the instructions in README.md"
  echo
}

__got_check_deps() {
  if ! command -v rg > /dev/null; then
    echo "Git of Trees (got) init error: Missing dependency. Please install ripgrep (https://github.com/BurntSushi/ripgrep)"
  fi

  if ! command -v fzf > /dev/null; then
    echo "Git of Trees (got) init error: Missing dependency. Please install fzf (https://github.com/junegunn/fzf)"
  fi

  if ! command -v gum > /dev/null; then
    echo "Git of Trees (got) init error: Missing dependency. Please install gum (https://github.com/charmbracelet/gum)"
  fi
}

__got_print_error() {
  local message=$1

  gum style $message --foreground $ERROR_COLOR --margin $ERROR_MARGIN --bold
}

# Print information to user with nice style
#
# Params:
#   - title
#   - ...content text
__got_print_info() {
  local title=$(gum style $1 --foreground '#ff9e64' --bold)
  shift

  local content=$( gum style $@ )
  local full=$(gum join "$title" "$content" --vertical)

  gum style "$full" --border double --margin '1 2' --padding '0 2'
}

### MAIN ###

# want this check to run when the file is sourced to avoid having to run these checks
# on every command.
__got_check_deps

# main function used by users
got() {
  readonly command=$1
  if [[ -z $command ]] || [[ ${#[@]} -eq 0 ]]; then
    __got_print_usage
    return
  fi

  shift
  case $command in
    "clone")
      __got_clone $@
      ;;
    "add")
      __got_add $@
      ;;
    "del")
      __got_del $@
      ;;
    "list")
      __got_list $@
      ;;
    "cd")
      __got_cd $@
      ;;
    *)
      echo "Unknown command $command"
      echo
      __got_print_usage
      ;;
  esac
}
