# FRDY LLM Wiki Schema

이 문서는 `frdy`에서 LLM Wiki를 어떻게 읽고 쓰는지 정의합니다.

## 1. 계층 구조

`frdy`의 지식 구조는 아래 3계층으로 운영합니다.

```text
docs/artifacts/                 ← raw: 수정하지 않고 쌓아나가는 작업 단위 원천 데이터
docs/wiki/                      ← wiki: LLM만 수정하는 현재형 지식층
docs/wiki/SCHEMA.md 등 rule 문서  ← schema/rules: raw-wiki 패턴을 지키기 위한 운영 규칙
```

### raw / artifacts 계층

- `docs/artifacts/`는 수정하는 문서가 아니라 쌓아나가는 데이터입니다.
- 작업 중 발생한 PRD, ADR, 회의록, AI 대화 기록, 실험 로그, 리뷰 메모, 타임라인을 누적합니다.
- 과거 기록을 현재 관점으로 고쳐 쓰지 않습니다. 정정이 필요하면 새 기록을 추가합니다.
- 단, `meta.md`의 `status`, `wiki_sync_status`, `updated_at`, PR/merge 정보는 운영 추적을 위해 갱신할 수 있습니다.

### wiki 계층

- `docs/wiki/`는 LLM이 artifacts를 근거로 현재형 지식을 재합성하는 계층입니다.
- wiki 문서는 사람이 직접 편집하지 않고, LLM 요청을 통해서만 수정합니다.
- wiki는 append-only가 아니며, 현재 코드/결정과 맞도록 영향 페이지 단위로 재서술합니다.

### schema / rules 계층

- `docs/wiki/SCHEMA.md`, `docs/wiki/RESOLVER.md`, `docs/wiki/skills/*`, 관련 guard script는 패턴을 지키기 위한 룰입니다.
- schema/rules 계층은 raw를 어디에 쌓고, wiki를 언제 어떻게 재합성하며, LLM이 어떤 순서로 읽을지를 정의합니다.

## 2. 조회 우선순위

에이전트는 아래 순서를 기본으로 따릅니다.

1. `docs/wiki/RESOLVER.md`
2. `docs/wiki/index.md`
3. 관련 위키 페이지
4. 필요한 경우에만 관련 `docs/artifacts/<work-unit-id>/`
5. 그래도 부족하면 코드/테스트/깃 이력

즉, 기본 원칙은 `wiki-first, artifacts-on-demand`입니다.

## 3. 페이지 타입

### project

- 프로젝트의 현재 상태, 핵심 판타지, 운영 원칙

### systems

- 런타임 아키텍처, 전투/맵/주문/보상/이벤트/UI 같은 시스템 단위 설명

### features

- 특정 기능 또는 이슈 묶음이 남긴 현재형 지식

### concepts

- 게임 디자인 개념, 밸런스 철학, UX 원칙

### archive

- 과거 계획/폐기된 방향/역사 문서

## 4. 위키 갱신 원칙

- 위키는 append-only가 아닙니다.
- 위키 수정은 LLM만 수행합니다. 사람이 직접 현재형 지식을 고쳐 쓰지 않습니다.
- 아티팩트가 누적되면 관련 위키 페이지를 현재형으로 재합성합니다.
- 기본 전략은 `증분 업데이트 + 영향 페이지 단위 재합성`입니다.
- 전체 위키 전면 재작성은 정기 점검 또는 대형 리워크 때만 수행합니다.
- PR 생성 전에는 해당 작업 artifact의 `wiki_sync_status`가 `synced`여야 하며, `wiki_targets`에 적은 `docs/wiki/...` 파일이 같은 PR diff에서 갱신되어야 합니다.

## 5. 아티팩트 → 위키 반영 규칙

- `prd.md`, `adr/`, 회의록, 실험 로그, 리뷰 메모는 근거입니다.
- AI 대화 기록은 근거 후보이며, 검증된 결론만 위키로 승격합니다.
- `meta.md`의 `wiki_targets`는 어떤 위키 페이지를 갱신해야 하는지 나타냅니다.
- 작업 시작 시 영향 페이지가 불명확하면 `wiki_targets: []`로 둘 수 있지만, PR 전에는 실제 `docs/wiki/...` 대상이 1개 이상 필요합니다.
- `meta.md`의 `wiki_sync_status`가 `pending`이면 PR 생성 전 위키 갱신 대상입니다.
- `meta.md`의 `wiki_sync_status`가 `synced`이면 해당 작업의 영향 위키 페이지가 현재 PR 안에서 재합성된 상태입니다.
- main에 남은 `pending` artifact는 기존/예외 작업을 복구하기 위한 후속 sync 후보로만 취급합니다.

## 6. 단일 소스 원칙

- 루트의 `GAME_CONCEPT.md`, `CLASS_DIAGRAM.md`, `PLAN.md`는 더 이상 진실의 원천이 아닙니다.
- 이 파일들은 호환성용 포인터이며, 실제 최신 내용은 `docs/wiki/`에 둡니다.

## 7. 필수 허브 문서

- `docs/wiki/RESOLVER.md`
- `docs/wiki/index.md`
- `docs/wiki/log.md`
- `docs/wiki/skills/wiki-query.md`
- `docs/wiki/skills/wiki-update.md`
