# Wiki Query Skill

`frdy`에서 설계/맥락/규칙을 물을 때의 기본 조회 절차입니다.

## 조회 순서

1. `docs/wiki/RESOLVER.md`
2. `docs/wiki/index.md`
3. 관련 위키 페이지
4. 필요한 경우에만 관련 `docs/artifacts/<work-unit-id>/`
5. 코드/테스트/깃 이력

## 규칙

- 기본 RAG는 항상 `docs/wiki/`를 우선합니다.
- `docs/artifacts/`는 기본 검색 대상이 아닙니다.
- 아래 상황에서만 artifacts를 엽니다.
  - 위키가 비어 있거나 낡았을 때
  - 위키와 코드가 충돌할 때
  - 특정 결정의 근거가 필요할 때
  - 위키 갱신 작업을 수행할 때

## 답변 원칙

- 현재형 설명은 위키 기준으로 답합니다.
- 근거가 필요하면 artifact 경로를 함께 제시합니다.
- 위키가 비어 있거나 낡았으면 그 사실을 명시합니다.
