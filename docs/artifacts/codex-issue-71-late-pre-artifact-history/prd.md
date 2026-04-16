# PRD

- work-unit: codex-issue-71-late-pre-artifact-history
- branch: codex/issue-71-late-pre-artifact-history

## Problem

- `docs/wiki/project/implementation-history.md`가 2026-03-19 이후의 핵심 구조 변화를 건너뛰고 있어 현재 런 종료, 저장, 검증, wiki 운영 구조가 어떤 순서로 형성됐는지 설명하지 못합니다.

## Goal

- late pre-artifact 구간을 별도 backfill artifact로 복원합니다.
- 현재형 wiki가 해당 구간의 구조 변화를 요약하도록 갱신합니다.

## Constraints

- 기존 `history-bootstrap-2026-04`의 범위와 의미는 보존합니다.
- 위키는 append-only가 아니라 현재형 재합성 문서로 유지합니다.
- post-artifact 작업 단위와 혼동되지 않게 2026-04-14 이전까지만 다룹니다.

## Acceptance

- 새 backfill artifact에 기간, 핵심 변화, 한계가 기록됩니다.
- `docs/wiki/project/implementation-history.md`가 런 종료/이어하기, headless 검증, 종료 경로 복구, wiki 운영 도입을 별도 구간으로 설명합니다.
- `docs/wiki/log.md`에 이번 backfill 반영이 남습니다.
