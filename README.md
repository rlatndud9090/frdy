# Friday-like Roguelike Deckbuilder

Love2D 기반 로그라이크 덱빌딩 게임

## 게임 컨셉
- 'Friday' 보드게임의 핵심 메커니즘
- 'Slay the Spire' 수준의 깊이와 다양성

## 개발 환경
- Love2D 11.x
- Lua 5.1+

## 실행 방법
```bash
love .
```

## 검증 방법 (팝업 최소화)
```bash
./scripts/check_love.sh
```

- 내부적으로 `FRDY_CI_CHECK=1 timeout 5 love .`를 실행합니다.
- 5초 타임아웃(124) + 출력 없음이면 정상으로 간주합니다.
- 에러/로그가 있으면 stderr로 출력하고 실패 코드로 종료합니다.

## 개발 현황
- [x] 개발 환경 세팅
- [ ] 기본 프로젝트 구조
- [ ] 카드 시스템
- [ ] 전투 시스템
- [ ] 덱 관리 시스템
- [ ] 맵/진행 시스템
