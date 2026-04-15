# Artifacts

이 디렉터리는 `frdy`의 작업 단위별 아티팩트를 보관하는 진실의 원천입니다.

## 원칙

- 아티팩트는 작업 단위별로 보관합니다.
- 기본 작업 단위는 브랜치이지만, 실제 폴더명은 브랜치명을 정규화한 `work-unit id`를 사용합니다.
- 아티팩트는 append-only 성격을 우선합니다.
- 회의록, AI 대화 기록, PRD, ADR, 실험 로그, 리뷰 메모는 모두 이 계층에 쌓습니다.
- 에이전트는 기본 RAG에서 이 디렉터리를 뒤지지 않습니다.
- 위키 갱신, 근거 확인, 모순 해소가 필요할 때만 이 계층으로 내려갑니다.

## 기본 구조

```text
docs/artifacts/
├── _template/
└── <work-unit-id>/
    ├── meta.md
    ├── timeline.md
    ├── prd.md
    ├── adr/
    ├── meetings/
    ├── ai-sessions/
    ├── experiments/
    └── review-notes/
```

## 상태 규칙

`meta.md` frontmatter의 `wiki_sync_status`를 기준으로 후속 작업을 추적합니다.

- `not-started`: 작업 중이며 아직 위키 갱신 판단 전
- `pending`: 위키 반영이 필요함
- `synced`: 관련 위키 반영이 완료됨

`status`는 작업 자체의 라이프사이클을 나타냅니다.

- `collecting`: 아티팩트 수집 중
- `ready-for-pr`: PR 생성 가능
- `in-review`: PR 리뷰 진행 중
- `merged`: main 머지 완료
- `archived`: 후속 추적 종료

## 운영 메모

- 브랜치 작업을 시작할 때 `./scripts/ensure_artifact_scaffold.sh`로 스캐폴드를 만듭니다.
- PR 전에는 `./scripts/check_artifact_guard.sh`가 최소 요건을 확인합니다.
- main 머지 후 위키 갱신 자동화는 `./scripts/check_wiki_sync_guard.sh` 출력을 기반으로 후속 실행할 수 있게 설계합니다.
- 이 자동화는 `status: merged`를 별도 전제조건으로 요구하지 않습니다. `main`에 존재하는 `wiki_sync_status: pending` artifact면 sync 후보입니다.
