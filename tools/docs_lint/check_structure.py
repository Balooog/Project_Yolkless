#!/usr/bin/env python3
"""
Minimal DocOps linting for Project Yolkless.

Validates that profile-required documentation and roadmap scaffolding exist.
"""

from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    required_files = [
        "docs/README.md",
        "docs/bootstrap/Discovery_Report.md",
        "docs/bootstrap/Profile.md",
        "docs/bootstrap/Adapters_Applied.md",
        "docs/bootstrap/Clarifications.md",
        "docs/design/Product_Pillars.md",
        "docs/design/UX_Principles.md",
        "docs/design/Modules_Index.md",
        "docs/dev/Session_Kickoff_Checklist.md",
        "docs/dev/CommonErrors.md",
        "docs/quality/Telemetry_Spec.md",
        "docs/quickstarts/gameplay_loop_quickstart.md",
        "docs/quickstarts/telemetry_replay_quickstart.md",
        "docs/ops/Release_Playbook.md",
        "docs/ops/Release_Milestones.md",
        "docs/qa/RM-economy-checklist.md",
        "docs/qa/RM-sandbox-perf-checklist.md",
        "docs/roadmap/PR-000.md",
        "docs/roadmap/ROADMAP_TASKS.md",
        "docs/roadmap/RM/RM-Index.md",
        "docs/templates/RM_Template.md",
    ]

    missing = [path for path in required_files if not (repo_root / path).is_file()]

    rm_dir = repo_root / "docs" / "roadmap" / "RM"
    if not rm_dir.is_dir():
        missing.append("docs/roadmap/RM/ (directory missing)")
    else:
        for rm_path in rm_dir.glob("RM-*.md"):
            stem = rm_path.stem  # e.g. RM-009 or RM-000_docops_bootstrap
            r_code = stem.split("-", 1)[1] if "-" in stem else ""
            code = r_code.split("_", 1)[0] if r_code else ""
            if not code or code == "Index":
                continue
            pr_path = repo_root / "docs" / "roadmap" / f"PR-{code}.md"
            if not pr_path.exists():
                missing.append(f"docs/roadmap/PR-{code}.md (for {rm_path.name})")

    agents_path = repo_root / "AGENTS.md"
    if agents_path.is_file():
        if "v0.2.0" not in agents_path.read_text():
            missing.append("AGENTS.md missing DocOps bootstrap version reference (expected v0.2.0).")
    else:
        missing.append("AGENTS.md")

    if missing:
        for item in missing:
            print(f"[DOC LINT] Missing or outdated: {item}")
        return 1

    print("[DOC LINT] Docs tree structure validated.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
