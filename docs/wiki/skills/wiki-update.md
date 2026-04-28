# Wiki Update Skill

`frdy`에서 artifact를 바탕으로 wiki를 갱신할 때 따르는 절차입니다.

## 목표

- `docs/artifacts/<work-unit-id>/`에 쌓인 근거를 읽고
- 관련 `docs/wiki/` 페이지를 현재형으로 재합성하고
- `meta.md`의 `wiki_sync_status`를 갱신합니다.

## 입력

- 대상 work unit id 1개 이상
- 또는 `wiki_sync_status: pending` 인 작업 단위 전부

## 절차

1. `docs/wiki/RESOLVER.md`와 `docs/wiki/index.md`를 읽습니다.
2. 대상 artifact의 `meta.md`, `timeline.md`, PRD, ADR, 회의록, 실험 로그를 읽습니다.
3. `meta.md`의 `wiki_targets`를 우선 사용합니다.
4. 영향받은 wiki 페이지를 골라 현재형으로 재서술합니다.
5. 필요하면 `docs/wiki/index.md`와 `docs/wiki/log.md`도 갱신합니다.
6. 갱신이 끝나면 `wiki_sync_status: synced`로 바꿉니다.
7. PR 전 `./scripts/check_artifact_guard.sh origin/main`을 실행해 `wiki_targets`의 위키 파일이 같은 PR diff에 포함되는지 확인합니다.

## 강한 규칙

- wiki 수정은 LLM만 수행합니다. 사람은 직접 wiki 본문을 고치지 않고 LLM에게 재합성을 요청합니다.
- artifacts를 그대로 복붙하지 않습니다.
- artifacts는 수정하지 않고 쌓아나가는 raw data로 취급합니다. 정정은 새 기록으로 남깁니다.
- AI 대화 로그의 미검증 결론은 위키에 바로 승격하지 않습니다.
- 위키는 append-only가 아니라 현재형 재합성 문서입니다.
- 전면 재작성보다 `영향 페이지 단위 재합성`을 기본으로 합니다.

## PR 전 운영 원칙

- PR 생성 전 작업 artifact는 `wiki_sync_status: synced`여야 합니다.
- `wiki_targets`에 적은 `docs/wiki/...` 파일은 같은 PR diff에서 실제로 변경되어야 합니다.
- 같은 wiki 파일을 여러 PR이 수정하는 경우, 후발 PR은 최신 base의 위키 내용을 포함해 다시 재합성한 뒤 guard를 통과시킵니다.
- main 트리에 남은 `wiki_sync_status: pending` artifact는 기존/예외 작업 복구용 후보입니다.
