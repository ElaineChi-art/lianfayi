#!/bin/zsh
# 鏈法醫・期刊專題 平日自動發文（launchd 於 10:15 觸發；週末休息）
set -u
# 週六(6)日(7)不發文；手動指定 FORCE_DATE 時照跑
if [ -z "${FORCE_DATE:-}" ] && [ "$(date +%u)" -ge 6 ]; then exit 0; fi
REPO="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$REPO/logs/daily-$(date +%Y%m%d).log"
BIN=$(ls -d "$HOME"/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude 2>/dev/null | sort -V | tail -1)
{
  echo "=== $(date) 鏈上日報開始 ==="
  [ -z "$BIN" ] && { echo "找不到 claude 執行檔"; exit 1; }
  cd "$REPO" || exit 1
  # 剛喚醒時網路可能還沒連上：最多等 10 分鐘
  i=0
  until /usr/bin/curl -sm 5 -o /dev/null https://api.anthropic.com 2>/dev/null; do
    i=$((i+1))
    [ $i -ge 60 ] && { echo "網路 10 分鐘未就緒，放棄本次執行"; exit 1; }
    sleep 10
  done
  echo "網路就緒（等待 $((i*10)) 秒）"
  git pull -q origin main
  DATE="${FORCE_DATE:-$(date +%Y-%m-%d)}"
  PROMPT=$(sed "s/{{DATE}}/$DATE/g" "$REPO/scripts/daily-prompt.txt")
  "$BIN" -p "$PROMPT" \
      --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
      --max-turns 120
  # 若未產出（如 API 瞬斷），60 秒後重試一次
  if [ ! -f "$REPO/posts/daily/$DATE.html" ]; then
    echo "第一次執行未產出，60 秒後重試一次"
    sleep 60
    "$BIN" -p "$PROMPT" \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
        --max-turns 120
  fi
  # 轉 Word：drafts/DATE.md → 期刊日更Word（資料夾被搬走會自動尋找）
  OUT="$HOME/Desktop/📄 講座與文件/期刊日更Word"
  [ -d "$OUT" ] || OUT=$(find "$HOME/Desktop" -maxdepth 3 -type d -name "期刊日更Word" 2>/dev/null | head -1)
  [ -n "$OUT" ] || { OUT="$HOME/Desktop/期刊日更Word"; mkdir -p "$OUT"; }
  if [ "${MAKE_WORD:-0}" = "1" ] && [ -f "$REPO/drafts/$DATE.md" ]; then
    /opt/anaconda3/bin/pandoc "$REPO/drafts/$DATE.md" --from markdown+footnotes \
      -o "$OUT/$DATE-期刊專題.docx" && echo "Word 已輸出 → $OUT"
  fi
  echo "=== $(date) 結束（exit $?) ==="
} >> "$LOG" 2>&1
