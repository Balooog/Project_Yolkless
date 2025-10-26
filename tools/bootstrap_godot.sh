#!/usr/bin/env bash
set -euo pipefail

VERSION="4.5.1"
LINUX_RELEASE_NAME="Godot_v${VERSION}-stable_linux.x86_64"
LINUX_ARCHIVE_NAME="${LINUX_RELEASE_NAME}.zip"
DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/${LINUX_ARCHIVE_NAME}"

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BIN_DIR="${REPO_ROOT}/bin"
LINUX_BIN_PATH="${BIN_DIR}/${LINUX_RELEASE_NAME}"
ARCHIVE_PATH="${BIN_DIR}/${LINUX_ARCHIVE_NAME}"

ensure_tools() {
	if ! command -v curl >/dev/null 2>&1; then
		echo "[bootstrap] curl is required to download Godot." >&2
		exit 1
	fi
	if ! command -v unzip >/dev/null 2>&1; then
		echo "[bootstrap] unzip is required to extract ${LINUX_ARCHIVE_NAME}." >&2
		exit 1
	fi
}

download_linux_cli() {
	mkdir -p "${BIN_DIR}"
	echo "[bootstrap] Downloading ${LINUX_ARCHIVE_NAME}..."
	curl -fL "${DOWNLOAD_URL}" -o "${ARCHIVE_PATH}"
}

extract_linux_cli() {
	echo "[bootstrap] Extracting ${LINUX_ARCHIVE_NAME}..."
	unzip -o "${ARCHIVE_PATH}" -d "${BIN_DIR}" >/dev/null
	chmod +x "${LINUX_BIN_PATH}"
	rm -f "${ARCHIVE_PATH}"
}

main() {
	ensure_tools
	if [[ -x "${LINUX_BIN_PATH}" ]]; then
		if "${LINUX_BIN_PATH}" --version >/dev/null 2>&1; then
			echo "[bootstrap] Godot CLI already present at ${LINUX_BIN_PATH}"
			echo "GODOT_BIN=${LINUX_BIN_PATH}"
			return
		else
			echo "[bootstrap] Existing binary at ${LINUX_BIN_PATH} failed to run; refreshing..."
			rm -f "${LINUX_BIN_PATH}"
		fi
	fi
	download_linux_cli
	extract_linux_cli
	echo "[bootstrap] Installed Godot CLI to ${LINUX_BIN_PATH}"
	echo "GODOT_BIN=${LINUX_BIN_PATH}"
}

main "$@"
