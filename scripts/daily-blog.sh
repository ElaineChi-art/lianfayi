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
  DATE="${FORCE_DATE:-$(date +%Y-%m-%d)}"
  PROMPT=$(sed "s/{{DATE}}/$DATE/g" "$REPO/scripts/daily-prompt.txt")
  "$BIN" -p "$PROMPT" \
      --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
      --max-turns 80
  # 轉 Word：drafts/DATE.md → 桌面「期刊日更Word」
  if [ -f "$REPO/drafts/$DATE.md" ]; then
    /opt/anaconda3/bin/pandoc "$REPO/drafts/$DATE.md" --from markdown+footnotes \
      -o "$HOME/Desktop/期刊日更Word/$DATE-期刊專題.docx" && echo "Word 已輸出"
  fi
  echo "=== $(date) 結束（exit $?) ==="
} >> "$LOG" 2>&1
