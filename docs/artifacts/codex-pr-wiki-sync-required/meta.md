---
id: codex-pr-wiki-sync-required
branch: codex/pr-wiki-sync-required
status: merged
wiki_sync_status: synced
created_at: 2026-04-28
updated_at: 2026-04-28
related_issue:
related_pr:
merge_commit:
wiki_targets:
  - docs/wiki/SCHEMA.md
  - docs/wiki/RESOLVER.md
  - docs/wiki/skills/wiki-update.md
  - docs/wiki/project/wiki-sync-automation.md
  - docs/wiki/project/overview.md
  - docs/wiki/log.md
---

# Work Unit Meta

## Goal

- PR 생성 전 위키 증분 업데이트를 필수 가드로 강제
- 이 브랜치의 변경과 검증 결과를 artifact에 지속적으로 누적합니다.

## Scope

- 포함 범위: artifact PR guard, start_work_unit wiki target 기본값, wiki sync guard 정책 문서, README/AGENTS 운영 문구 갱신
- 제외 범위: Codex cron 자동화 구현, 기존 pending artifact 본문 복구, GitHub branch protection 설정 변경

## Acceptance

- PR CI에서 작업 artifact가 wiki_sync_status: synced 상태이고 wiki_targets의 docs/wiki 대상이 PR diff에 포함되지 않으면 실패합니다.
- PR 전 `./scripts/check_artifact_progress.sh`와 `./scripts/check_artifact_guard.sh`를 통과합니다.

## Notes

- PR 전 wiki sync 강제 정책 자체도 같은 PR에서 `docs/wiki/` 문서를 재합성해 반영합니다.
- 동일 wiki 파일을 여러 PR이 수정하는 경우는 Git merge conflict와 최신 base 기준 CI 재검증을 충돌 표면으로 사용합니다.
- 사용자 지시에 따라 PR 없이 main 직접 push로 정책 변경을 반영합니다.
