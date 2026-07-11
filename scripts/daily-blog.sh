#!/bin/zsh
# 鏈法醫・鏈上日報 每日自動發文（launchd 於每天 10:15 觸發）
set -u
REPO="$HOME/Desktop/lianfayi"
LOG="$REPO/logs/daily-$(date +%Y%m%d).log"
BIN=$(ls -d "$HOME"/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude 2>/dev/null | sort -V | tail -1)
{
  echo "=== $(date) 鏈上日報開始 ==="
  [ -z "$BIN" ] && { echo "找不到 claude 執行檔"; exit 1; }
  cd "$REPO" || exit 1
  git pull -q origin main
  "$BIN" -p "$(cat "$REPO/scripts/daily-prompt.txt")" \
      --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
      --max-turns 60
  echo "=== $(date) 結束（exit $?) ==="
} >> "$LOG" 2>&1
