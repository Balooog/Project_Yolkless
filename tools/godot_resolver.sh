#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LINUX_BIN="${REPO_ROOT}/bin/Godot_v4.5.1-stable_linux.x86_64"
BOOTSTRAP_SCRIPT="${REPO_ROOT}/tools/bootstrap_godot.sh"

running_in_wsl() {
	grep -qi microsoft /proc/version 2>/dev/null
}

use_if_valid() {
	local candidate="$1"
	if [[ -z "${candidate}" ]]; then
		return
	fi
	local resolved="${candidate}"
	if [[ ! -x "${resolved}" ]]; then
		if command -v "${candidate}" >/dev/null 2>&1; then
			resolved="$(command -v "${candidate}")"
		fi
	fi
	if [[ -x "${resolved}" ]] && "${resolved}" --version >/dev/null 2>&1; then
		echo "${resolved}"
		exit 0
	fi
}

resolve_wsl() {
	if running_in_wsl; then
		if [[ -x "${LINUX_BIN}" ]]; then
			use_if_valid "${LINUX_BIN}"
		fi
		if [[ -x "${BOOTSTRAP_SCRIPT}" ]]; then
			bash "${BOOTSTRAP_SCRIPT}" >/dev/null
			if [[ -x "${LINUX_BIN}" ]]; then
				echo "${LINUX_BIN}"
				exit 0
			fi
		fi
	fi
}

main() {
	if running_in_wsl; then
		if [[ -n "${GODOT_BIN:-}" ]] && [[ ! "${GODOT_BIN}" =~ ^/mnt/c/ ]]; then
			use_if_valid "${GODOT_BIN}"
		fi
		resolve_wsl
	else
		use_if_valid "${GODOT_BIN:-}"
	fi

	# Local fallback (non-WSL Linux / macOS clones using the tarball).
	if [[ -x "${LINUX_BIN}" ]]; then
		use_if_valid "${LINUX_BIN}"
	fi

	# Non-WSL users may still rely on an explicitly-set GODOT_BIN.
	if ! running_in_wsl; then
		use_if_valid "${GODOT_BIN:-}"
	fi

	echo "[resolver] No valid Godot binary found." >&2
	exit 1
}

main "$@"
