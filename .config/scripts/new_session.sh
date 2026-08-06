#!/usr/bin/env zsh

new_session() {
  local input="$1"

  if [[ -z "$input" ]]; then
    echo "Usage: new_session <something/something_else>" >&2
    return 1
  fi

  local first_part="${input%%/*}"
  local second_part="${input#*/}"

  if [[ "$first_part" == "$second_part" || -z "$first_part" || -z "$second_part" ]]; then
    echo "ERROR: Input must be in format 'something/something_else'" >&2
    return 1
  fi

  local session_name="$second_part"
  local sentinel_dir="$HOME/deepkeep-repo/sentinel"
  local main_dir="$sentinel_dir/deepkeep-sentinel-main"

  # 1. Pull main branch -- abort on any failure
  echo "Pulling main branch in $main_dir ..."
  if ! git -C "$main_dir" pull; then
    echo "ERROR: git pull failed on main branch. Aborting." >&2
    return 1
  fi

  # 2. Create branch (must run from sentinel dir)
  echo "Creating branch ron/$input ..."
  if ! (cd "$sentinel_dir" && create_branch "$input"); then
    echo "ERROR: create_branch failed. Aborting." >&2
    return 1
  fi

  # Worktree folder name matches create_branch logic: slashes become underscores
  local wt_folder="${input//\//_}"
  local branch_dir="$sentinel_dir/$wt_folder"

  # Packages subdir: replace hyphens with slashes in the first part
  local pkg_subdir
  pkg_subdir="$(echo "$first_part" | tr '-' '/')"
  local pkg_dir="$branch_dir/packages/$pkg_subdir"

  echo "Creating tmux session '$session_name' ..."

  # Window 1: lazygit in the worktree root
  tmux new-session -d -s "$session_name" -c "$branch_dir"
  tmux send-keys -t "$session_name" "lazygit" C-m

  # Window 2: make setup install in the package dir
  tmux new-window -t "$session_name" -c "$pkg_dir"
  tmux send-keys -t "$session_name" "make setup install" C-m

  # Window 3: wait for venv, source it, open vim
  tmux new-window -t "$session_name" -c "$pkg_dir"
  tmux send-keys -t "$session_name" \
    "while [ ! -f .venv/bin/activate ]; do sleep 1; done && source .venv/bin/activate && vim" C-m

  # Window 4: wait for venv, source it, run tcode
  tmux new-window -t "$session_name" -c "$pkg_dir"
  tmux send-keys -t "$session_name" \
    "while [ ! -f .venv/bin/activate ]; do sleep 1; done && source .venv/bin/activate && tcode" C-m

  # Attach or switch to session
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}
