# Legacy Plan: Korean Text Rendering + i18n

이 문서는 과거 i18n 도입 당시의 작업 계획 기록을 보관합니다.
현재 코드 상태와 일부 표현은 다를 수 있으며, 최신 설계의 진실의 원천은 아닙니다.

## 당시 문제 정의

- Love2D 기본 폰트는 한글 글리프를 지원하지 않음
- 한국어 UI 문자열이 런타임에서 깨짐
- 하드코딩된 문자열이 소스 전반에 분산되어 있었음
- i18n 인프라가 없었음

## 당시 해결 전략

1. 한국어 지원 폰트 도입
2. i18n 모듈 구축
3. UI 문자열을 영어 기본 + 한국어 보조 구조로 재편
4. 설정 오버레이에 언어 선택 추가

## 현재 위치

- 이 문서는 역사 보관본입니다.
- 현재형 구조 설명은 아래 문서를 우선합니다.
  - [../project/overview.md](../project/overview.md)
  - [../systems/runtime-architecture.md](../systems/runtime-architecture.md)
