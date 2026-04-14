# FRDY LLM Wiki Schema

이 문서는 `frdy`에서 LLM Wiki를 어떻게 읽고 쓰는지 정의합니다.

## 1. 계층 구조

`frdy`의 지식 구조는 아래 2계층으로 운영합니다.

```text
docs/wiki/       ← LLM이 기본 참조하는 정리된 현재 지식층
docs/artifacts/  ← 작업 단위별 진실의 원천 아티팩트 계층
```

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
- 아티팩트가 누적되면 관련 위키 페이지를 현재형으로 재합성합니다.
- 기본 전략은 `증분 업데이트 + 영향 페이지 단위 재합성`입니다.
- 전체 위키 전면 재작성은 정기 점검 또는 대형 리워크 때만 수행합니다.

## 5. 아티팩트 → 위키 반영 규칙

- `prd.md`, `adr/`, 회의록, 실험 로그, 리뷰 메모는 근거입니다.
- AI 대화 기록은 근거 후보이며, 검증된 결론만 위키로 승격합니다.
- `meta.md`의 `wiki_targets`는 어떤 위키 페이지를 갱신해야 하는지 나타냅니다.
- `meta.md`의 `wiki_sync_status`가 `pending`이면 후속 위키 갱신 대상입니다.

## 6. 단일 소스 원칙

- 루트의 `GAME_CONCEPT.md`, `CLASS_DIAGRAM.md`, `PLAN.md`는 더 이상 진실의 원천이 아닙니다.
- 이 파일들은 호환성용 포인터이며, 실제 최신 내용은 `docs/wiki/`에 둡니다.

## 7. 필수 허브 문서

- `docs/wiki/RESOLVER.md`
- `docs/wiki/index.md`
- `docs/wiki/log.md`
- `docs/wiki/skills/wiki-query.md`
- `docs/wiki/skills/wiki-update.md`
