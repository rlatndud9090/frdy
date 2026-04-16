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

- `not-started`: scaffold만 만든 초기 상태이며, 진행 중 작업에는 허용하지 않음
- `pending`: 위키 반영이 필요함
- `synced`: 관련 위키 반영이 완료됨

`status`는 작업 자체의 라이프사이클을 나타냅니다.

- `collecting`: scaffold만 생성된 상태. 실제 작업을 시작하기 전까지만 허용
- `in_progress`: 작업 요약, 범위, 수용 기준, 타임라인 초안이 채워진 진행 상태
- `ready-for-pr`: PR 생성 가능
- `in-review`: PR 리뷰 진행 중
- `merged`: main 머지 완료
- `archived`: 후속 추적 종료

## 운영 메모

- 브랜치 작업을 시작할 때는 `./scripts/start_work_unit.sh`로 artifact 초안을 채웁니다.
- `./scripts/check_artifact_progress.sh`는 현재 브랜치 artifact가 껍데기 상태인지 확인합니다.
- PR 전에는 `./scripts/check_artifact_guard.sh`가 파일 존재뿐 아니라 본문 충실도까지 확인합니다.
- `main` push 후에는 `./scripts/check_main_artifact_audit.sh`가 머지된 변경에 artifact가 함께 반영됐는지 감사합니다.
- main 머지 후 위키 갱신 자동화는 `./scripts/check_wiki_sync_guard.sh` 출력을 기반으로 후속 실행할 수 있게 설계합니다.
- 이 자동화는 `status: merged`를 별도 전제조건으로 요구하지 않습니다. `main`에 존재하는 `wiki_sync_status: pending` artifact면 sync 후보입니다.
