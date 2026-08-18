#!/usr/bin/env bash
# Install write-prd as a Cursor / Codex / Claude / Agents skill.
#
# Usage:
#   ./install.sh
#   ./install.sh /Users/didi/Downloads/write-prd.tar
#   ./install.sh /path/to/write-prd
set -euo pipefail

SKILL_NAME="write-prd"
DEFAULT_TAR="${HOME}/Downloads/write-prd.tar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() {
  echo "error: $*" >&2
  exit 1
}

is_skill_root() {
  local dir="$1"
  [[ -f "${dir}/SKILL.md" ]] || return 1
  grep -q '^name:[[:space:]]*write-prd[[:space:]]*$' "${dir}/SKILL.md"
}

resolve_skill_root() {
  local candidate="$1"

  if [[ -d "${candidate}" ]] && is_skill_root "${candidate}"; then
    printf '%s\n' "${candidate}"
    return 0
  fi

  if [[ -d "${candidate}/${SKILL_NAME}" ]] && is_skill_root "${candidate}/${SKILL_NAME}"; then
    printf '%s\n' "${candidate}/${SKILL_NAME}"
    return 0
  fi

  # Archives sometimes wrap the repo in an extra folder.
  local found
  found="$(find "${candidate}" -maxdepth 3 -type f -name SKILL.md -print 2>/dev/null | head -n 1 || true)"
  if [[ -n "${found}" ]] && is_skill_root "$(dirname "${found}")"; then
    dirname "${found}"
    return 0
  fi

  return 1
}

extract_tar() {
  local tar_path="$1"
  local tmp_dir="$2"
  mkdir -p "${tmp_dir}"
  tar -xf "${tar_path}" -C "${tmp_dir}"
}

copy_skill_files() {
  local src="$1"
  local dest="$2"

  # Keep the skill folder loadable: SKILL.md must sit at the destination root.
  mkdir -p "$(dirname "${dest}")"
  rm -rf "${dest}"
  mkdir -p "${dest}"

  cp "${src}/SKILL.md" "${dest}/SKILL.md"
  [[ -f "${src}/LICENSE" ]] && cp "${src}/LICENSE" "${dest}/LICENSE"
  [[ -f "${src}/README.md" ]] && cp "${src}/README.md" "${dest}/README.md"

  for extra in references agents evals .cursor-plugin; do
    if [[ -d "${src}/${extra}" ]]; then
      cp -R "${src}/${extra}" "${dest}/${extra}"
    fi
  done
}

install_plugin() {
  local src="$1"
  local dest="$2"
  copy_skill_files "${src}" "${dest}"

  if [[ ! -f "${dest}/.cursor-plugin/plugin.json" ]]; then
    mkdir -p "${dest}/.cursor-plugin"
    cat > "${dest}/.cursor-plugin/plugin.json" <<'EOF'
{
  "name": "write-prd",
  "version": "1.0.0",
  "description": "将一句话需求或零散材料，整理成与信息成熟度匹配的产品需求文档（PRD）。",
  "license": "MIT"
}
EOF
  fi
}

SOURCE_ARG="${1:-}"
CLEANUP_DIR=""
SOURCE_ROOT=""

if [[ -z "${SOURCE_ARG}" ]]; then
  if [[ -f "${DEFAULT_TAR}" ]]; then
    SOURCE_ARG="${DEFAULT_TAR}"
  elif [[ -f "/Users/didi/Downloads/write-prd.tar" ]]; then
    SOURCE_ARG="/Users/didi/Downloads/write-prd.tar"
  elif is_skill_root "${SCRIPT_DIR}"; then
    SOURCE_ARG="${SCRIPT_DIR}"
  else
    die "未找到技能包。请传入 tar 路径，或在 write-prd 仓库根目录运行 ./install.sh"
  fi
fi

if [[ -f "${SOURCE_ARG}" ]]; then
  case "${SOURCE_ARG}" in
    *.tar|*.tar.gz|*.tgz)
      CLEANUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/write-prd-install.XXXXXX")"
      extract_tar "${SOURCE_ARG}" "${CLEANUP_DIR}"
      SOURCE_ROOT="$(resolve_skill_root "${CLEANUP_DIR}")" \
        || die "tar 中没有找到 write-prd 的 SKILL.md: ${SOURCE_ARG}"
      ;;
    *)
      die "不支持的文件类型（需要 .tar / .tar.gz）: ${SOURCE_ARG}"
      ;;
  esac
elif [[ -d "${SOURCE_ARG}" ]]; then
  SOURCE_ROOT="$(resolve_skill_root "${SOURCE_ARG}")" \
    || die "目录中没有找到 write-prd 的 SKILL.md: ${SOURCE_ARG}"
else
  die "路径不存在: ${SOURCE_ARG}"
fi

echo "Installing write-prd from: ${SOURCE_ROOT}"

HOME_DIR="${HOME}"
INSTALLED=()

install_skill_dir() {
  local dest="$1"
  mkdir -p "$(dirname "${dest}")"
  copy_skill_files "${SOURCE_ROOT}" "${dest}"
  INSTALLED+=("${dest}")
}

install_skill_dir "${HOME_DIR}/.cursor/skills/${SKILL_NAME}"
install_skill_dir "${HOME_DIR}/.agents/skills/${SKILL_NAME}"
install_skill_dir "${HOME_DIR}/.codex/skills/${SKILL_NAME}"
install_skill_dir "${HOME_DIR}/.claude/skills/${SKILL_NAME}"
install_plugin "${SOURCE_ROOT}" "${HOME_DIR}/.cursor/plugins/local/${SKILL_NAME}"
INSTALLED+=("${HOME_DIR}/.cursor/plugins/local/${SKILL_NAME}")

if [[ -n "${CLEANUP_DIR}" ]]; then
  rm -rf "${CLEANUP_DIR}"
fi

echo
echo "write-prd 已安装到："
for path in "${INSTALLED[@]}"; do
  echo "  - ${path}"
done
echo
echo "Cursor：重启窗口，或运行 Command Palette → Developer: Reload Window。"
echo "之后在 Agent 对话里输入 /write-prd 即可使用。"
