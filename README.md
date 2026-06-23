# k-startup-template — 공모전·창업지원사업 산출물 템플릿 키트

공모전·창업지원사업·연구과제의 **제안서 → 개발계획서 → 과업지시서 → 개발결과보고서 + 데모 앱**을
규약대로(정량 기준·논문형 그림·반응형·정직성) 만들기 위한 **재사용 템플릿**이다.
Claude Code 와 OpenAI Codex CLI **양쪽**에서 자율 실행되도록 설계했다.

## 구성

| 경로 | 내용 |
|:---|:---|
| [`CLAUDE.md`](CLAUDE.md) | **규칙 단일 출처** — 디렉터리 규약·문서 규약·정량 기준·DoD·금지사항 |
| [`AGENTS.md`](AGENTS.md) | **자율 운영 루프** — "진행해" 한마디로 스캔→채움→검증→반복 (Codex/Claude 공용) |
| [`CODEX.md`](CODEX.md) | Codex 무인 실행(`--sandbox workspace-write -a never`)·worktree 병렬·**MCP 서버 설정** 가이드 |
| [`.claude/agents/`](.claude/agents/) | 역할별 서브에이전트(병렬 spawn): proposal·research·차별점·figure·app·capture·report·qa·orchestrator |
| [`design-guide/`](design-guide/) | 데모 앱 디자인 가이드(애플×토스·모바일·PC·반응형 검수) |
| [`forms/`](forms/) | **문서 양식 + 참고자료 단일 디렉터리** — `forms/biz/`(빈 골격), `forms/refs/`(참고 PDF) |

## 핵심 정량 기준 (CLAUDE.md)
- 참고문헌 **≥ 1,000** (실제 출처만, 날조·중복 금지)
- 차별점 **≥ 50** (카테고리화, 부풀리기 금지)
- 데모 앱 기능 **≥ 100** (실 동작만, 버전 누적 허용)
- 문서 그림자료 = **논문형 흑백**(컬러 0, 번호·캡션) / 데모 앱 UI = 디자인가이드(컬러)
- 웹 데모 **모바일·PC 반응형** + 캡처 폴더 분리 + 눈검수
- 버전별 `release/<project>/vN` 브랜치·`<project>-vN` 태그로 언제든 단독 배포

## 사용법

전 과정(**기획 → 제안서·조사 → 개발 → 캡처·테스트 → 검수**)이 한 번의 지시로 자동으로 돈다.
출발 씨앗은 **공고 PDF**(가장 정확) 또는 **한 줄 아이템**이며, 둘 다 없으면 키트 예시 공고로 데모한다.

### 0. 공고 PDF 넣기 (기획의 씨앗)
새 프로젝트라면 공고(과제) PDF 를 워크스페이스 루트에 `공고-<사업명>.pdf` 로 두거나 [`forms/refs/`](forms/refs/) 에 넣는다.
자율 루프의 **부트스트랩**([`AGENTS.md` §2.0](AGENTS.md))이 `pdftotext` 로 공고를 읽어 메타(사업명·주관기관·트랙·일정·섹션 순서)를 **공고에 적힌 사실만** 뽑고, `<프로젝트>/biz/`·`projects/` 를 만들고 `forms/biz/` 골격을 복사해 제안서 머리표까지 채운 뒤 본 루프에 진입한다(없는 한도·자격은 창작하지 않음).

### 1. Codex CLI — 턴키 런처(권장)
```bash
./run.sh                      # 현 디렉터리 자율 진행(공고 PDF 자동 탐색)
./run.sh 공고-청년창업.pdf      # 공고 PDF 를 출발 씨앗으로
./run.sh "대학생 중고거래 SaaS" # 한 줄 아이템을 씨앗으로
MAX_ITERS=30 ./run.sh         # 반복 횟수 조정 (기본 20)
```
→ [`run.sh`](run.sh) 가 게이트를 **모두 충족(`DONE`)할 때까지** codex 를 무인 모드로 반복 호출한다.
직접 부르려면 `codex --sandbox workspace-write --ask-for-approval never "AGENTS.md 와 .claude/agents 읽고 자율 루프로 진행해"` (구 `--full-auto` 는 deprecated).
무인 실행·worktree 병렬·MCP 설정은 [`CODEX.md`](CODEX.md) 참고. (codex CLI 는 별도 설치 필요 — 런처가 부재 시 안내한다.)

### 2. Claude Code
```
"orchestrator 로 AGENTS.md 자율 루프 돌려서 끝까지 완성해"
```
→ 역할 에이전트를 병렬 spawn, 검증·커밋·버전 태그 고정을 일괄 수행.

### 자율 루프가 하는 일 (ASSESS → PLAN → EXECUTE → VERIFY → REPEAT)
스스로 현재 디렉터리를 점검 → 역할 문서를 읽고 부족분을 채움 → 적대적 검수 → 게이트를 **모두 충족할 때까지 반복**한다([`AGENTS.md` §2](AGENTS.md)).
- **전면 재검토** — 이미 만들어진 산출물도 매 사이클 *처음 관점*에서 다시 의심·실측해 품질을 끌어올린다(증분 점검 아님).
- **정직성 우선** — 정량 미달을 허위 충족으로 적지 않고 `현재/목표` 수치를 남긴 채 루프를 더 돈다.
- **멈추지 않음** — 한 항목이 끝나면 다음 미달 항목으로 자동 진행(매번 확인하지 않음).

## 시작
1. 새 작업 디렉터리에 이 키트 내용을 둔다(또는 이 레포를 클론).
2. (새 프로젝트면) 공고 PDF 를 루트나 `forms/refs/` 에 둔다 — 위 **0단계**.
3. `./run.sh`(Codex) 또는 **"에이전트 파일 읽고 진행해"**(Claude) → 자율 루프 시작.
4. 팀·서명 빈칸(`forms/biz/_사용자입력_필요항목.md`)만 제출 전 직접 채운다.
