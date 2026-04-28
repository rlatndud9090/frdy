---
id: codex-raw-wiki-schema-rules
branch: codex/raw-wiki-schema-rules
status: in_progress
wiki_sync_status: pending
created_at: 2026-04-28
updated_at: 2026-04-28
related_issue: 
related_pr:
merge_commit:
wiki_targets:
  - docs/wiki/SCHEMA.md
  - docs/wiki/RESOLVER.md
  - docs/wiki/skills/wiki-update.md
  - docs/wiki/project/implementation-history.md
---

# Work Unit Meta

## Goal

- raw-wiki-schema 3계층 운영 규칙을 명문화합니다
- 이 브랜치의 변경과 검증 결과를 artifact에 지속적으로 누적합니다.

## Scope

- 포함 범위: raw/artifacts 누적 원칙, wiki LLM-only 수정 원칙, schema/rules 역할을 운영 문서에 명시
- 제외 범위: 런타임 코드 변경, 기존 미완성 artifact 정리, pending wiki sync 해소

## Acceptance

- SCHEMA/RESOLVER/AGENTS/wiki-update/artifacts README가 raw-wiki-schema 3계층 규칙을 일관되게 설명합니다.
- PR 전 `./scripts/check_artifact_progress.sh`와 `./scripts/check_artifact_guard.sh`를 통과합니다.

## Notes

- 브랜치 시작 직후 artifact 초안을 채워 껍데기 상태로 작업이 진행되지 않게 합니다.
