#!/usr/bin/env bash
set -Eeuo pipefail

# ==================================================
# CONFIG
# ==================================================
WORKDIR="$(pwd)/galaga-kernel"
MANIFEST_URL="https://github.com/nothing-galaga/kernel_manifest-6.1"
MANIFEST_BRANCH="master"
JOBS="$(nproc)"

# ==================================================
# COLORS + LOG
# ==================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; }

trap 'err "Script failed at line $LINENO"; exit 1' ERR

clear

# ==================================================
# CONFIRM DELETE
# ==================================================
echo "This will REMOVE the following directory if it exists:"
echo "  - $WORKDIR"
read -rp "Continue? [y/N]: " ans
[[ "${ans,,}" == "y" ]] || { warn "Aborted."; exit 1; }

# ==================================================
# DEPENDENCY CHECK
# ==================================================
for c in git curl python3; do
  command -v $c >/dev/null || { err "$c not found"; exit 1; }
done

# ==================================================
# ASK KSU-NEXT
# ==================================================
read -rp "Integrate KernelSU-Next? [y/N]: " ksu_ans
if [[ "${ksu_ans,,}" == "y" ]]; then
  ENABLE_KSU=true
  log "KernelSU-Next ENABLED"
else
  ENABLE_KSU=false
  warn "KernelSU-Next DISABLED"
fi

# ==================================================
# FRESH START
# ==================================================
log "Preparing workspace..."
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ==================================================
# TOOLS (local)
# ==================================================
log "Downloading repo tool..."
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o repo
chmod +x repo

log "Downloading bazelisk..."
curl -fsSL https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o bazel
chmod +x bazel

export PATH="$WORKDIR:$PATH"
ok "Tools ready"

# ==================================================
# REPO INIT + SYNC
# ==================================================
log "Initializing repo..."
repo init -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH"

log "Syncing sources..."
repo sync -c -j"$JOBS" --no-tags --force-sync
ok "Sources synced"

# ==================================================
# KERNELSU-NEXT
# ==================================================
if $ENABLE_KSU; then
  log "Applying KernelSU-Next..."
  cd kernel-6.1
  curl -LSs https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh | bash -
  cd ..
  ok "KernelSU-Next applied"
fi

# ==================================================
# BUILD
# ==================================================
log "Building kernel..."
tools/bazel run //kernel-6.1:kernel_aarch64_dist -- --destdir=out
ok "Build finished"

# ==================================================
# GOFILE UPLOAD
# ==================================================
gofile_upload() {
  local FILE="$1"

  [[ -f "$FILE" ]] || { warn "Not found: $FILE"; return; }

  log "Getting GoFile server..."
  SERVER=$(curl -s https://api.gofile.io/getServer | grep -oP '"server":"\K[^"]+')
  [[ -n "$SERVER" ]] || { err "Server fetch failed"; return; }

  log "Uploading $(basename "$FILE")..."
  RESP=$(curl -s -F "file=@$FILE" "https://${SERVER}.gofile.io/uploadFile")
  LINK=$(echo "$RESP" | grep -oP '"downloadPage":"\K[^"]+')

  [[ -n "$LINK" ]] || { err "Upload failed"; echo "$RESP"; return; }

  ok "Uploaded: $(basename "$FILE")"
  echo "👉 $LINK"
  echo
}

# ==================================================
# FIND + UPLOAD FILES
# ==================================================
log "Searching output files..."

KERNEL_IMG=$(find out -type f -name "Image*" | head -n 1)
BOOT_IMG=$(find out -type f -name "boot.img" | head -n 1)

echo
echo "================ UPLOAD RESULTS ================"

[[ -n "$KERNEL_IMG" ]] && gofile_upload "$KERNEL_IMG" || warn "Kernel image not found"
[[ -n "$BOOT_IMG"   ]] && gofile_upload "$BOOT_IMG"   || warn "boot.img not found"

echo "================================================"
ok "All done 🔥"
