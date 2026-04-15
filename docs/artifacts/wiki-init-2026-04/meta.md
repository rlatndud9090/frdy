---
id: wiki-init-2026-04
branch: main
status: merged
wiki_sync_status: synced
created_at: 2026-04-14
updated_at: 2026-04-14
related_issue:
related_pr:
merge_commit:
wiki_targets:
  - docs/wiki/SCHEMA.md
  - docs/wiki/RESOLVER.md
  - docs/wiki/index.md
  - docs/wiki/project/overview.md
  - docs/wiki/project/implementation-history.md
  - docs/wiki/systems/runtime-architecture.md
  - docs/wiki/systems/class-architecture.md
---

# Work Unit Meta

## Goal

- `frdy`에 LLM Wiki + artifact 운영 구조를 도입합니다.
- 기존 루트 설계 문서를 wiki로 통합 이관하고, guard script/CI/운영 규칙을 정비합니다.

## Scope

- 포함 범위: wiki/artifact 디렉터리 신설, 루트 문서 포인터화, guard script/CI 추가, 초기 히스토리 부트스트랩
- 제외 범위: 별도 서버형 wiki sync 파이프라인 구축

## Acceptance

- `docs/wiki/`와 `docs/artifacts/`를 기준으로 운영할 수 있어야 합니다.
- 새 작업부터 branch/work unit artifact 누적이 가능해야 합니다.
- 위키 초기 상태가 현재 코드 기준으로 읽을 만한 수준까지 채워져 있어야 합니다.

## Notes

- 이 work unit은 bootstrap 성격의 main 직접 반영 작업입니다.
- 외부 Codex skill/automation 조정은 로컬 환경에서 함께 적용했지만, 저장소 커밋 범위는 `frdy` 내부 파일로 제한합니다.
