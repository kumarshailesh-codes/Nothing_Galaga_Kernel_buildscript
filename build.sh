#!/bin/bash
set -e

clear

KERNEL="$(pwd)/galaga-kernel"

echo "This will REMOVE the following directory if it exists:"
echo "  - $KERNEL"
read -rp "Do you want to continue? [y/N]: " ans

if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

# ----------------------
# fresh start
# ----------------------
rm -rf "$KERNEL"
mkdir -p "$KERNEL"
cd "$KERNEL"

# ----------------------
# install repo & bazel locally
# ----------------------
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o repo
chmod +x repo

curl -fsSL https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o bazel
chmod +x bazel

export PATH="$KERNEL:$PATH"


repo init \
  -u https://github.com/nothing-galaga/kernel_manifest-6.1 \
  -b master

repo sync -c -j$(nproc) --no-tags


# ----------------------
# KernelSU-Next
# ----------------------
cd kernel-6.1
curl -LSs https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh | bash -
cd ..

# ----------------------
# Build
# ----------------------
tools/bazel run //kernel-6.1:kernel_aarch64_dist -- --destdir=out
