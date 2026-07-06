#!/bin/bash
# Claude Code status line
# Left: model display name
# Right: context usage bar + %, and 5h rate limit usage bar + %

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')

used_ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Colors (dim, since the status line is rendered with dimmed colors)
DIM=$'\033[2m'
RESET=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'

# Pick a color based on usage percentage
bar_color() {
  local pct_int="$1"
  if [ "$pct_int" -ge 80 ]; then
    echo "$RED"
  elif [ "$pct_int" -ge 50 ]; then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

# Build a colored block progress bar, e.g. [####------]
make_bar() {
  local pct="$1"
  local width=10
  local pct_int
  pct_int=$(printf '%.0f' "$pct")
  local filled=$(( pct_int * width / 100 ))
  [ "$filled" -lt 0 ] && filled=0
  [ "$filled" -gt "$width" ] && filled=$width
  local empty=$(( width - filled ))
  local color
  color=$(bar_color "$pct_int")
  local bar=""
  local i
  for ((i = 0; i < filled; i++)); do bar="${bar}#"; done
  for ((i = 0; i < empty; i++)); do bar="${bar}-"; done
  printf "${DIM}[${color}%s${RESET}${DIM}]${RESET}" "$bar"
}

# Strip ANSI escape codes to measure visible length
visible_len() {
  local s="$1"
  s=$(printf '%b' "$s" | sed 's/\x1b\[[0-9;]*m//g')
  echo "${#s}"
}

right=""

if [ -n "$used_ctx" ]; then
  ctx_int=$(printf '%.0f' "$used_ctx")
  ctx_bar=$(make_bar "$used_ctx")
  right="Ctx ${ctx_bar} ${ctx_int}%"
fi

if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  five_bar=$(make_bar "$five_pct")
  [ -n "$right" ] && right="${right}  "
  right="${right}5h ${five_bar} ${five_int}%"
fi

left=$(printf "${DIM}${CYAN}%s${RESET}" "$model")

cols=$(tput cols 2>/dev/null)
[ -z "$cols" ] && cols=80

if [ -n "$right" ]; then
  left_len=$(visible_len "$left")
  right_len=$(visible_len "$right")
  pad=$(( cols - left_len - right_len ))
  [ "$pad" -lt 1 ] && pad=1
  printf "%s%*s%s\n" "$left" "$pad" "" "$right"
else
  printf "%s\n" "$left"
fi
