# Friday-like Roguelike Deckbuilder

Love2D 기반 로그라이크 덱빌딩 게임

## 게임 컨셉
- 'Friday' 보드게임의 핵심 메커니즘
- 'Slay the Spire' 수준의 깊이와 다양성

## 개발 환경
- Love2D 11.x
- LuaJIT 2.1 (Love2D 런타임)
- Lua 5.4+ (도구/스크립트 실행용)

## 실행 방법
```bash
love .
```

## 검증 방법 (팝업 최소화)
```bash
./scripts/check_love.sh
```

- 내부적으로 `FRDY_CI_CHECK=1 timeout|gtimeout 5 love .`를 실행합니다.
- `timeout` 또는 `gtimeout`을 자동 감지해 사용합니다.
- 5초 타임아웃(124) + 에러 로그 없음이면 정상으로 간주합니다.
- 에러/로그가 있으면 stderr로 출력하고 실패 코드로 종료합니다.

## 자동화 테스트
```bash
./scripts/run_tests.sh
```

- Lua 단위/통합 테스트를 실행합니다.
- 테스트 실패 시 non-zero 코드로 종료합니다.
- CI(`.github/workflows/ci.yml`)에서 자동 실행됩니다.

## 개발 현황
- [x] 개발 환경 세팅
- [x] 기본 프로젝트 구조
- [x] 맵/진행 시스템 프로토타입
- [x] 전투/행동 시스템 프로토타입
- [x] 이벤트/국제화(i18n) 기반 UI
- [ ] 카드/덱 콘텐츠 확장 및 밸런싱
