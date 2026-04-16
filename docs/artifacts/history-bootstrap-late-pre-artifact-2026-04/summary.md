# Late Pre-Artifact History Bootstrap Summary

이 문서는 artifact 체계 도입 직전인 `2026-03-20..2026-04-14` 구간의 `frdy` 구현 이력을 사후 복원한 요약입니다.

## 사용한 근거

- 현재 코드 구조와 현재형 wiki
- 해당 기간 `main` 커밋 로그와 커밋 본문
- 이슈 #71이 수집한 누락 구간 후보와 파일 위치

## 복원된 큰 흐름

### 1. 메인 메뉴, 이어하기, 런 종료 구조 정착

- 2026-03-24에 `MainMenuScene`, `RunEndScene`, 확인 모달, active save JSON/checksum/backup 구조가 함께 들어왔습니다.
- 저장 책임은 `GameScene` 단독 처리에서 `RunSaveCoordinator`와 participant registry 쪽으로 분리되었습니다.
- 이 구간이 현재 메인 메뉴의 `이어하기`, 런 종료 화면, 체크포인트 저장/복원 흐름의 기준선을 만들었습니다.

### 2. 헤드리스 Love 검증 fallback 도입

- 같은 날 `scripts/check_love.sh`에 no-display 상황을 감지해 headless smoke check로 전환하는 fallback이 추가되었습니다.
- 이 변경으로 디스플레이가 없는 자동화 환경에서도 Love 실행 검증을 필수 절차로 유지할 수 있게 되었습니다.

### 3. 층 전환과 패배 종료 흐름 복구

- 2026-03-26과 2026-04-01 사이에 다음 층 전환 체크포인트, 런 종료 정리, `GAME_OVER` 전환 누락이 연속 보수되었습니다.
- 이 시기 수정으로 현재 `GameScene`은 층 전환 대기, 패배 종료, 재시작 입력 경로를 명시 상태 전환으로 처리합니다.

### 4. 이벤트 치사 피해와 의심 최대치 종료 연결

- 2026-04-09에 이벤트 치사 피해와 `suspicion_max` 도달을 공통 런 종료 정리 경로에 연결하는 수정이 들어왔습니다.
- 이 흐름은 전투 밖에서 발생한 종료 사유도 active save 정리와 종료 씬 표시를 일관되게 거치도록 만들었습니다.

### 5. LLM Wiki + artifact 운영 기반 도입

- 2026-04-14에 `docs/wiki/`와 `docs/artifacts/` 2계층 구조, scaffold/guard 스크립트, bootstrap history 복원 체계가 도입되었습니다.
- 이후부터 구현 근거는 work unit artifact에 쌓고, 위키는 그 근거를 바탕으로 현재형으로 재합성하는 운영 기준이 정착했습니다.

## 한계

- 이 artifact 역시 원본 회의록이나 PR 리뷰 스레드 전체를 복원하지는 않습니다.
- 커밋 메시지와 현재 코드로 검증 가능한 구조 변화만 골라 요약했습니다.

## 후속 운영 원칙

- pre-artifact 구간을 참조할 때는 `history-bootstrap-2026-04`와 본 artifact를 함께 읽습니다.
- 2026-04-14 이후의 변화는 개별 work unit artifact를 진실의 원천으로 사용합니다.
