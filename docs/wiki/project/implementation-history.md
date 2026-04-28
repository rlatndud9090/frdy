# Implementation History

이 문서는 `frdy`의 현재 구조가 어떤 구현 단계를 거쳐 형성되었는지 요약합니다.

초기 구간은 artifact 체계 도입 이전이라, 현재 코드를 최우선 근거로 하고 git 커밋 로그와 기존 루트 문서를 보조 근거로 사용해 사후 복원했습니다.

## 1. 코어 프레임워크와 맵 생성기 시작

- 2026-02-07에 `Game`, `SceneManager`, `EventBus`가 들어오며 런타임 뼈대가 만들어졌습니다.
- 같은 시기에 `Node`/`Edge` 기반 절차적 맵 생성기가 들어와 로그라이트의 공간 구조가 잡혔습니다.

## 2. GameScene 통합 구조로 수렴

- 초기에 분리됐던 Scene 구조는 2026-02-09 전후 `GameScene + phase state machine`으로 합쳐졌습니다.
- 현재 `GameScene`이 시작 노드 선택, 이동, 전투, 이벤트, 정산, 경로 선택까지 통합 관리하는 이유가 여기서 결정됐습니다.

## 3. Deck/Card에서 SpellBook/Spell로 전환

- 2026-02-12에 덱/드로우 모델이 폐기되고 `SpellBook/Spell` 중심 구조로 바뀌었습니다.
- 이 전환으로 플레이어 경험은 “카드를 뽑아 전개”하는 방식보다 “항상 사용 가능한 개입 수단 중 무엇을 언제 쓰느냐”에 더 집중하게 됐습니다.

## 4. 예측 타임라인 전투의 형성

- 2026-02-13에 Planning/Execution 2페이즈, `PredictionEngine`, `TimelineManager`, `PredictedAction`, `TimelineUI`가 집중적으로 들어왔습니다.
- 이후 삽입형, 조작형, 대상 선택형, 전체 대상형 스펠이 확장되며 현재의 개입형 전투 구조가 완성됐습니다.

## 5. 맵 UX와 시작 노드 선택 안정화

- 2026-02-14 ~ 2026-02-15에 STS형 맵 배치, 시작 노드 선택, 드래그 이동, 맵 오버레이 포커스가 다듬어졌습니다.
- 이 시기 변경으로 현재의 `Minimap + MapOverlay + StartNodeSelect` 흐름이 자리잡았습니다.

## 6. 대상 규칙, 상태 훅, 정신 조종 확장

- 2026-02-25 이후 대상 선택, 속도 개입, 정신 조종 기반 선택 개입, 상태 훅 컨테이너가 추가됐습니다.
- 2026-03-19에는 전체 대상 스펠과 타깃 규칙 정리가 반영되어 현재의 타깃 체계 기준선이 완성됐습니다.

## 7. 보상/성장 루프와 결정론 RNG

- 2026-03-02에 정산 기반 보상 시스템, `RewardManager`, `DemonAwakening`, `LegendaryInventory`, 자동화 테스트가 추가됐습니다.
- 2026-03-04에 `RunContext` 기반 결정론 RNG가 들어오며 런 전체를 시드 재현 가능한 구조로 정리했습니다.

## 8. 메인 메뉴, 이어하기, 런 종료 구조 정착

- 2026-03-24에 `MainMenuScene`, `RunEndScene`, 확인 모달, active save JSON/checksum/backup 구조가 함께 들어왔습니다.
- 저장 책임은 `GameScene`에서 `RunSaveCoordinator`와 participant registry 계층으로 분리되었고, 현재의 `이어하기`와 종료 화면 경험이 이 시점에 자리잡았습니다.

## 9. 헤드리스 Love 검증 fallback 도입

- 같은 날 `scripts/check_love.sh`에 no-display 환경 감지와 headless smoke check fallback이 추가됐습니다.
- 이 변경으로 현재의 자동 검증 절차는 GUI가 없는 환경에서도 Love 실행 검증을 유지할 수 있게 되었습니다.

## 10. 층 전환과 패배 종료 흐름 복구

- 2026-03-26과 2026-04-01에 런 종료 정리, 다음 층 체크포인트, `GAME_OVER` 전환 누락이 연속 보수되었습니다.
- 현재 `GameScene`이 층 전환 대기, 패배 종료, 재시작 입력 흐름을 명시 상태 전환으로 다루는 이유가 이 시기 수정에서 고정됐습니다.

## 11. 이벤트 치사 피해와 의심 최대치 종료 연결

- 2026-04-09에 이벤트 치사 피해와 `suspicion_max` 도달이 공통 런 종료 정리 경로에 연결되었습니다.
- 이 흐름으로 전투 밖 종료 사유도 active save 정리와 종료 사유 표시를 일관되게 거치도록 맞춰졌습니다.
- 2026-04-15에는 `GameScene`의 `suspicion_max` 이벤트 구독/해제 생명주기가 보강되어, 씬 교체 뒤 종료 이벤트가 중복 처리되지 않도록 정리됐습니다.
- 같은 날 UI 계층 위키에서 `MapOverlay`와 `SettingsOverlay`가 `UIElement` 상속 위젯이 아니라 `GameScene` composition overlay라는 점도 현재 코드 기준으로 정정됐습니다.

## 12. LLM Wiki와 artifact 운영 기반 도입

- 2026-04-14에 `docs/wiki/`와 `docs/artifacts/` 저장 영역, scaffold/guard 스크립트, pre-artifact bootstrap 복원 체계가 도입되었습니다.
- 현재 운영 표현은 raw/artifacts, wiki, schema/rules 3계층이며, work unit artifact를 근거층으로 쌓고 LLM이 위키를 그 근거로 재합성하는 규칙을 기본 규약으로 둡니다.

## 해석 규칙

- 이 문서는 “현재 구조가 왜 이렇게 생겼는가”를 설명하는 현재형 요약입니다.
- 세부 근거가 더 필요하면 `docs/artifacts/history-bootstrap-2026-04/`와 `docs/artifacts/history-bootstrap-late-pre-artifact-2026-04/`를 먼저 보고, 이후 작업은 개별 work unit artifact를 참조합니다.
