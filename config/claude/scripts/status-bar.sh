#!/usr/bin/env bash
# Claude Code status bar. Pure bash + git: no jq/node needed, so it works on
# Windows (Git Bash), Linux and macOS.
#
# Output: Opus 5.5 │ ctx ▓▓▓░░░░░░░ 31% │ 5h 42% (resets 14:30) │ 7d 18% (resets Tue 09:00) │ spend 63% (resets Oct 01) │  master │ ~/Projects/dotfiles
# Claude Code pipes a JSON blob to stdin. Segments with missing data are skipped.

COLOR="blue"   # blue | orange | teal | green | lavender | rose | gold | slate | cyan | gray

case "$COLOR" in
    orange)   ACCENT=173 ;; blue)  ACCENT=74 ;; teal)  ACCENT=66 ;;
    green)    ACCENT=71  ;; lavender) ACCENT=139 ;; rose)     ACCENT=132 ;;
    gold)     ACCENT=136 ;; slate) ACCENT=60 ;; cyan)  ACCENT=37 ;;
    *)        ACCENT=245 ;;
esac
C_ACC=$'\033[38;5;'"${ACCENT}m"
C_DIM=$'\033[38;5;245m'
C_EMPTY=$'\033[38;5;238m'
C_RST=$'\033[0m'
SEP=" ${C_DIM}│${C_RST} "
BRANCH_ICON=$'\xee\x82\xa0'   # Nerd Font branch glyph (U+E0A0)

BS=$(awk 'BEGIN{printf "%c",92}'); SL=/
input=$(cat)
flat=${input//$'\n'/ }
flat=${flat//$'\r'/ }

# json_str <json> <key>  -> first string value of "key"
json_str() {
    local re="\"$2\"[[:space:]]*:[[:space:]]*\"((${BS}${BS}|[^\"${BS}])*)\""
    [[ $1 =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}
# json_num <json> <key>  -> first numeric value of "key"
json_num() {
    local re='"'"$2"'"[[:space:]]*:[[:space:]]*(-?[0-9]+([.][0-9]+)?)'
    [[ $1 =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}
# scope <json> <key> -> json from "key" onwards (so repeated keys resolve to the right block)
scope() {
    [[ $1 == *"\"$2\""* ]] && printf '%s' "${1#*\"$2\"}"
}
# round_int <number> -> nearest integer
round_int() {
    local n=${1%%.*} f=${1#*.}
    [[ $1 == *.* && ${f:0:1} -ge 5 ]] && n=$((n + 1))
    printf '%s' "${n:-0}"
}

segments=()

# --- model ---
model=$(json_str "$flat" display_name)
[[ -z $model ]] && model=$(json_str "$flat" id)
segments+=("${C_ACC}${model:-?}${C_RST}")

# --- context usage ---
ctx=$(json_num "$(scope "$flat" context_window)" used_percentage)
if [[ -n $ctx ]]; then
    pct=$(round_int "$ctx")
    (( pct > 100 )) && pct=100
    filled=$(( pct * 10 / 100 ))
    bar_on="" bar_off=""
    for ((i = 0; i < 10; i++)); do
        if (( i < filled )); then bar_on+="▓"; else bar_off+="░"; fi
    done
    segments+=("${C_DIM}ctx ${C_ACC}${bar_on}${C_EMPTY}${bar_off} ${C_ACC}${pct}%${C_RST}")
fi

# rate_seg <key> <label> <date_fmt> -> appends "label N% (resets <time>)" for a rate_limits window
rate_seg() {
    local win used resets t seg
    win=$(scope "$flat" "$1")
    win=${win%%\}*}   # windows have no nested objects: stop at the first }
    [[ -z $win ]] && return
    used=$(json_num "$win" used_percentage)
    [[ -z $used ]] && return
    seg="${C_DIM}$2 ${C_ACC}$(round_int "$used")%${C_RST}"
    resets=$(json_num "$win" resets_at)
    if [[ -n $resets ]]; then
        t=$(date -d "@${resets%%.*}" +"$3" 2>/dev/null || date -r "${resets%%.*}" +"$3" 2>/dev/null)
        [[ -n $t ]] && seg+=" ${C_DIM}(resets ${t})${C_RST}"
    fi
    segments+=("$seg")
}

# --- usage windows + reset times (each hidden when absent) ---
rate_seg five_hour   5h    %H:%M
rate_seg seven_day   7d    "%a %H:%M"
rate_seg spend_limit spend "%b %d"

# --- directory (needed for git too) ---
dir=$(json_str "$flat" current_dir)
[[ -z $dir ]] && dir=$(json_str "$flat" cwd)
dir=${dir//"$BS$BS"/$SL}   # JSON-escaped backslashes -> /
dir=${dir//"$BS"/$SL}

# --- git branch ---
if [[ -n $dir ]]; then
    gdir=$dir
    [[ -d $gdir ]] || { command -v cygpath >/dev/null 2>&1 && gdir=$(cygpath -u "$dir" 2>/dev/null); }
    if [[ -d $gdir ]]; then
        branch=$(git -C "$gdir" --no-optional-locks branch --show-current 2>/dev/null)
        [[ -z $branch ]] && branch=$(git -C "$gdir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
        [[ -n $branch ]] && segments+=("${C_ACC}${BRANCH_ICON} ${branch}${C_RST}")
    fi

    # Shorten the home directory to ~ (case-insensitive: Windows drive letters vary)
    shopt -s nocasematch
    for home in "${USERPROFILE//"$BS"/$SL}" "$HOME"; do
        [[ -z $home ]] && continue
        home=${home%/}
        if [[ $dir == "$home" ]]; then dir="~"; break
        elif [[ $dir == "$home"/* ]]; then dir="~${dir#"$home"}"; break
        fi
    done
    shopt -u nocasematch
    segments+=("${C_DIM}${dir}${C_RST}")
fi

# --- join ---
out=""
for s in "${segments[@]}"; do
    [[ -n $out ]] && out+="$SEP"
    out+="$s"
done
printf '%s\n' "$out"
