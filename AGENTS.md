# Agent Instructions

이 파일은 AI 에이전트가 이 프로젝트에서 작업할 때 따라야 할 규칙과 가이드라인을 정의합니다.

## Git Commit Convention

**필수 준수 사항**: 모든 커밋은 Conventional Commits 규칙을 따라야 합니다.
**개인 프로젝트 규칙**: 외부 트래커 접두어(`#dooray-...`, `JIRA-...`) 없이 Conventional 형식만 사용합니다.

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
- `scripts/check_love.sh`: 무팝업 검증 스크립트

## 개발 가이드라인

### Codex 자동리뷰 언어

- Codex의 자동리뷰 코멘트(리뷰 본문, 인라인 피드백, 요약)는 기본적으로 **한국어**로 작성한다.
- 코드 식별자, 로그, 명령어, 파일 경로 등 기술 문자열은 원문을 유지하고 설명/의견만 한국어로 작성한다.

### UX 절대 원칙

- **자동 확정 금지**: 경로 선택/이벤트 선택/개입 선택에 자동 확정 타이머를 두지 않는다.
- **시간 압박 금지**: 플레이어 입력을 강제하는 카운트다운, 제한시간, 자동 진행 UX를 추가하지 않는다.
- 위 원칙은 이 프로젝트의 **절대적 개발 원칙**으로 유지한다.

### 코드 스타일

- Lua 스타일 가이드 준수
- 들여쓰기: 2 spaces
- 명명 규칙: snake_case (함수, 변수), PascalCase (클래스/모듈)

### LuaLS 타입 어노테이션 (필수)

**모든 Lua 파일에는 LuaLS 타입 어노테이션을 반드시 포함해야 합니다.**

#### 클래스 정의

```lua
---@class ClassName
---@field field_name type
local ClassName = class('ClassName')

-- 상속 시
---@class ChildClass : ParentClass
---@field extra_field type
local ChildClass = class('ChildClass', ParentClass)
```

#### 함수 어노테이션

```lua
---함수 설명
---@param name type
---@param optional_param? type
---@return type
function ClassName:method(name, optional_param)
```

#### 규칙

1. **클래스 선언** 위에 `---@class` 와 `---@field` 추가
2. **모든 함수**에 `---@param`, `---@return` 추가
3. **구체적 타입 사용**: `table` 대신 클래스명 (예: `Node`, `Scene`, `Edge`)
4. **선택적 파라미터**는 `?` 표기 (예: `---@param pos? {x: number, y: number}`)
5. **좌표**는 `{x: number, y: number}` 사용
6. **색상 배열**은 `number[]` 사용
7. **콜백**은 `fun(...)` 또는 `function` 사용

#### 주요 타입 참조

| 타입 | 설명 |
|------|------|
| `Scene` | 씬 기본 클래스 |
| `Node` | 맵 노드 기본 클래스 |
| `CombatNode` | 전투 노드 (Node 서브클래스) |
| `EventNode` | 이벤트 노드 (Node 서브클래스) |
| `Edge` | 노드 간 간선 |
| `Floor` | 맵 층 |
| `Map` | 전체 맵 |
| `UIElement` | UI 기본 클래스 |
| `Button` | 버튼 (UIElement 서브클래스) |
| `Gauge` | 게이지 (UIElement 서브클래스) |
| `Panel` | 패널 (UIElement 서브클래스) |
| `EdgeSelector` | 엣지 선택기 (UIElement 서브클래스) |

### 실행 검증 (필수)

**코드 변경 후 반드시 자동화 테스트 + Love2D 실행 검증을 수행해야 합니다.**

```bash
./scripts/run_tests.sh
```

- Lua 단위/통합 테스트 실행
- **exit code 0** = 정상, 그 외 = 실패

```bash
./scripts/check_love.sh
```

- 내부적으로 `FRDY_CI_CHECK=1 timeout|gtimeout 5 love .`를 실행
- `timeout` 또는 `gtimeout`을 자동 감지해 사용
- 5초 타임아웃(124) + 에러 로그 없음이면 정상으로 간주
- **exit code 0** = 정상
- **에러 출력/비정상 종료** = 실패
- 에러 발생 시 반드시 수정 후 재검증할 것

### 테스트 작성 컨벤션 (필수)

- `src/`, `data/` 하위 Lua 로직 변경 시 `tests/*_test.lua`를 함께 추가/수정한다.
- PR에서는 테스트 누락 시 CI(`scripts/check_test_required.sh`)에서 실패하도록 유지한다.

### 로컬 실행

```bash
love .
```

### 게임 시스템 우선순위

1. **핵심 시스템** (맵, 전투, 카드)
2. **의심 시스템** (게임 핵심 메커니즘)
3. **UI/UX**
4. **밸런싱**
5. **아트/오디오**

---

*이 문서는 AI 에이전트와 개발자 모두를 위한 가이드입니다.*
