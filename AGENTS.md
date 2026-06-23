# AGENTS.md — 자율 운영 지침 (Codex / Claude 공용)

> 이 파일 하나만 읽고 **"진행해"** 라고 지시받으면, 에이전트는 **스스로** 현재 디렉터리를 점검하고 → 역할 문서를 읽고 → 부족한 부분을 채우고 → 검증하고 → 기준을 모두 충족할 때까지 **반복**한다.
>
> **규칙의 단일 출처(Single Source of Truth)는 [`CLAUDE.md`](CLAUDE.md)** 다. 이 AGENTS.md 는 그 규칙을 **자율 실행 루프**로 옮긴 운영서다. 규칙 충돌 시 CLAUDE.md 가 우선하며, 규칙을 바꾸면 **CLAUDE.md 와 이 파일을 함께** 갱신한다(둘을 어긋나게 두지 말 것).

---

## 0. 시작하기 (Codex / Claude 공통)

사용자가 **"에이전트 파일 읽고 작업 진행해"** 라고만 말하면, 아래 **자율 루프(§2)** 를 시작한다. 추가 지시를 기다리지 말고 합리적 기본값으로 진행한다(단, [`CLAUDE.md` §2.7](CLAUDE.md) 팀·서명 빈칸은 `<TODO: 사용자 입력>` 으로 두고 묻지 않는다).

> ### ⚠️ Codex 사용자 — 먼저 읽어라 (이거 안 하면 동작 안 함)
> Codex 는 **이 `AGENTS.md` 한 파일만 자동 로드**한다(git 루트→현재 디렉터리, 합산 **32KiB 상한**). [`CLAUDE.md`](CLAUDE.md)(규칙 본문)·[`.claude/agents/*.md`](.claude/agents/)(역할 정의)·[`design-guide/`](design-guide/)·[`그림자료_규약.md`](그림자료_규약.md) 는 **자동으로 안 읽힌다.**
> 1. **첫 행동**: 파일 도구로 [`CLAUDE.md`](CLAUDE.md) 를 **직접 연다**(규칙 단일 출처). 역할 작업을 시작할 때마다 해당 [`.claude/agents/<role>.md`](.claude/agents/) 도 **직접 연다**. §3 표는 요약일 뿐 — 세부는 그 파일에 있다.
> 2. **서브에이전트 spawn 불가**: '병렬 spawn'은 Claude Code 전용이다. Codex 는 §3 역할을 **한 프로세스 안에서 순차로 역할 전환**하거나, 여러 Codex 프로세스를 `git worktree` 로 띄워 병렬화한다([`CODEX.md` §2](CODEX.md)).
> 3. **무인 실행 플래그**: `codex exec --sandbox workspace-write --ask-for-approval never`(구 `--full-auto` 는 **deprecated**). git repo 밖이면 `--skip-git-repo-check`. 승인 프롬프트로 루프가 끊기면 디렉터리 신뢰 또는 `-a never` 로 푼다([`CODEX.md` §1](CODEX.md)).

- **Claude Code**: [`.claude/agents/`](.claude/agents/) 의 서브에이전트를 `Agent`(Task) 도구로 **한 메시지에 여러 개 동시 spawn**(병렬). 오케스트레이션은 [`.claude/agents/orchestrator.md`](.claude/agents/orchestrator.md) 참고.

> Codex 무인 실행·worktree 병렬·**MCP 서버**(검색·Playwright 등)·디렉터리 신뢰 설정은 [`CODEX.md`](CODEX.md). 턴키 런처는 [`run.sh`](run.sh).

---

## 1. 작업 대상 파악 (먼저 읽어라)

1. **`CLAUDE.md` 전체** — 규약·정량 기준·DoD·금지사항. 최우선.
2. **현재 디렉터리 스캔** — 무엇이 이미 있고 무엇이 없는지. 각 프로젝트(`<project>/`)의 `biz/`·`projects/` 상태:
   - 문서: `1_제안서.md`, `2_개발계획서.md`, `N_과업지시서_vN.md`, `N_1_개발결과보고서_vN.md`, `5_research/README.md`
   - 앱: `projects/<app>/vN.html`, 캡처 `biz/captures/<vN>/`·`biz/captures/mobile/<vN>/`
3. **역할 문서** — [`.claude/agents/*.md`](.claude/agents/) (각 역할의 책임·산출물·규칙). Codex 는 이 파일들을 직접 읽어 해당 역할로 빙의해 실행한다.
4. **양식파일·참고자료** — [`forms/`](forms/) 한 디렉터리에 모여 있다(`forms/biz/` 빈 골격, `forms/refs/` 참고 PDF). 골격을 복사해 새 산출물의 출발점으로 삼는다.

> **공고(과제) PDF 위치 — 기획의 출발 씨앗.** 새 프로젝트의 공고 PDF 는 워크스페이스 루트(예: `공고-<사업명>.pdf`) 또는 [`forms/refs/`](forms/refs/) 에 둔다. 부트스트랩(§2.0)이 이를 찾아 메타를 추출한다. 공고가 없으면 키트 예시 공고 [`forms/refs/ref-startup-club-notice.pdf`](forms/refs/ref-startup-club-notice.pdf) 로 데모하거나, 사용자가 준 **한 줄 아이템**을 씨앗으로 쓴다.

---

## 2. 자율 루프 (ASSESS → PLAN → EXECUTE → VERIFY → REPEAT)

```
0. BOOTSTRAP (프로젝트가 없을 때 — "기획")
   — `<project>/biz/` 가 하나도 없으면 LOOP 전에 먼저 기획한다.
   a. 공고 PDF 를 찾는다(§1: 루트/`forms/refs/`). 텍스트 추출 `pdftotext <공고>.pdf -`
      (또는 모델이 직접 PDF 판독). 공고가 없고 한 줄 아이템만 주어지면 그 아이템을 씨앗으로.
   b. 공고에서 메타(사업명·주관기관·트랙·일정·자격·요구 섹션 순서)를 뽑는다 —
      **창작 금지, 공고에 적힌 사실만**(CLAUDE.md §7). 없는 한도·자격은 추정하지 않는다.
   c. 프로젝트 디렉터리 생성: `<kebab-사업명>/biz/`·`<...>/projects/`.
      `forms/biz/` 골격을 `biz/` 로 복사해 출발점으로 삼는다.
   d. 제안서 머리표에 공고 메타를 채우고 섹션 순서를 공고대로 고정 → LOOP 진입.

LOOP:
  1. ASSESS  — **매 사이클 "처음 관점"에서 전면 재검토**(증분 점검 금지). 이미 만들어진
               산출물도 새로 쓴 것처럼 §1·게이트(§4) 기준으로 다시 읽고 적대적으로 평가해
               "충족/미달·품질결함" 표를 만든다. 정량 수(참고문헌·차별점·기능·캡처)는 매번 실측.
  2. PLAN    — 미달·결함 항목을 골라, 각 항목에 §3 역할을 배정한다. 독립 항목은 병렬(Claude=동시 spawn / Codex=순차 역할 전환 또는 worktree 병렬), 의존 항목은 순서대로.
  3. EXECUTE — 배정된 역할 문서(.claude/agents/<role>.md)를 읽고 그 규칙대로 산출물을 만든다/고친다.
  4. VERIFY  — qa-auditor 가 §4 게이트 + 품질을 **처음 보는 산출물처럼** 적대적으로 검증. ❌면 같은 역할로 수정.
  5. REPEAT  — 미달·결함이 남아 있으면 1로. **모든 게이트 ✅ 면 종료**하고 최종 보고.
```

- **전면 재검토 원칙 (사용자 지시, 2026-06-23)**: "이미 다 했다"고 가정하지 않는다. 매 사이클 기존 산출물을 **처음 관점에서 다시 의심**하고(품질·정합·정직성·정량) 더 끌어올린다. 토큰을 아끼려고 점검을 건너뛰지 않는다 — 의심 → 실측 → 보강.
- **멈추지 말 것**: 한 항목이 끝나면 다음 미달 항목으로 자동 진행. 사용자에게 매번 확인하지 않는다.
- **정직성 우선**: 정량 기준 미달이어도 **허위로 충족 표기 금지**([`CLAUDE.md` §2.6](CLAUDE.md)). 진행 중이면 "현재/목표" 수치를 산출물에 명시하고 루프를 계속 돌려 채운다.
- **git**: 하위 역할은 파일·캡처만 만든다. 커밋·브랜치/태그 고정은 **오케스트레이터가 일괄**([`CLAUDE.md` §3.5](CLAUDE.md)).

---

## 3. 역할 → 산출물 (배정표)

| 역할(.claude/agents) | 언제 돌리나(미달 신호) | 산출물 |
|---|---|---|
| `research-collector` | 참고문헌 < 1,000 | `biz/5_research/` |
| `differentiation-analyst` | 차별점 < 50 | 제안서 차별성 섹션 |
| `proposal-writer` | 제안서 누락/필수 섹션 미비 | `biz/1_제안서.md` |
| `figure-maker` | 문서 그림이 컬러/캡션 누락 | 각 문서 figure(논문형 흑백) |
| `app-builder` | 앱 기능 < 100 / 뷰·워크플로 부족 | `projects/<app>/vN.html` |
| `capture-runner` | 캡처 부족 / PC·모바일 미분리 | `biz/captures/...` |
| `report-writer` | 과업지시서·결과보고서 누락 | `biz/N_*_vN.md` |
| `qa-auditor` | 매 VERIFY 단계 | 검수 결과(수정 지시) |

Codex 는 표의 역할 행에 해당하는 `.claude/agents/<role>.md` 를 읽고 그 시스템 프롬프트대로 행동한다.

---

## 4. 완료 게이트 (모두 ✅ 여야 종료 — CLAUDE.md §6 DoD 발췌+정량)

- [ ] 공고 PDF 메타(사업명·주관기관·트랙·일정)가 제안서 머리표·섹션 순서와 일치(공고 없으면 키트 예시/한 줄 아이템으로 데모임을 명시)
- [ ] `biz/`·`projects/` 구조, 제안서 필수 섹션(프레임워크·GTM·수익모델·차별성·구매동인·참고문헌)
- [ ] **참고문헌 ≥ 1,000** (실제 출처, 날조·중복 0) — 미달 시 현재 수치 명시
- [ ] **차별점 ≥ 50** (카테고리화, 부풀리기 0)
- [ ] **앱 기능 ≥ 100** (실 동작만, 버전 누적 허용) — 결과보고서에 기능 목록표
- [ ] 과업지시서 5섹션 / 결과보고서 D구조 + 캡처 실존
- [ ] 웹 데모 **모바일·PC 반응형** + 캡처 폴더 분리 + **반응형 눈검수 통과**
- [ ] **문서 그림자료 = 순수 흑백 논문형**(흰 배경+검정만, 회색·컬러 0, Mermaid base init, 번호·캡션, 렌더 PNG 눈검수) / 앱 UI = 디자인가이드(컬러 OK)
- [ ] 통계·인용 각주 ↔ `5_research/` 정합, **데이터 정직성 선언**
- [ ] 팀·서명·연락처 자동채움 0건(`<TODO: 사용자 입력>`)
- [ ] (사이클 완료 시) `release/<project>/vN` 브랜치·`<project>-vN` 태그 고정(오케스트레이터)

---

## 5. 병렬 실행 (Codex)

- 역할이 **서로 다른 파일/디렉터리**를 만들면 동시에 돌려도 안전하다(같은 파일 동시 수정 금지).
- 충돌 위험이 있으면 `git worktree add ../wt-<role>` 로 분리 실행 후 병합.
- 대량 수량(출처 1,000)은 `research-collector` 를 도메인/출처유형별 N개로 나눠 병렬 수집 → **중복 제거 → 정직성 검증 → 통합**.
- 병합·커밋·버전 태그는 **오케스트레이터 1명**이 담당한다.
