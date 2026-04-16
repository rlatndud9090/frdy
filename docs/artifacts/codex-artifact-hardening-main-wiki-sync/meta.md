---
id: codex-artifact-hardening-main-wiki-sync
branch: codex/artifact-hardening-main-wiki-sync
status: ready-for-pr
wiki_sync_status: pending
created_at: 2026-04-16
updated_at: 2026-04-16
related_issue: 
related_pr:
merge_commit:
wiki_targets:
  - docs/wiki/project/wiki-sync-automation.md
  - docs/wiki/RESOLVER.md
  - docs/wiki/project/overview.md
---

# Work Unit Meta

## Goal

- artifact completeness guard와 main 기준 wiki sync 스킬을 도입합니다.
- 이 브랜치의 변경과 검증 결과를 artifact에 지속적으로 누적합니다.

## Scope

- 포함 범위: artifact 시작 절차, completeness guard, main push audit, main 기준 wiki sync 스킬, 관련 운영 문서 정리
- 제외 범위: 게임 런타임 로직 변경, 기존 feature 구현 범위 확장

## Acceptance

- 새 시작 스크립트와 completeness guard가 실제로 이 브랜치 artifact를 채우고 통과시킵니다.
- PR 전 `./scripts/check_artifact_progress.sh`와 `./scripts/check_artifact_guard.sh`를 통과합니다.

## Notes

- 이 브랜치는 규칙 강화와 스킬 추가를 한 번에 정리하는 인프라 작업입니다.
- `frdy-main-wiki-sync` 스킬은 최신 `main`만 기준으로 wiki sync를 수행하고, 본 브랜치의 guard는 그 전제인 artifact completeness를 보장합니다.
