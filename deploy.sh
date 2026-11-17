#!/usr/bin/env bash
# 배포: 원격 연결 → push → GitHub Pages 활성화 → 접속 확인
set -u
REPO_NAME="${1:-family-dashboard}"
OWNER="mktina"
cd "$(dirname "$0")" || exit 1

echo "== 1) remote"
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/${OWNER}/${REPO_NAME}.git"
git push -u origin main 2>&1 | tail -5 || exit 1

echo "== 2) enable pages (main / root)"
gh api -X POST "repos/${OWNER}/${REPO_NAME}/pages" \
  -f 'source[branch]=main' -f 'source[path]=/' 2>&1 | head -5
gh api "repos/${OWNER}/${REPO_NAME}/pages" --jq '{html_url, status, branch: .source.branch, path: .source.path}' 2>&1

echo "== 3) poll url"
URL="https://${OWNER}.github.io/${REPO_NAME}/"
for i in $(seq 1 30); do
  CODE=$(curl -s -o /tmp/fd.html -w '%{http_code}' -L "$URL" 2>/dev/null)
  TITLE=$(grep -o '우리 가족 기록장' /tmp/fd.html 2>/dev/null | head -1)
  echo "try ${i}: http=${CODE} title='${TITLE}'"
  if [ "$CODE" = "200" ] && [ -n "$TITLE" ]; then
    echo "OK $URL"
    exit 0
  fi
  sleep 20
done
echo "TIMEOUT $URL"
exit 2
