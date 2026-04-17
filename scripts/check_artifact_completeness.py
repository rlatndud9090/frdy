#!/usr/bin/env python3
"""Validate FRDY work-unit artifacts beyond scaffold existence."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ALLOWED_STATUS = {
    "collecting",
    "in_progress",
    "ready-for-pr",
    "in-review",
    "merged",
    "archived",
}
ALLOWED_WIKI_STATUS = {"not-started", "pending", "synced"}
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
TIMELINE_ENTRY_RE = re.compile(r"^- 20\d{2}-\d{2}-\d{2} \d{2}:\d{2} \| .+\S$")
FRONTMATTER_PLACEHOLDERS = {
    "id": "<work-unit-id>",
    "branch": "<branch-name>",
    "created_at": "YYYY-MM-DD",
    "updated_at": "YYYY-MM-DD",
}
PLACEHOLDER_LINE_PATTERNS = (
    (re.compile(r"^(?:-\s*)?이 작업 단위의 목표를 1~3줄로 적습니다\.$"), "이 작업 단위의 목표를 1~3줄로 적습니다."),
    (re.compile(r"^(?:-\s*)?완료 기준:$"), "완료 기준:"),
    (
        re.compile(r"^(?:-\s*)?아티팩트 수집 규칙, 주의사항, 후속 결정 메모를 남깁니다\.$"),
        "아티팩트 수집 규칙, 주의사항, 후속 결정 메모를 남깁니다.",
    ),
    (re.compile(r"^- YYYY-MM-DD HH:MM \| .+$"), "YYYY-MM-DD HH:MM"),
)
META_BODY_SECTIONS = ("Goal", "Scope", "Acceptance", "Notes")
PRD_SECTIONS = ("Problem", "Goal", "Constraints", "Acceptance")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate FRDY artifact completeness.")
    parser.add_argument("--artifact-dir", required=True)
    parser.add_argument(
        "--mode",
        choices=("progress", "pr", "main-audit"),
        required=True,
    )
    parser.add_argument("--expected-id")
    parser.add_argument("--expected-branch")
    return parser.parse_args()


def load_text(path: Path) -> str:
    if not path.is_file():
        raise FileNotFoundError(str(path))
    return path.read_text(encoding="utf-8")


def parse_frontmatter(text: str) -> tuple[dict[str, object], str]:
    lines = text.splitlines()
    if len(lines) < 3 or lines[0].strip() != "---":
        raise ValueError("frontmatter 시작 구분자(---)를 찾지 못했습니다.")

    try:
        end_index = lines[1:].index("---") + 1
    except ValueError as exc:
        raise ValueError("frontmatter 종료 구분자(---)를 찾지 못했습니다.") from exc

    data: dict[str, object] = {}
    current_list_key: str | None = None

    for raw_line in lines[1:end_index]:
        line = raw_line.rstrip()
        stripped = line.strip()
        if not stripped:
            continue
        if line.startswith("  - "):
            if current_list_key is None:
                raise ValueError(f"리스트 항목이 키 없이 나타났습니다: {line}")
            data.setdefault(current_list_key, [])
            assert isinstance(data[current_list_key], list)
            data[current_list_key].append(line[4:].strip())
            continue
        if ":" not in line:
            raise ValueError(f"frontmatter 파싱에 실패했습니다: {line}")
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "":
            if key == "wiki_targets":
                data[key] = []
                current_list_key = key
                continue
            data[key] = ""
            current_list_key = None
        else:
            data[key] = value
            current_list_key = None

    body = "\n".join(lines[end_index + 1 :]).strip()
    return data, body


def parse_sections(text: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current: str | None = None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        if line.startswith("## "):
            current = line[3:].strip()
            sections.setdefault(current, [])
            continue
        if current is not None:
            sections[current].append(line)

    return sections


def compact_lines(lines: list[str]) -> list[str]:
    return [line.strip() for line in lines if line.strip()]


def section_text(lines: list[str]) -> str:
    return " ".join(compact_lines(lines))


def require_prefixed_value(
    lines: list[str],
    *,
    prefix: str,
    label: str,
    errors: list[str],
) -> None:
    for raw_line in compact_lines(lines):
        normalized = raw_line
        if normalized.startswith("- "):
            normalized = normalized[2:].strip()
        if not normalized.startswith(prefix):
            continue
        value = normalized[len(prefix) :].strip()
        if value:
            return
        errors.append(f"{label}에 `{prefix}` 뒤 실제 내용이 있어야 합니다.")
        return
    errors.append(f"{label}에 `{prefix}` 항목이 없습니다.")


def validate_no_placeholders(text: str, label: str, errors: list[str]) -> None:
    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        for pattern, snippet in PLACEHOLDER_LINE_PATTERNS:
            if pattern.fullmatch(stripped):
                errors.append(f"{label}에 템플릿 플레이스홀더가 남아 있습니다: {snippet}")


def validate_frontmatter(
    data: dict[str, object],
    *,
    expected_id: str | None,
    expected_branch: str | None,
    mode: str,
    errors: list[str],
) -> None:
    artifact_id = str(data.get("id", "")).strip()
    branch = str(data.get("branch", "")).strip()
    status = str(data.get("status", "")).strip()
    wiki_status = str(data.get("wiki_sync_status", "")).strip()
    created_at = str(data.get("created_at", "")).strip()
    updated_at = str(data.get("updated_at", "")).strip()
    related_pr = str(data.get("related_pr", "")).strip()

    for key, snippet in FRONTMATTER_PLACEHOLDERS.items():
        value = str(data.get(key, "")).strip()
        if value == snippet:
            errors.append(f"meta.md의 {key}에 템플릿 플레이스홀더가 남아 있습니다: {snippet}")

    if expected_id and artifact_id != expected_id:
        errors.append(f"meta.md의 id가 예상값과 다릅니다. expected={expected_id}, actual={artifact_id}")
    if expected_branch and branch != expected_branch:
        errors.append(f"meta.md의 branch가 예상값과 다릅니다. expected={expected_branch}, actual={branch}")
    if not artifact_id:
        errors.append("meta.md의 id가 비어 있습니다.")
    if not branch:
        errors.append("meta.md의 branch가 비어 있습니다.")
    if status not in ALLOWED_STATUS:
        errors.append(f"meta.md의 status가 허용값이 아닙니다: {status}")
    if wiki_status not in ALLOWED_WIKI_STATUS:
        errors.append(f"meta.md의 wiki_sync_status가 허용값이 아닙니다: {wiki_status}")
    if not DATE_RE.match(created_at):
        errors.append(f"meta.md의 created_at 형식이 올바르지 않습니다: {created_at}")
    if not DATE_RE.match(updated_at):
        errors.append(f"meta.md의 updated_at 형식이 올바르지 않습니다: {updated_at}")

    if mode in {"progress", "pr"} and status == "collecting":
        errors.append("scaffold만 만든 collecting 상태로는 작업을 진행할 수 없습니다.")
    if mode in {"progress", "pr"} and wiki_status == "not-started":
        errors.append("작업 중 artifact는 wiki_sync_status: pending 또는 synced 여야 합니다.")
    if mode == "pr" and status == "in-review" and not related_pr:
        errors.append("status가 in-review이면 related_pr를 채워야 합니다.")
    if mode == "pr" and status not in {"in_progress", "ready-for-pr", "in-review"}:
        errors.append(f"PR 검증 시 status는 in_progress/ready-for-pr/in-review 중 하나여야 합니다: {status}")


def validate_markdown_sections(
    body: str,
    *,
    required_sections: tuple[str, ...],
    label: str,
    mode: str,
    errors: list[str],
) -> None:
    sections = parse_sections(body)
    for section in required_sections:
        if section not in sections:
            errors.append(f"{label}에 필수 섹션이 없습니다: {section}")
            continue
        text = section_text(sections[section])
        if len(text) < 12:
            errors.append(f"{label}의 {section} 섹션 내용이 너무 짧거나 비어 있습니다.")

    if label == "meta.md 본문" and mode == "pr":
        scope_lines = sections.get("Scope", [])
        require_prefixed_value(scope_lines, prefix="포함 범위:", label="meta.md의 Scope 섹션", errors=errors)
        require_prefixed_value(scope_lines, prefix="제외 범위:", label="meta.md의 Scope 섹션", errors=errors)


def validate_timeline(text: str, *, mode: str, errors: list[str]) -> None:
    validate_no_placeholders(text, "timeline.md", errors)
    entries = [line.strip() for line in text.splitlines() if TIMELINE_ENTRY_RE.match(line.strip())]
    if not entries:
        errors.append("timeline.md에 실제 타임라인 항목이 없습니다.")
        return
    if mode == "pr" and len(entries) < 2:
        errors.append("PR 검증 전에는 timeline.md에 최소 2개 이상의 실제 진행 기록이 필요합니다.")


def main() -> int:
    args = parse_args()
    artifact_dir = Path(args.artifact_dir).resolve()
    errors: list[str] = []

    meta_path = artifact_dir / "meta.md"
    prd_path = artifact_dir / "prd.md"
    timeline_path = artifact_dir / "timeline.md"

    for required_path in (meta_path, prd_path, timeline_path):
        if not required_path.is_file():
            errors.append(f"필수 파일이 없습니다: {required_path}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    meta_text = load_text(meta_path)
    prd_text = load_text(prd_path)
    timeline_text = load_text(timeline_path)

    validate_no_placeholders(meta_text, "meta.md", errors)
    validate_no_placeholders(prd_text, "prd.md", errors)

    meta_frontmatter, meta_body = parse_frontmatter(meta_text)
    validate_frontmatter(
        meta_frontmatter,
        expected_id=args.expected_id,
        expected_branch=args.expected_branch,
        mode=args.mode,
        errors=errors,
    )
    validate_markdown_sections(
        meta_body,
        required_sections=META_BODY_SECTIONS,
        label="meta.md 본문",
        mode=args.mode,
        errors=errors,
    )
    validate_markdown_sections(
        prd_text,
        required_sections=PRD_SECTIONS,
        label="prd.md",
        mode=args.mode,
        errors=errors,
    )
    validate_timeline(timeline_text, mode=args.mode, errors=errors)

    if errors:
        print("artifact completeness 검증 실패:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"artifact completeness 통과: {artifact_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
