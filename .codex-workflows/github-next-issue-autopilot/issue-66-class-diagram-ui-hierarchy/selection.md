# Selection

- selected_issue: #66 [Audit][Doc] CLASS_DIAGRAM UI 계층 상속관계 최신화
- repository: rlatndud9090/frdy
- rationale:
  - 활성 PR이 없는 non-Fun 이슈 중 현재 코드/문서 불일치가 가장 명확했습니다.
  - `#59`, `#58`, `#68`, `#60`은 현재 `main`과 테스트 기준으로 stale 가능성이 높아 즉시 착수 가치가 낮았습니다.
  - `#66`은 실제 코드와 위키 다이어그램의 차이가 바로 재현되어 한 PR로 안전하게 수습 가능합니다.
- deferred_candidates:
  - #60: 현재 문서와 스크립트가 headless fallback을 이미 반영해 stale 가능성 높음
  - #68: `main`에 headless fallback 수정 이력이 있어 stale 가능성 높음
- handoff_seed:
  - owner_repo: rlatndud9090/frdy
  - issue_number: 66
  - issue_url: https://github.com/rlatndud9090/frdy/issues/66
  - why_now: 현재 코드 기준 문서 진실을 즉시 복구하는 최소 범위 작업
  - scope_clarity: high
  - likely_surface_area: single-file
  - known_blockers_or_unknowns: issue 본문은 루트 `CLASS_DIAGRAM.md`를 언급하지만 실제 불일치는 위키 다이어그램에 남아 있는지 재확인 필요
  - route_hint: direct-impl 후보
