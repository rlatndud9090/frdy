# FRDY Wiki Resolver

새 지식 또는 문서를 어디에 반영할지 결정할 때 이 문서를 먼저 읽습니다.

## 1. 먼저 판단할 것

이 정보는 아래 중 어디에 속합니까?

1. 현재형으로 유지해야 하는 프로젝트 지식
2. 작업 단위에서 발생한 근거/증거/초안
3. raw-wiki 패턴을 지키기 위한 schema/rule
4. 과거 결정이나 폐기된 계획의 보관 기록

## 2. 경로 규칙

### `docs/wiki/project/`

- 프로젝트 전체 판타지
- 런타임 구조의 최신 상태
- 저장소 운영 원칙

### `docs/wiki/systems/`

- 실제 코드 기준 시스템 구조
- 전투, 맵, 주문, 보상, 이벤트, UI, RNG 같은 기술/설계 축

### `docs/wiki/features/`

- 특정 이슈/기능 묶음이 남긴 현재 상태
- 장기적으로 재참조될 가능성이 있는 기능 설명

### `docs/wiki/concepts/`

- 밸런스 원칙
- UX 절대 원칙
- 실험 철학

### `docs/wiki/archive/`

- 더 이상 현재형 지식으로 쓰지 않는 과거 계획
- 폐기되었지만 맥락상 보존 가치가 있는 문서

### `docs/artifacts/<work-unit-id>/`

- PRD
- ADR
- 회의록
- AI 대화 기록
- 실험 결과
- 리뷰 메모
- 브랜치 단위 작업 이력

raw/artifact 계층은 수정 대상이 아니라 누적 대상입니다. 과거 기록을 고쳐 쓰지 말고, 정정이 필요하면 새 기록을 추가합니다. 단, `meta.md`의 상태/동기화/PR/merge 추적 필드는 운영상 갱신할 수 있습니다.

### schema / rules

- `docs/wiki/SCHEMA.md`
- `docs/wiki/RESOLVER.md`
- `docs/wiki/skills/wiki-query.md`
- `docs/wiki/skills/wiki-update.md`
- `scripts/check_artifact_*.sh`, `scripts/check_main_artifact_audit.sh`, `scripts/check_wiki_sync_guard.sh`

schema/rules 계층은 raw를 어디에 쌓고, wiki를 어떤 절차로 LLM이 재합성할지 정하는 규칙입니다.

## 3. 판정 규칙

- 현재 상태를 설명해야 하면 `wiki`
- 무엇을 근거로 그런 상태가 되었는지 보여줘야 하면 `artifacts`
- 패턴 유지 규칙을 정의해야 하면 `schema/rules`
- 과거 설계 초안이나 역사 기록이면 `wiki/archive`

## 4. RAG 규칙

- 질문 응답, 설계 설명, 코드 변경 전 맥락 파악은 `wiki`를 먼저 읽습니다.
- 아래 경우에만 `artifacts`로 내려갑니다.
  - 위키에 정보가 없을 때
  - 위키와 코드가 충돌할 때
  - 특정 결정의 근거가 필요할 때
  - 위키 업데이트를 수행할 때

## 5. 작업 종료 규칙

- 작업 단위 아티팩트가 생성되면 `meta.md`를 유지합니다.
- scaffold만 만든 `collecting` 상태로는 작업을 지속하지 않습니다. 최소한 범위/수용 기준/타임라인 초안을 채우고 `in_progress` 이상으로 올립니다.
- PR 생성 전 `wiki_sync_status`를 최소 `pending` 또는 `synced`로 명시합니다.
- main 머지 후에는 `main`에 반영된 `wiki_sync_status: pending` artifact를 대상으로 LLM이 관련 위키를 갱신하고 `wiki_sync_status: synced`로 바꿉니다.
- wiki 계층은 LLM만 수정합니다. 사람이 직접 wiki 본문을 고쳐 쓰지 않고, LLM에게 artifacts 기반 재합성을 요청합니다.
