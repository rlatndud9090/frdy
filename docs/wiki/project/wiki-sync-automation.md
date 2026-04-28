# PR Wiki Sync Guard

`frdy`의 wiki sync 기본 정책은 PR 생성 전 증분 업데이트입니다. 작업 branch의 artifact와 영향 wiki 페이지가 같은 PR diff에 함께 들어가야 합니다.

## 결론

- PR CI의 `artifact-required` job이 wiki sync 완료 여부를 함께 검증합니다.
- 작업 artifact의 `wiki_sync_status`는 PR 전에 `synced`여야 합니다.
- `meta.md`의 `wiki_targets`에 적은 `docs/wiki/...` 파일은 같은 PR diff에서 실제로 변경되어야 합니다.
- main 머지 후 pending sync는 기존/예외 작업을 복구하기 위한 안전망이며, 새 작업의 기본 경로가 아닙니다.

## 이유

- 작업 맥락이 가장 풍부한 시점은 PR 생성 직전입니다.
- 코드/테스트 변경과 위키 재합성을 같은 리뷰 단위로 묶으면, 코드만 merge되고 의사결정 히스토리가 뒤늦게 따라오는 상태를 줄일 수 있습니다.
- CI guard는 artifact 존재, artifact 충실도, wiki sync 상태, 영향 wiki 파일 변경 여부를 한 번에 확인합니다.

## PR 전 흐름

1. 브랜치 작업 시작 시 `./scripts/start_work_unit.sh`로 artifact 초안을 채웁니다.
2. 구현/검증/리뷰 메모를 artifact에 누적합니다.
3. 영향 페이지가 확정되면 `wiki_targets`에 실제 `docs/wiki/...` 파일을 채웁니다.
4. `docs/wiki/RESOLVER.md`와 `docs/wiki/skills/wiki-update.md` 절차에 따라 영향 wiki 페이지를 현재형으로 재합성합니다.
5. 작업 artifact의 `wiki_sync_status`를 `synced`로 바꾸고 `updated_at`을 갱신합니다.
6. `./scripts/check_artifact_guard.sh origin/main`을 통과한 뒤 PR을 올립니다.

## 동시 PR 충돌 대비

- 두 PR이 같은 wiki 파일을 수정하면 Git의 일반 병합 규칙을 충돌 표면으로 사용합니다.
- 텍스트 충돌이 발생하면 후발 PR이 최신 `main` 또는 최신 PR base를 반영한 뒤 wiki를 다시 재합성합니다.
- 텍스트 충돌이 없더라도 같은 `wiki_targets`를 건드린 후발 PR은 최신 base 내용을 포함해 다시 확인합니다.
- branch protection 또는 merge queue가 required CI를 최신 base에서 다시 실행하도록 두는 것이 이 정책의 전제입니다.

## 기존 자동화와의 역할 분리

- PR artifact guard: 새 작업의 기본 강제 경로입니다.
- `check_wiki_sync_guard.sh`: main에 남은 `pending` artifact를 찾는 복구/감사 도구입니다.
- 주기적 감사 자동화: 누락된 wiki sync나 stale 문서를 사후 탐지하는 보조 안전망입니다.

## 보류한 대안

- main 머지 후에만 wiki sync 수행: 코드와 의사결정 히스토리가 분리되어 누락 위험이 커지므로 기본 정책에서 제외합니다.
- GitHub Actions에서 LLM 재합성까지 직접 수행: 에이전트형 판단과 로컬 문맥 활용이 필요하므로 CI는 검증만 담당합니다.
