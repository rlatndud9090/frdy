# FRDY Wiki Log

- 2026-04-14 | wiki-init | 루트 설계 문서를 `docs/wiki/` 체계로 이관하고 LLM Wiki 스키마를 도입했다.
- 2026-04-14 | history-bootstrap | 현재 코드, 루트 문서, git log를 근거로 pre-artifact 구현 히스토리를 사후 복원했다.
- 2026-04-14 | artifact-bootstrap | `wiki-init-2026-04` work unit artifact를 생성해 초기 도입 작업 자체를 근거층에 남겼다.
- 2026-04-16 | history-bootstrap-late-pre-artifact | 2026-03-20부터 2026-04-14까지의 late pre-artifact 구현 이력을 별도 backfill artifact와 `implementation-history.md`에 반영했다.
- 2026-04-28 | raw-wiki-schema-rules | raw/artifacts, wiki, schema/rules 3계층 운영 규칙과 wiki LLM-only 수정 원칙을 명문화했다.
- 2026-04-28 | artifact-hardening-main-wiki-sync | artifact completeness guard, main artifact audit, main 기준 wiki sync 운영 규칙을 main에 반영했다.
- 2026-04-28 | pr-wiki-sync-required | PR 생성 전 작업 artifact의 `wiki_sync_status: synced`와 대상 wiki diff 포함을 필수화했다.
