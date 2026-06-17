# CODEX.md — Codex CLI 로 자율 실행하기 (+ MCP)

> 이 키트를 **OpenAI Codex CLI** 로 무인 실행/병렬 실행하는 방법과, **MCP 서버**로 도구를 강화하는 법.
> 규칙은 [`CLAUDE.md`](CLAUDE.md), 자율 루프는 [`AGENTS.md`](AGENTS.md). Codex 는 작업 디렉터리의 `AGENTS.md` 를 자동으로 컨텍스트에 싣는다.
>
> ⚠️ Codex CLI 플래그·설정은 버전마다 다를 수 있다. 실제 값은 `codex --help`, `codex mcp --help` 로 확인할 것.

---

## 1. 무인(자율) 실행

기본 Codex 는 명령/수정마다 승인을 묻는다. 루프가 안 끊기게 하려면 자동승인으로 띄운다.

```bash
# 작업 디렉터리(프로젝트 루트)에서 — 대화형 TUI, 저마찰 자동
codex --full-auto "AGENTS.md 와 .claude/agents 읽고 자율 루프로 진행해"

# 비대화형(스크립트/CI) — 한 번 실행하고 끝
codex exec --full-auto "AGENTS.md 읽고 게이트 모두 충족까지 진행해"
```

- `--full-auto` ≈ 샌드박스(workspace-write) + 실패 시에만 승인. 대부분의 무인 루프에 적합.
- 완전 무인(승인 0, 네트워크 포함)이 필요하면 `--dangerously-bypass-approvals-and-sandbox`(별칭 `--yolo`). **신뢰 환경에서만** — 임의 명령·네트워크를 무승인 실행한다.
- 세분 제어: `--sandbox {read-only|workspace-write|danger-full-access}`, `--ask-for-approval {untrusted|on-failure|on-request|never}`.

**큰 목표는 이어달리기.** 참고문헌 1,000·기능 100 은 한 세션 컨텍스트를 넘길 수 있다 → 산출물에 `현재/목표`(예: `412 / 1,000`)를 남기는 규칙([AGENTS.md §2](AGENTS.md)) 덕에 **다시 `codex exec` 를 호출하면 남은 분량부터** 이어서 채운다. 셸로 반복:

```bash
for i in $(seq 1 20); do
  codex exec --full-auto "AGENTS.md 자율 루프 계속. 미달 게이트만 채우고, 모두 충족이면 'DONE' 출력" \
    | tee -a .codex-run.log
  grep -q DONE .codex-run.log && break
done
```

---

## 2. 병렬 실행 (worktree)

Codex 는 Claude Code 처럼 서브에이전트를 자동 spawn 하지 않는다 → **여러 Codex 프로세스를 직접** 띄워 병렬화한다. 충돌을 막으려면 `git worktree` 로 분리:

```bash
# 역할/프로젝트별 worktree 분리 후 백그라운드 병렬 실행
for role in research-collector app-builder figure-maker; do
  git worktree add ../wt-$role HEAD
  ( cd ../wt-$role && codex exec --full-auto \
      ".claude/agents/$role.md 역할로 해당 산출물만 만들어. git 커밋은 하지 마." ) &
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

### 설정 — `~/.codex/config.toml`
```toml
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]

# 웹검색 (API 키 필요)
[mcp_servers.tavily]
command = "npx"
args = ["-y", "tavily-mcp"]
env = { TAVILY_API_KEY = "sk-..." }   # 키는 셸 env 로 주입 권장, 커밋 금지

[mcp_servers.filesystem]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "."]
```
또는 CLI 로: `codex mcp add playwright -- npx -y @playwright/mcp@latest` (지원 버전에서). 등록 확인: `codex mcp list`.

### 주의
- MCP 는 **자율성을 바꾸지 않는다** — 여전히 `--full-auto` 로 띄워야 무인 루프가 돈다.
- 각 MCP 서버의 **도구 스키마가 컨텍스트를 먹는다** → 꼭 필요한 서버만 켠다.
- 검색·일부 서버는 **API 키** 필요. 키는 `.env`/셸 env 로, **레포에 커밋 금지**([CLAUDE.md §3.1](CLAUDE.md)).
- Playwright MCP 도 캡처는 [§2.4 캡처 의무](CLAUDE.md) 그대로: **PC·모바일 폴더 분리 + 스크린샷 눈검수**.

---

## 4. 한계 (정직하게)

- **자가검증**: `qa-auditor` 는 같은 모델이 자기 산출물을 검사하는 구조 → 누락·정량 미달·컬러 그림은 잘 잡지만 **독립 보증은 아니다**. 참고문헌 진위·차별점 품질은 사람이 한 번 확인 권장.
- **정직성 우선**: 정량 미달을 허위 충족으로 적지 않는다([CLAUDE.md §2.6](CLAUDE.md)). 미달이면 현재 수치를 남기고 루프를 더 돌린다.
