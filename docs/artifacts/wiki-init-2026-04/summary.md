# Wiki Init Summary

## 도입 내용

- `docs/wiki/`를 현재형 지식층으로 도입했습니다.
- `docs/artifacts/`를 작업 단위별 진실의 원천으로 도입했습니다.
- `wiki-first, artifacts-on-demand` 조회 규칙을 명문화했습니다.
- artifact scaffold 생성, PR 전 artifact guard, pending wiki sync 확인 스크립트를 추가했습니다.
- 기존 루트 설계 문서는 호환성 포인터로 전환했습니다.

## 운영 의미

- 앞으로는 작업 시작 시 artifact를 먼저 만들고, 구현/리뷰를 거친 뒤 wiki를 갱신합니다.
- wiki는 append-only가 아니라 현재형 재합성 문서로 유지합니다.
- pre-artifact 히스토리는 `history-bootstrap-2026-04` artifact를 근거로 삼습니다.
