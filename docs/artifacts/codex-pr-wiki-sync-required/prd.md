# PRD

- work-unit: codex-pr-wiki-sync-required
- branch: codex/pr-wiki-sync-required

## Problem

- PR 생성 전 위키 증분 업데이트를 필수 가드로 강제

## Goal

- PR 생성 전 위키 증분 업데이트를 필수 가드로 강제

## Constraints

- 동일 wiki 파일을 여러 PR이 수정할 때는 Git merge conflict와 최신 base 재검증으로 드러나게 하고, guard는 PR diff 안에 대상 wiki 갱신과 synced 상태가 함께 있는지만 검증합니다.

## Acceptance

- PR CI에서 작업 artifact가 wiki_sync_status: synced 상태이고 wiki_targets의 docs/wiki 대상이 PR diff에 포함되지 않으면 실패합니다.
