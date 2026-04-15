Issue #66 route judgement

- scope is narrow and documentation-only
- affected surface is one wiki diagram block
- acceptance criteria are explicit from the issue body and current code
- no design replanning or multi-file implementation loop is needed

```json
{
  "kind": "issue_route_judgement",
  "route": "direct-impl",
  "confidence": "high",
  "summary": "문서상 잘못된 UI 상속 화살표 두 줄을 현재 코드 기준으로 정정하는 국소 수정입니다.",
  "reasons": [
    "실제 코드에서 MapOverlay와 SettingsOverlay는 UIElement를 상속하지 않습니다.",
    "위키 다이어그램 한 블록만 수정하면 현재 불일치를 해소할 수 있습니다.",
    "필수 검증 리스크가 낮고 acceptance criteria가 선명합니다."
  ],
  "blocking_unknowns": [
    "이슈 본문이 루트 CLASS_DIAGRAM.md를 지목하지만 현재 워크트리에서는 위키 문서가 실제 수정 대상입니다."
  ],
  "handoff_notes": [
    "PR 범위는 문서와 artifact 상태 유지로 제한합니다.",
    "main 머지 후 wiki_sync_status 후속 갱신 가능성을 artifact에 남깁니다."
  ],
  "signals": {
    "scope_clarity": "high",
    "surface_area": "single-file",
    "verification_risk": "low",
    "design_risk": "low"
  }
}
```
