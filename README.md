# 마왕의 은밀한 조력 (frdy)

Love2D 기반의 턴 기반 개입형 로그라이트 프로젝트입니다.
플레이어는 마왕으로서 용사 전투 흐름에 주문을 개입시키되,
의심 수치를 관리하면서 런을 진행합니다.

## 핵심 특징

- `MainMenuScene` → `GameScene` → `RunEndScene` 흐름
- `GameScene` 단일 통합 흐름 기반 진행
- 전투 Planning/Execution + 예측 타임라인
- `SpellBook/Spell` 기반 개입 시스템
- `RewardManager` 기반 정산/각성/전설 아이템 루프
- `RunContext` 기반 결정론 RNG 스트림
- 진행 중 런 자동 저장 + 메인 메뉴 `이어하기`
- data-only active save + backup fallback 기반 런 복귀

## 개발 환경

- Love2D 11.x
- LuaJIT 2.1 (Love2D 런타임)
- Lua 5.4+ (스크립트/테스트 실행)

## 실행

```bash
love .
```

## 검증

```bash
./scripts/run_tests.sh
./scripts/check_love.sh
```

- `run_tests.sh`: 단위/통합 테스트 실행
- `check_love.sh`: `FRDY_CI_CHECK=1` 기반 무팝업 실행 검증

## 프로젝트 구조

```text
src/
├── core/      # Game/SceneManager/EventBus/RNG
├── scene/     # MainMenu/GameScene/RunEndScene
├── combat/    # 전투/예측/상태 시스템
├── spell/     # 주문/마나/의심
├── reward/    # 정산/각성/전설
├── map/       # 맵 생성/노드/간선
├── event/     # 이벤트 도메인
├── handler/   # 서브플로우 핸들러
├── ui/        # HUD/오버레이/입력 UI
└── anim/      # 카메라/연출

data/          # 밸런스/콘텐츠 데이터
scripts/       # 검증/체크 스크립트
tests/         # unit/integration 테스트
```

## 주요 문서

- [GAME_CONCEPT.md](GAME_CONCEPT.md): 게임 설계/런타임 흐름(현재 코드 기준)
- [CLASS_DIAGRAM.md](CLASS_DIAGRAM.md): 클래스/시스템 다이어그램
- [AGENTS.md](AGENTS.md): 에이전트 작업 규칙 및 개발 가이드
- [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md): 커밋 규칙
