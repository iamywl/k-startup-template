# CODEX.md — Codex CLI 로 자율 실행하기 (+ MCP)

> 이 키트를 **OpenAI Codex CLI** 로 무인 실행/병렬 실행하는 방법과, **MCP 서버**로 도구를 강화하는 법.
> 규칙은 [`CLAUDE.md`](CLAUDE.md), 자율 루프는 [`AGENTS.md`](AGENTS.md). Codex 는 작업 디렉터리의 `AGENTS.md` 를 자동으로 컨텍스트에 싣는다.
>
> ⚠️ Codex CLI 플래그·설정은 버전마다 다를 수 있다. 실제 값은 `codex --help`, `codex mcp --help` 로 확인할 것.

---

## 1. 무인(자율) 실행

기본 Codex 는 명령/수정마다 승인을 묻는다. 루프가 안 끊기게 하려면 자동승인으로 띄운다.

**가장 쉬운 방법 — 턴키 런처 [`run.sh`](run.sh).** 게이트 모두 충족(`DONE`)까지 codex 를 무인 모드로 반복 호출한다. 프로젝트가 없으면 공고 PDF 로 **기획 부트스트랩**(AGENTS.md §2.0)부터, 이미 있으면 **처음 관점 전면 재검토**로 더 끌어올린다.

```bash
./run.sh                      # 현 디렉터리 자율 진행(공고 PDF 자동 탐색)
./run.sh 공고-청년창업.pdf      # 공고 PDF 를 출발 씨앗으로
./run.sh "대학생 중고거래 SaaS" # 한 줄 아이템을 씨앗으로
MAX_ITERS=30 ./run.sh         # 반복 횟수 조정 (기본 20)
```

직접 부르고 싶으면 (무인 = 승인 프롬프트 없이):

```bash
# 대화형 TUI
codex --sandbox workspace-write --ask-for-approval never \
  "AGENTS.md 와 .claude/agents 읽고 자율 루프로 진행해"

# 비대화형(스크립트/CI) — 한 번 실행하고 끝. git repo 밖이면 --skip-git-repo-check
codex exec --sandbox workspace-write --ask-for-approval never --skip-git-repo-check \
  "AGENTS.md 읽고 게이트 모두 충족까지 진행해"
```

- **무인 권장**: `--sandbox workspace-write`(작업폴더 쓰기 허용) + `--ask-for-approval never`(승인 프롬프트 0). ⚠️ 구 `--full-auto` 는 **deprecated**(호환용으로만 남음) — `--sandbox workspace-write` 를 쓴다.
- 완전 무제한(샌드박스·승인 모두 해제, 네트워크 포함)은 `--dangerously-bypass-approvals-and-sandbox`(별칭 `--yolo`). **신뢰 환경에서만.**
- 플래그 값: `--sandbox {read-only|workspace-write|danger-full-access}`, `--ask-for-approval {untrusted|on-request|never}`. 정확한 목록은 버전마다 다르니 `codex --help`·`codex exec --help` 로 확인.
- **디렉터리 신뢰**: 비신뢰 폴더에서 승인이 자꾸 뜨면 `--ask-for-approval never` 로 무인화하거나, `~/.codex/config.toml` 의 `[projects."<경로>"] trust_level = "trusted"` 로 신뢰 등록.

**큰 목표는 이어달리기.** 참고문헌 1,000·기능 100 은 한 세션 컨텍스트를 넘길 수 있다 → 산출물에 `현재/목표`(예: `412 / 1,000`)를 남기는 규칙([AGENTS.md §2](AGENTS.md)) 덕에 **다시 `codex exec` 를 호출하면 남은 분량부터** 이어서 채운다(run.sh 가 이 반복을 대신한다).

---

## 2. 병렬 실행 (worktree)

Codex 는 Claude Code 처럼 서브에이전트를 자동 spawn 하지 않는다 → **여러 Codex 프로세스를 직접** 띄워 병렬화한다. 충돌을 막으려면 `git worktree` 로 분리:

```bash
# 역할/프로젝트별 worktree 분리 후 백그라운드 병렬 실행
for role in research-collector app-builder figure-maker; do
  git worktree add ../wt-$role HEAD
  ( cd ../wt-$role && codex exec --sandbox workspace-write --ask-for-approval never \
      ".claude/agents/$role.md 를 열어 그 역할로 해당 산출물만 만들어. git 커밋은 하지 마." ) &
done
wait
# 병합·커밋·버전 태그 고정은 오케스트레이터(메인)가 일괄 (CLAUDE.md §3.5)
```

- 같은 파일을 동시에 고치지 않게 **역할별 산출물 디렉터리를 분리**한다([AGENTS.md §5](AGENTS.md)).
- 커밋·`release/<project>/vN` 브랜치·태그 고정은 **한 명(메인)** 이 담당.

---

## 3. MCP 로 도구 강화 (권장)

MCP 서버를 붙이면 Codex 의 도구가 좋아진다. 이 워크플로에서 **효과가 큰 순서**:

| MCP 서버 | 강화되는 역할 | 효과 |
|:---|:---|:---|
| **검색**(Tavily·Brave·fetch) | `research-collector` | 참고문헌 1,000+ 를 구조화 결과로 안정 수집(스크래핑보다 토큰효율·정확) |
| **Playwright**(`@playwright/mcp`) | `capture-runner` | 캡처 스크립트 없이 실제 브라우저로 PC/모바일 스크린샷·DOM 점검 |
| **filesystem** | 전 역할 | 스코프된 파일 읽기/쓰기 표준화 |
| **git / github** | orchestrator | 커밋·브랜치·PR 표준화 |

### 설정 — CLI (권장)
형식: `codex mcp add <이름> [--env KEY=VAL] -- <stdio 실행명령>`

```bash
codex mcp add playwright -- npx -y @playwright/mcp@latest
codex mcp add tavily --env TAVILY_API_KEY=$TAVILY_API_KEY -- npx -y tavily-mcp
codex mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem .

codex mcp list            # 등록 확인 (TUI 안에서는 /mcp)
codex mcp --help          # 정확한 옵션은 버전마다 다름
```

### 또는 `~/.codex/config.toml` 직접
```toml
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]

[mcp_servers.tavily]
command = "npx"
args = ["-y", "tavily-mcp"]
env_vars = ["TAVILY_API_KEY"]   # 셸 env 에서 키를 전달(레포에 키 커밋 금지)

[mcp_servers.filesystem]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "."]
```
필드: `command`(필수)·`args`(선택)·`env`(키=값 테이블)·`env_vars`(셸 env 에서 전달할 변수명).

### 주의
- MCP 는 **자율성을 바꾸지 않는다** — 여전히 무인 모드(`--sandbox workspace-write --ask-for-approval never`)로 띄워야 루프가 안 끊긴다.
- 각 MCP 서버의 **도구 스키마가 컨텍스트를 먹는다** → 꼭 필요한 서버만 켠다.
- 검색·일부 서버는 **API 키** 필요. 키는 `.env`/셸 env 로, **레포에 커밋 금지**([CLAUDE.md §3.1](CLAUDE.md)).
- Playwright MCP 도 캡처는 [§2.4 캡처 의무](CLAUDE.md) 그대로: **PC·모바일 폴더 분리 + 스크린샷 눈검수**.

---

## 4. 한계 (정직하게)

- **자가검증**: `qa-auditor` 는 같은 모델이 자기 산출물을 검사하는 구조 → 누락·정량 미달·컬러 그림은 잘 잡지만 **독립 보증은 아니다**. 참고문헌 진위·차별점 품질은 사람이 한 번 확인 권장.
- **정직성 우선**: 정량 미달을 허위 충족으로 적지 않는다([CLAUDE.md §2.6](CLAUDE.md)). 미달이면 현재 수치를 남기고 루프를 더 돌린다.
