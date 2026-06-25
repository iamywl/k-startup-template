#!/usr/bin/env bash
# k-startup-template 자율 실행 런처 — Codex CLI 무인 루프.
#
# 사용:
#   ./run.sh                      # 현 디렉터리 자율 진행(공고 PDF 자동 탐색)
#   ./run.sh 공고-청년창업.pdf      # 공고 PDF 를 출발 씨앗으로
#   ./run.sh "대학생 중고거래 SaaS" # 한 줄 아이템을 씨앗으로
#   MAX_ITERS=30 ./run.sh         # 반복 횟수 조정
#
# 동작: AGENTS.md 자율 루프를 게이트 모두 충족('DONE')까지 codex 무인 모드로 반복 호출(CODEX.md §1).
#   무인 플래그: --sandbox workspace-write --ask-for-approval never (구 --full-auto 는 deprecated).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

SEED="${1:-}"
MAX_ITERS="${MAX_ITERS:-20}"
LOG="${LOG:-.codex-run.log}"

if ! command -v codex >/dev/null 2>&1; then
  echo "[run.sh] codex CLI 가 PATH 에 없습니다. 설치 후 재시도: https://github.com/openai/codex" >&2
  exit 127
fi

PROMPT="AGENTS.md 와 .claude/agents 를 읽고 자율 루프(ASSESS→PLAN→EXECUTE→VERIFY→REPEAT)로 진행해라.
프로젝트(<project>/biz/)가 하나도 없으면 AGENTS.md §2.0 BOOTSTRAP 부터: 공고 PDF 를 찾아(pdftotext 로 추출) 메타를 뽑고, 프로젝트 디렉터리를 기획·생성한 뒤 제안서에 착수한다.
이미 산출물이 있어도 매 사이클 '처음 관점'에서 전면 재검토한다(증분 점검 금지).
작업은 방대하다(참고문헌 1,000+·차별점 50+·기능 100+) — 토큰을 아끼지 말고 깊게 일해라. 골격·스텁·요약으로 때우지 말고 실제 산출물을 끝까지 만든다.
게이트가 미달이면 턴을 끝내지 말고 컨텍스트가 소진될 때까지 EXECUTE→VERIFY 를 반복해라('나중에 계속' 금지).
게이트 ✅ 는 AGENTS.md §2.5 명령으로 실측한 수치가 있어야 한다(세지 않고 충족 표기 금지).
${SEED:+착수 씨앗(공고 PDF 경로 또는 한 줄 아이템): ${SEED}
}모든 게이트가 실측 충족일 때만 마지막 줄에 정확히 DONE 만 출력해라(미달이면 DONE 출력 금지)."

: > "$LOG"
for i in $(seq 1 "$MAX_ITERS"); do
  echo "[run.sh] ===== iteration ${i}/${MAX_ITERS} =====" | tee -a "$LOG"
  codex exec --sandbox workspace-write --ask-for-approval never --skip-git-repo-check "$PROMPT" 2>&1 | tee -a "$LOG"
  if tail -n 5 "$LOG" | grep -qx "DONE"; then
    echo "[run.sh] 모든 게이트 충족(DONE). 종료." | tee -a "$LOG"
    exit 0
  fi
done

echo "[run.sh] ${MAX_ITERS}회 반복 후에도 미완. ${LOG} 확인 후 재실행." | tee -a "$LOG"
exit 1
