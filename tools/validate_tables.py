#!/usr/bin/env python3
"""
Lightweight TSV validator for Yolkless upgrade/research data.

Checks column headers, empty cells, id/tier uniqueness, and dependency cycles.
Writes validation output to logs/validation/YYYYMMDD.log and exits non-zero on failure.
"""

import argparse
import collections
import datetime
import pathlib
import sys
from typing import Dict, List, Set, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate TSV tables against basic schema rules.")
    parser.add_argument(
        "--tables",
        required=True,
        help="Comma-separated list of TSV files (relative paths).",
    )
    parser.add_argument(
        "--schema",
        required=False,
        help="Optional reference doc path for logging context.",
    )
    return parser.parse_args()


def load_tsv(path: pathlib.Path) -> Tuple[List[str], List[Dict[str, str]]]:
    rows: List[Dict[str, str]] = []
    text = path.read_text(encoding="utf-8").strip().splitlines()
    headers = [h.strip() for h in text[0].split("\t")]
    for line in text[1:]:
        if not line or line.startswith("#"):
            continue
        values = [v.strip() for v in line.split("\t")]
        # Pad missing columns
        if len(values) < len(headers):
            values += [""] * (len(headers) - len(values))
        rows.append(dict(zip(headers, values)))
    return headers, rows


def check_headers(headers: List[str]) -> List[str]:
    errors: List[str] = []
    header_set = set()
    for header in headers:
        if header == "":
            errors.append("Empty header detected.")
        if header in header_set:
            errors.append(f"Duplicate header '{header}'.")
        header_set.add(header)
    return errors


def check_empty_cells(rows: List[Dict[str, str]], critical_fields: Set[str]) -> List[str]:
    errors: List[str] = []
    for idx, row in enumerate(rows):
        for field in critical_fields:
            if field in row and row[field] == "":
                errors.append(f"Row {idx + 2}: field '{field}' is empty.")
    return errors


def check_unique(rows: List[Dict[str, str]], key_fields: Tuple[str, ...]) -> List[str]:
    errors: List[str] = []
    seen: Set[Tuple[str, ...]] = set()
    for idx, row in enumerate(rows):
        key = tuple(row.get(field, "") for field in key_fields)
        if key in seen:
            errors.append(f"Row {idx + 2}: duplicate key {key}.")
        seen.add(key)
    return errors


def build_dependency_graph(rows: List[Dict[str, str]], id_field: str, requires_field: str) -> Dict[str, Set[str]]:
    graph: Dict[str, Set[str]] = collections.defaultdict(set)
    for row in rows:
        node = row.get(id_field, "")
        if not node:
            continue
        requires = row.get(requires_field, "")
        if not requires or requires == "-":
            continue
        for dep in requires.split(","):
            dep = dep.strip()
            if dep:
                graph[node].add(dep)
    return graph


def detect_cycle(graph: Dict[str, Set[str]]) -> Tuple[bool, List[str]]:
    visited: Set[str] = set()
    temp: Set[str] = set()
    path: List[str] = []

    def visit(node: str) -> bool:
        if node in temp:
            path.append(node)
            return True
        if node in visited:
            return False
        temp.add(node)
        for dep in graph.get(node, []):
            if visit(dep):
                path.append(node)
                return True
        temp.remove(node)
        visited.add(node)
        return False

    for start in graph:
        if visit(start):
            path.reverse()
            return True, path
    return False, []


def validate_environment_profiles(headers: List[str], rows: List[Dict[str, str]]) -> List[str]:
    errors: List[str] = []
    required_columns = {
        "profile_id",
        "label",
        "daylen",
        "temp_min",
        "temp_max",
        "humidity_mean",
        "humidity_swing",
        "light_mean",
        "light_swing",
        "air_mean",
        "air_swing",
        "wind_mean",
        "theme",
        "tier_min",
    }
    missing = required_columns.difference(headers)
    if missing:
        errors.append("missing columns: %s" % ", ".join(sorted(missing)))
        return errors

    previous_tier = -1
    for idx, row in enumerate(rows):
        row_num = idx + 2
        try:
            temp_min = float(row.get("temp_min", "0"))
            temp_max = float(row.get("temp_max", "0"))
        except ValueError:
            errors.append(f"Row {row_num}: temp_min/temp_max must be numeric")
            continue
        if not 0.0 <= temp_min <= 1.0:
            errors.append(f"Row {row_num}: temp_min {temp_min} outside 0-1 range")
        if not 0.0 <= temp_max <= 1.0:
            errors.append(f"Row {row_num}: temp_max {temp_max} outside 0-1 range")
        if temp_min > temp_max:
            errors.append(f"Row {row_num}: temp_min {temp_min} exceeds temp_max {temp_max}")

        for field in [
            "humidity_mean",
            "humidity_swing",
            "light_mean",
            "light_swing",
            "air_mean",
            "air_swing",
            "wind_mean",
        ]:
            try:
                value = float(row.get(field, "0"))
            except ValueError:
                errors.append(f"Row {row_num}: {field} must be numeric")
                continue
            if not 0.0 <= value <= 1.0:
                errors.append(f"Row {row_num}: {field} {value} outside 0-1 range")

        try:
            daylen = float(row.get("daylen", "0"))
        except ValueError:
            daylen = 0.0
        if daylen < 120.0:
            errors.append(f"Row {row_num}: daylen {daylen} below minimum 120s")

        try:
            tier_min = int(row.get("tier_min", "0"))
        except ValueError:
            errors.append(f"Row {row_num}: tier_min must be integer")
            tier_min = previous_tier
        if tier_min < 0:
            errors.append(f"Row {row_num}: tier_min {tier_min} must be non-negative")
        if previous_tier != -1 and tier_min < previous_tier:
            errors.append(f"Row {row_num}: tier_min {tier_min} lower than previous {previous_tier}")
        previous_tier = tier_min

    return errors


def write_log(lines: List[str]) -> None:
    log_dir = pathlib.Path("logs/validation")
    log_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d")
    log_path = log_dir / f"{stamp}.log"
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def main() -> int:
    args = parse_args()
    tables = [pathlib.Path(table.strip()) for table in args.tables.split(",") if table.strip()]
    overall_errors: List[str] = []

    for table in tables:
        if not table.exists():
            overall_errors.append(f"[{table}] missing file.")
            continue
        headers, rows = load_tsv(table)
        errors: List[str] = []
        errors += check_headers(headers)

        critical_fields: Set[str] = set()
        if "id" in headers:
            critical_fields.add("id")
            key_fields: Tuple[str, ...] = ("id",)
        elif "profile_id" in headers:
            critical_fields.add("profile_id")
            key_fields = ("profile_id",)
        elif "material_id" in headers:
            critical_fields.add("material_id")
            key_fields = ("material_id",)
        else:
            key_fields = ("id",)

        if "tier" in headers:
            critical_fields.add("tier")
            if "tier" not in key_fields:
                key_fields = key_fields + ("tier",)
        errors += check_empty_cells(rows, critical_fields)
        errors += check_unique(rows, key_fields)

        if "requires" in headers:
            graph = build_dependency_graph(rows, key_fields[0], "requires")
            has_cycle, cycle_path = detect_cycle(graph)
            if has_cycle:
                errors.append(f"Dependency cycle detected: {' -> '.join(cycle_path)}")

        if table.name == "environment_profiles.tsv":
            errors += validate_environment_profiles(headers, rows)

        if errors:
            overall_errors.append(f"[{table}] validation errors:")
            overall_errors.extend(f"  - {err}" for err in errors)
        else:
            overall_errors.append(f"[{table}] ✅ No schema issues found.")

    write_log(overall_errors)
    if any("validation errors" in line for line in overall_errors):
        for line in overall_errors:
            print(line)
        return 1
    for line in overall_errors:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
