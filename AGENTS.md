# Agent Instructions

이 파일은 AI 에이전트가 이 프로젝트에서 작업할 때 따라야 할 규칙과 가이드라인을 정의합니다.

## Git Commit Convention

**필수 준수 사항**: 모든 커밋은 Conventional Commits 규칙을 따라야 합니다.

### 커밋 메시지 형식

```
<type>(<scope>): <subject>

[본문 - 선택사항]
```

### Type (필수)

- `feat`: 새 기능 추가
- `fix`: 버그 수정
- `art`: 아트/그래픽 작업
- `audio`: 사운드/음악 작업
- `balance`: 게임 밸런스 조정
- `ui`: UI/UX 변경
- `refactor`: 코드 리팩토링
- `test`: 테스트 추가/수정
- `docs`: 문서 작업
- `chore`: 기타 작업

### Scope (선택사항)

- `combat`: 전투 시스템
- `map`: 맵/노드 시스템
- `card`: 카드 시스템
- `hero`: 용사
- `enemy`: 적
- `event`: 이벤트
- `suspicion`: 의심 시스템
- `ui`: UI 요소
- `core`: 핵심 엔진

### Subject 작성 규칙

1. **50자 이내**로 작성
2. **명령형**으로 작성 (예: "추가" ⭕, "추가함" ❌)
3. **한글** 사용
4. 마침표 없음

### 커밋 예시

✅ **좋은 예시**:
```
feat(combat): 턴제 전투 시스템 구현
fix(suspicion): 의심 수치 계산 오류 수정
balance(card): 마왕 카드 마력 소모량 조정
art: 용사 스프라이트 추가
```

❌ **나쁜 예시**:
```
update: 코드 수정
fix bug
feat: 기능 추가했습니다.
```

### AI 커밋 생성 프로세스

1. 변경사항 분석 (`git diff`, `git status`)
2. 적절한 `type` 선택
3. 해당하는 `scope` 있으면 추가
4. 명확한 `subject` 작성 (50자 이내, 명령형, 한글)
5. 복잡한 변경사항은 본문에 상세 설명 추가

## 프로젝트 구조

- `main.lua`: Love2D 진입점
- `GAME_CONCEPT.md`: 게임 설계 문서
- `COMMIT_CONVENTION.md`: 커밋 컨벤션 상세 문서
- `.gitmessage`: Git 커밋 템플릿

## 개발 가이드라인

### 코드 스타일

- Lua 스타일 가이드 준수
- 들여쓰기: 2 spaces
- 명명 규칙: snake_case (함수, 변수), PascalCase (클래스/모듈)

### 게임 시스템 우선순위

1. **핵심 시스템** (맵, 전투, 카드)
2. **의심 시스템** (게임 핵심 메커니즘)
3. **UI/UX**
4. **밸런싱**
5. **아트/오디오**

---

*이 문서는 AI 에이전트와 개발자 모두를 위한 가이드입니다.*
