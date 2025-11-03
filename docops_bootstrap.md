# Cross-Repo DocOps Bootstrap Canvas
> Version v0.2.0 (2025-02-14) — document the version used in AGENTS.md when the bootstrap runs.
### Make Codex discover any repo, select a doc profile, and generate a tailored documentation + automation suite

Codex should parse this canvas and:
1) **Discover** the repository’s tech stack and product shape.
2) **Select or compose a doc profile** (Game/Sim, Mobile App, Desktop Data App, Web/Viz, Utility/CLI) with optional adapters (e.g., Geophysics, Timesheet).
3) **Generate a minimal‑yet‑complete docs tree** with templates, CI hooks, and an agent primer.
4) **Link** everything with a single README and AGENTS.md so contributors (and Codex) can operate from day one.

**Clarify before scaffolding:** When discovery leaves the primary profile, module naming, or roadmap taxonomy ambiguous, ask the maintainer for quick confirmations instead of inventing placeholders.

---

## 0) Inputs & Non‑Goals
**Inputs:** existing repo tree, README (if present), source code, package files.  
**Non‑Goals:** change product code, enforce a specific framework, or replace existing CI beyond adding a docs stage and artifacts.
**Clarifications to request (when missing):** product tagline, release cadence, module abbreviations (PR/RM labels), compliance or domain vocabulary that should seed docs. Log open questions and responses in **`docs/bootstrap/Clarifications.md`** so every run leaves an auditable checklist.

---

## 1) Repo Discovery (auto)
Codex detects:
- **Languages / runtime:** Godot (project.godot), Flutter/Dart (pubspec.yaml), Android (gradle), Python (pyproject/requirements), Node (package.json), .NET (csproj), Excel/VBA (xlsm + VBA/).
- **App shape:** mobile, desktop GUI, web viz, CLI/utility, game/simulation.
- **Test/CI hints:** workflows, test folders, linters.

Codex writes **`docs/bootstrap/Discovery_Report.md`** summarizing findings.
Any ambiguities (e.g., conflicting tech hints or missing roadmap cues) get noted in **`docs/bootstrap/Clarifications.md`** with a status column so maintainers can reply before scaffolding continues.

---

## 2) Doc Profile Selection (auto + composable)
Codex assigns one **primary profile** and optional **adapters**.

Profiles and adapters are sourced from **`docops_profiles.yaml`**, keeping module inventories, quickstart expectations, and folder templates in sync across generators and this canvas. Update that file first when introducing new archetypes.

**Profiles → Core modules**
- **Game/Sim:** Architecture, Signals/Events, Performance Budgets, Telemetry & Replay, UI Principles, Modules briefs, AGENTS.
- **Mobile App:** Build Cookbook (mobile), Release Playbook (stores), UX/Accessibility, Feature flags.
- **Desktop Data App:** Data Schemas, Pipeline/CLI, QA datasets, Performance/Memory budgets.
- **Web/Viz:** API/Adapters, Viz Standards, Dashboard Spec, Caching & Performance.
- **Utility/CLI:** CLI UX, Config schema, Logging, Packaging & Distribution.

**Adapters (optional):** Geophysics (ERI/MASW/Gravity schemas, glossary), Timesheet (Excel/VBA consolidation flow).

Codex writes **`docs/bootstrap/Profile.md`** listing chosen profile + adapters and rationale.

---

## 3) Standard Docs Tree (always; content varies by profile)
```
docs/
  bootstrap/
    Discovery_Report.md
    Profile.md
    Adapters_Applied.md
    Clarifications.md
  architecture/
    Overview.md
    DataFlow_Diagram.md
    Signals_Events.md
    StatBus_or_State_Catalog.md
  design/
    Product_Pillars.md
    UX_Principles.md
    Modules_Index.md
    Balance_or_Data_Playbook.md
  data/
    Schemas.md
    Save_or_Export_Schema.md
  dev/
    Build_Cookbook.md
    Tooling.md
    CommonErrors.md
  quickstarts/
    <primary_flow_quickstart>.md
    <secondary_flow_quickstart>.md
  roadmap/
    PR-000.md
    PR-00X.md
    ROADMAP_TASKS.md
    RM/
      RM-Index.md
      RM-00X_<Module_Slug>.md
  quality/
    Performance_Budgets.md
    Telemetry_Spec.md
    Test_Strategy.md
  qa/
    CI_Pipeline.md
    Checklists.md
  ops/
    Release_Playbook.md
    Bug_and_Feature_Workflow.md
  analysis/
    Competitive_Comparative.md (optional)
  templates/
    PX_Prompt_Template.md
    ADR_Template.md
  images/ (optional, diagrams/screenshots referenced elsewhere)
AGENTS.md
README.md (top section regenerated with DocOps quickstart)
```
`docs/bootstrap/Clarifications.md` starts as a simple two-column table (`Question`, `Resolution`) so Codex and maintainers can track outstanding decisions before and during scaffolding. A starter skeleton lives at **`templates/bootstrap/Clarifications.md`** for copy/paste.

Roadmap files follow MASW Prep naming: `PR-###.md` for Product Requirements at the root and `RM/RM-###_<Slug>.md` for implementation logs (with `RM-Index.md` for navigation). Keep PR ↔ RM numbering aligned and surface shared tasks in `ROADMAP_TASKS.md`.

`docs/quickstarts/` captures two persona-focused guides (e.g., primary + secondary workflow) so contributors can exercise the build immediately; reference them from README and AGENTS.

`docs/dev/CommonErrors.md` tracks recurring pitfalls discovered while building the project—keep it short, actionable, and link back to fixes where possible.

Templates remain under **`docs/templates/`** for PX/ADR scaffolding, and profile-specific folders (game modules, UX/UI, art, etc.) stack on top of this baseline when the selected profile calls for them.

Profile and adapter metadata lives outside the repo tree in **`docops_profiles.yaml`**, enabling generators to stay in sync with this document without manual copy/paste.

---

## 4) CI & Scripts (profile‑aware)
Codex generates or amends lightweight automation:
- **Docs link check** and artifact publish.
- **Docs lint suite** (spelling, style, template freshness) keyed to the generated tree.
- **Lint/test** job if toolchain present.
- **Telemetry/Replay** (game/sim & data apps) or **smoke dataset test** (utilities).
- **Build Cookbook** commands that match the runtime (e.g., Godot CLI, Flutter, Python).

If CI already exists, add a **docs stage** and **artifacts** without breaking current jobs.
Where the repo already ships scripts (e.g., `scripts/check_docs_links.py`), wire them into CI; otherwise scaffold minimal linters under `scripts/docs_lint/`.

---

## 5) Agent Primer (always)
Create **`AGENTS.md`** tailored to the selected profile, including:
- Startup checklist (env vars, how to build/run).
- Default engagement workflow (discover → propose → validate → document).
- Quick links to roadmap anchors (`docs/roadmap/PR-000.md`, `RM-Index.md`) and the primary quickstarts so contributors can jump to the right guides.
- The bootstrap canvas version used (`v0.2.0`) and a link back to `docs/bootstrap/Clarifications.md` so agents know which decisions remain open.
- Guardrails (e.g., don’t mutate schemas without validator; don’t change sim tick).
- A **Compact Commands** index of project‑specific quick actions.

---

## 6) Repo‑Specific Adapters (examples)
**1D ERT Android app (Mobile + Geophysics):** `ERT_Schema.md`, acquisition signals, field logging; Build Cookbook for Flutter/Gradle.  
**Gravity desktop app (Desktop Data + Geophysics):** gravity CSV/SEG schemas, filter pipeline, QA datasets, Telemetry Spec.  
**Home weather viz (Web/Viz):** API adapters, dashboard spec, caching rules, render budgets.  
**Timesheet app (Utility + Timesheet):** timesheet column schemas, consolidator flow, macro security, smoke workbook set.

Codex writes **`docs/bootstrap/Adapters_Applied.md`** listing activated adapters and changes.
Extend adapter work into the roadmap (PR/RM pairs), quickstarts, and domain-specific data docs so the structure mirrors the MASW Prep convention.

---

## 7) PX Seed Prompts (kickoff)
- **PX-000.1 – Clarifications intake** (populate `docs/bootstrap/Clarifications.md` before scaffolding)
- **PX-000.2 – DocOps Bootstrap** (this run)
- **PX-001.1 – Build Cookbook Completion**
- **PX-002.1 – Roadmap PR↔RM scaffolding** (PR-000, task board, RM index/logs)
- **PX-003.1 – Quickstart playbooks & module briefs** (primary + secondary flows)
- **PX-004.1 – CI pipeline & docs lint enablement**

---

## 8) Discovery → Profile Mapping (heuristics)
- Godot → Game/Sim.  
- Flutter/Android → Mobile.  
- Python + Streamlit/Dash/Bokeh → Web/Viz.  
- Python + CLI/Qt → Desktop Data.  
- Excel/VBA present → Utility (+ Timesheet adapter).  
- Geophysics keywords (`.dat`, `R2`, `MASW`, `Bouguer`) → Geophysics adapter.

---

## 9) Acceptance Criteria
1. `docs/bootstrap/Discovery_Report.md`, `Profile.md`, `Adapters_Applied.md`, and `Clarifications.md` exist with accurate detection, rationale, and tracked resolutions for every open question.
2. Baseline docs directories (`architecture`, `design`, `data`, `dev`, `quality`, `qa`, `ops`, `analysis`) are populated with tailored content; `docs/dev/CommonErrors.md` lists actionable pitfalls discovered so far.
3. Roadmap suite delivered: `docs/roadmap/PR-000.md`, module PR files as needed, `docs/roadmap/ROADMAP_TASKS.md`, and `docs/roadmap/RM/RM-Index.md` with aligned PR ↔ RM numbering and implementation logs.
4. `docs/quickstarts/` contains at least two persona or workflow guides, and README/AGENTS reference them directly.
5. `docs/dev/Build_Cookbook.md` commands (and README DocOps quickstart) run for this repo when copy/pasted.
6. CI has a docs stage plus a profile-aligned smoke/test job and a docs lint suite; existing workflows remain green and new scripts are idempotent.
7. `AGENTS.md` includes compact commands, guardrails, the bootstrap canvas version (`v0.2.0` or later), and quick links into the roadmap, quickstarts, and clarifications log.
8. `docops_profiles.yaml` reflects the selected profile/adapters and remains the single source of truth for module inventories.

---

## 10) Commit Message
```
docs: bootstrap profile‑aware documentation, CI, and agent primer via Cross‑Repo DocOps
```

**Outcome:** The repository gains a coherent, automated documentation + CI foundation, tuned to its tech stack, so Codex (and new contributors) can understand, build, test, and extend it with minimal friction.
