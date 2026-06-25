# k-startup-template — 공모전·창업지원사업 산출물 템플릿 키트

공모전·창업지원사업·연구과제의 **제안서 → 개발계획서 → 과업지시서 → 개발결과보고서 + 데모 앱**을
규약대로(정량 기준·논문형 그림·반응형·정직성) 만들기 위한 **재사용 템플릿**이다.
**OpenAI Codex CLI** 와 **Claude Code** 양쪽에서 자율 실행되도록 설계했다.

## 이렇게 쓴다 (배포 모델)

```
①  이 레포를 GitHub 에서 clone
②  (선택) Codex MCP 서버 등록 — 웹검색·브라우저 캡처 강화
③  공고 PDF 한 개를 레포에 넣는다 (또는 한 줄 아이템)
④  Codex 에게:  "AGENTS.md 읽고 진행해"
⑤  Codex 가 에이전트 파일을 읽고 기획→집필→개발→캡처→검수를 알아서 반복
```

받는 사람은 **클론 → 명령 한 줄**이면 된다. 무엇을·어떤 기준으로·어떤 순서로 만들지는 전부 레포 안의 에이전트 파일([`AGENTS.md`](AGENTS.md)·[`CLAUDE.md`](CLAUDE.md)·[`.claude/agents/`](.claude/agents/))에 들어 있다.

## 구성

| 경로 | 내용 |
|:---|:---|
| [`AGENTS.md`](AGENTS.md) | **Codex 가 자동 로드하는 진입점** — 자율 운영 루프(스캔→채움→검증→반복) + 기획 부트스트랩 + 완료 게이트 |
| [`CLAUDE.md`](CLAUDE.md) | **규칙 단일 출처** — 디렉터리 규약·문서 규약·정량 기준·DoD·금지사항 (Codex 는 직접 열어 읽는다) |
| [`CODEX.md`](CODEX.md) | Codex 무인 실행 플래그·worktree 병렬·**MCP 서버 설정** 가이드 |
| [`.claude/agents/`](.claude/agents/) | 역할 정의 9종: proposal·research·차별점·figure·app·capture·report·qa·orchestrator |
| [`design-guide/`](design-guide/) | 데모 앱 디자인 가이드(애플×토스·모바일·PC·반응형 검수) |
| [`그림자료_규약.md`](그림자료_규약.md) | 문서 그림 = 순수 흑백 논문형 Mermaid init·변환 절차(단일 출처) |
| [`forms/`](forms/) | 문서 양식 + 참고자료 — `forms/biz/`(빈 골격)·`forms/refs/`(참고 PDF) |
| [`run.sh`](run.sh) | (CLI 전용) 게이트 충족까지 codex 를 무인 반복 호출하는 턴키 런처 |

## 핵심 정량 기준 ([CLAUDE.md](CLAUDE.md))
- 참고문헌 **≥ 1,000** (실제 출처만, 날조·중복 금지)
- 차별점 **≥ 50** (카테고리화, 부풀리기 금지)
- 데모 앱 기능 **≥ 100** (실 동작만, 버전 누적 허용)
- 문서 그림자료 = **논문형 순수 흑백**(컬러·회색 0, 번호·캡션) / 데모 앱 UI = 디자인가이드(컬러)
- 웹 데모 **모바일·PC 반응형** + 캡처 폴더 분리 + 눈검수
- 버전별 `release/<project>/vN` 브랜치·`<project>-vN` 태그로 언제든 단독 배포

---

# 설치 (Setup)

> 받는 사람 기준 — 처음부터. macOS/Linux 예시. Windows 는 PowerShell 또는 WSL2.

## 1. Codex CLI 설치

셋 중 하나 (공식, 2026):

```bash
npm install -g @openai/codex                       # npm (Node.js 20+ 필요)
brew install --cask codex                           # Homebrew (macOS)
curl -fsSL https://chatgpt.com/codex/install.sh | sh  # 설치 스크립트 (macOS/Linux)
```

설치 확인:

```bash
codex --version
```

> `command not found` 면 PATH 문제다 — 새 터미널을 열거나, npm 전역 bin 경로(`npm bin -g`)를 PATH 에 추가한다.

## 2. 인증 (로그인)

```bash
codex          # 첫 실행 시 브라우저가 열리며 로그인
```

- **ChatGPT 계정**(Plus·Pro·Business·Edu·Enterprise) 또는 **OpenAI API 키** 로 인증.
- 토큰은 `~/.codex/auth.json` 에 캐시된다(한 번만 로그인하면 됨).

## 3. 보조 도구 (선택 — 없으면 해당 단계만 제한)

| 도구 | 쓰는 곳 | 설치 |
|:---|:---|:---|
| **poppler**(`pdftotext`) | 공고 PDF → 텍스트 추출(기획 부트스트랩) | `brew install poppler` |
| **mermaid-cli**(`mmdc`) | 문서 그림 흑백 렌더 눈검수(figure-maker) | `npm i -g @mermaid-js/mermaid-cli` |
| **Playwright** | 데모 앱 PC·모바일 캡처(capture-runner) | 아래 **MCP** 권장, 또는 `npx playwright` |

> 보조 도구는 MCP 로 대체할 수 있다(다음 절). 예: 검색 MCP 가 있으면 `pdftotext` 없이도 공고 본문을 다룰 수 있고, Playwright MCP 가 있으면 별도 설치 없이 캡처한다.

## 4. MCP 서버 등록 (권장)

MCP 를 붙이면 Codex 도구가 강해진다(웹검색·실브라우저 캡처·파일접근). **자율성은 안 바뀐다** — 무인 플래그는 그대로 필요.

```bash
# 형식:  codex mcp add <이름> [--env KEY=VAL] -- <stdio 실행명령>
codex mcp add playwright -- npx -y @playwright/mcp@latest          # 브라우저 캡처
codex mcp add tavily --env TAVILY_API_KEY=$TAVILY_API_KEY -- npx -y tavily-mcp   # 웹검색(키 필요)
codex mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem .     # 파일접근

codex mcp list      # 등록 확인  (TUI 안에서는 /mcp)
```

또는 `~/.codex/config.toml` 에 직접:

```toml
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]

[mcp_servers.tavily]
command = "npx"
args = ["-y", "tavily-mcp"]
env_vars = ["TAVILY_API_KEY"]   # 셸 env 에서 키를 전달(레포에 키 커밋 금지)
```

| MCP | 강화되는 역할 | 효과 |
|:---|:---|:---|
| 검색(Tavily·Brave·fetch) | `research-collector` | 참고문헌 1,000+ 안정 수집 |
| Playwright | `capture-runner` | 실브라우저 PC/모바일 캡처·DOM 점검 |
| filesystem | 전 역할 | 스코프된 파일 읽기/쓰기 |

> ⚠️ MCP 서버마다 도구 스키마가 컨텍스트를 먹는다 → 꼭 필요한 것만 켠다. API 키는 `.env`/셸 env 로, **레포에 커밋 금지**. 자세히는 [`CODEX.md` §3](CODEX.md).

---

# 사용법 (Usage)

## 1. 클론

```bash
git clone <이 레포 URL> my-project
cd my-project
```

## 2. 출발 씨앗 넣기 (기획의 시작점)

자율 루프는 **공고 PDF**(가장 정확) 또는 **한 줄 아이템**에서 출발한다. 둘 다 없으면 키트 예시 공고로 데모한다.

- **공고 PDF**: 공고(과제) PDF 를 레포 루트에 `공고-<사업명>.pdf` 로 두거나 [`forms/refs/`](forms/refs/) 에 넣는다.
- **한 줄 아이템**: 파일 없이 실행 명령에 아이템을 적어도 된다(예: `"대학생 중고거래 SaaS"`).

기획 부트스트랩([`AGENTS.md` §2.0](AGENTS.md))이 공고에서 메타(사업명·주관기관·트랙·일정·섹션 순서)를 **공고에 적힌 사실만** 뽑아 `<프로젝트>/biz/`·`projects/` 를 만들고 제안서 머리표까지 채운 뒤 루프에 진입한다(없는 한도·자격은 창작하지 않음).

## 3. 실행 — "읽고 진행해"

**무인(승인 프롬프트 없이) 모드**로 띄운다:

```bash
# 대화형
codex --sandbox workspace-write --ask-for-approval never \
  "AGENTS.md 읽고 진행해"

# 비대화형(스크립트/CI) — git repo 밖이면 --skip-git-repo-check 추가
codex exec --sandbox workspace-write --ask-for-approval never \
  "AGENTS.md 읽고 게이트 모두 충족까지 진행해"
```

또는 턴키 런처(게이트 충족까지 자동 반복):

```bash
./run.sh                       # 공고 PDF 자동 탐색
./run.sh 공고-청년창업.pdf       # 공고 PDF 를 씨앗으로
./run.sh "대학생 중고거래 SaaS"  # 한 줄 아이템을 씨앗으로
MAX_ITERS=30 ./run.sh          # 반복 횟수 조정(기본 20)
```

> **Claude Code** 로 돌릴 때: `"orchestrator 로 AGENTS.md 자율 루프 돌려서 끝까지 완성해"` — 역할 에이전트를 병렬 spawn 하고 검증·커밋·버전 태그 고정까지 일괄 수행.

## 4. 무엇이 일어나나 (자율 루프)

ASSESS → PLAN → EXECUTE → VERIFY → REPEAT 를 게이트 모두 충족까지 반복한다([`AGENTS.md` §2](AGENTS.md)).
- **전면 재검토** — 이미 만든 산출물도 매 사이클 *처음 관점*에서 다시 의심·실측해 끌어올린다(증분 점검 아님).
- **정직성 우선** — 정량 미달을 허위 충족으로 적지 않고 `현재/목표` 수치를 남긴 채 더 돈다.
- **멈추지 않음** — 한 항목이 끝나면 다음 미달 항목으로 자동 진행(매번 확인 안 함).

산출물은 `<프로젝트>/biz/`(문서)·`<프로젝트>/projects/`(데모 앱)·`biz/captures/`(캡처)에 쌓인다.

## 5. 사람이 채울 것

팀·서명·연락처 등 행정 빈칸은 자동으로 안 채운다 — `<TODO: 사용자 입력>` 로 남는다. 제출 전 [`forms/biz/_사용자입력_필요항목.md`](forms/biz/_사용자입력_필요항목.md) 기준으로 직접 채운다.

---

# 트러블슈팅

| 증상 | 원인 / 해결 |
|:---|:---|
| Codex 가 규칙을 안 따르는 듯 | Codex 는 **`AGENTS.md` 만 자동 로드**(32KiB 상한). `CLAUDE.md`·`.claude/agents/*.md` 는 자동으로 안 읽힌다 → AGENTS.md §0 지시대로 Codex 가 직접 열어야 한다. "AGENTS.md 읽고 진행해" 로 시작하면 그 절차가 명시돼 있다. |
| **토큰을 적게 쓰고 금방 끝남 = 얕게 함** | 작업은 방대해서(참고문헌 1,000+·기능 100+) 짧게 끝날 수 없다. AGENTS.md §0(작업 강도)·§2.6(안티패턴)이 골격·"나중에 계속"·미실측 ✅ 를 금지하고, §2.5 가 게이트를 grep/카운트로 실측하게 한다. 그래도 한 번에 다 못 차면 `run.sh` 로 `DONE` 까지 자동 반복(이어달리기). |
| 매 명령마다 승인 프롬프트 → 루프 끊김 | `--ask-for-approval never` 를 빼먹었다. 위 무인 플래그로 실행. 또는 `~/.codex/config.toml` 에 `[projects."<경로>"] trust_level = "trusted"`. |
| `--full-auto` 안내가 deprecated 라고 뜸 | 맞다 — `--sandbox workspace-write --ask-for-approval never` 를 쓴다. |
| `codex: command not found` | 새 터미널을 열거나 npm 전역 bin(`npm bin -g`)을 PATH 에 추가. |
| 공고 PDF 를 못 읽음 | `brew install poppler`(`pdftotext`) 설치, 또는 검색/파일 MCP 사용. |
| 참고문헌 1,000·기능 100 이 한 번에 안 참 | 정상 — 컨텍스트를 넘기므로 `현재/목표` 수치를 남기고 멈춘다. **다시 실행하면 남은 분량부터** 이어간다(`run.sh` 가 자동 반복). |
| 캡처가 안 됨 | Playwright MCP 등록 또는 `npx playwright install`. |

자세한 무인 실행·병렬·MCP 는 [`CODEX.md`](CODEX.md), 규칙 전체는 [`CLAUDE.md`](CLAUDE.md).
