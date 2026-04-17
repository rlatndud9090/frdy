# Wiki Sync Automation

`frdy`의 wiki sync는 PR 전 강제보다 `main` 머지 후 후속 처리로 자동화하는 쪽을 기본 전략으로 둡니다.

## 결론

- 추천 방식은 최신 `main`을 확인하는 `frdy-main-wiki-sync` 스킬 또는 이를 호출하는 Codex cron 자동화입니다.
- GitHub Actions는 `artifact -> wiki 재합성` 같은 에이전트형 문서 작업을 수행하기에 적합하지 않습니다.
- 따라서 CI는 guard 역할만 맡고, 실제 wiki sync는 Codex 자동화가 수행합니다.

## 이유

- PR 단계에서 wiki 완료를 강제하면 구현 속도와 리뷰 루프가 불필요하게 느려집니다.
- 반대로 머지 후 자동화는 구현 맥락이 정리된 뒤 `main`에 반영된 `wiki_sync_status: pending` 작업만 골라 처리할 수 있습니다.
- `docs/wiki/`는 현재형 재합성 문서라서, 단순 텍스트 치환보다 에이전트형 판단이 필요합니다.
- 이 전략이 성립하려면 PR 단계에서 artifact completeness guard가 껍데기 artifact 머지를 먼저 차단해야 합니다.

## 권장 흐름

1. 브랜치 작업 시작 시 artifact scaffold 생성
2. 구현/PR/리뷰 루프 진행
3. main 머지 완료 후 artifact가 `main` 트리에 존재하고 `wiki_sync_status: pending`
4. `frdy-main-wiki-sync` 또는 이를 호출하는 Codex 자동화가 `./scripts/check_wiki_sync_guard.sh`로 pending 대상을 확인
5. `docs/wiki/skills/wiki-update.md` 절차로 영향 페이지를 재합성
6. 완료된 work unit의 `wiki_sync_status`를 `synced`로 갱신

## 자동화 요구사항

- 대상 브랜치는 `main`만 사용합니다.
- pending 대상이 없으면 조용히 종료합니다.
- `status`는 참고 정보이며, sync 후보 판정은 `main` 존재 여부 + `wiki_sync_status: pending`을 기준으로 합니다.
- 기본 조회는 `docs/wiki/RESOLVER.md`, `docs/wiki/index.md`부터 시작합니다.
- 관련 artifact만 읽고, 전체 artifact를 전수 스캔하지 않습니다.
- wiki 갱신 후에는 변경 파일과 갱신한 work unit id를 요약으로 남깁니다.

## 기존 자동화와의 역할 분리

- `Daily Autopilot`: issue pick -> 구현 -> PR -> review loop 완료까지 책임
- `주간 코드 변경 감사`: 최근 변경 중 리스크, wiki 미반영, 재미 아이디어를 감사
- `Wiki Sync Automation`: main 머지 후 pending wiki sync 해소

## 보류한 대안

- PR 생성 전 wiki 완료 강제: 구현 흐름을 지나치게 무겁게 만드므로 채택하지 않음
- GitHub Actions에서 wiki 직접 갱신: 에이전트형 재합성과 개인 로컬 문맥 활용이 어려워 채택하지 않음
