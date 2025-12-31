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

repo init -u https://android-review.googlesource.com/kernel/manifest \
  -b common-android14-6.1 \
  --depth=1


mkdir -p .repo/local_manifests

cat > .repo/local_manifests/galaga.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

  <!-- custom vendor remote -->
  <remote name="nothing-galaga"
          fetch="https://github.com/nothing-galaga/" />

  <!-- Nothing / Malachite kernel -->
  <project path="kernel-6.1"
           name="android_kernel_nothing_mt6878"
           revision="lineage-23.0"
           remote="nothing-galaga">
    <linkfile src="build.config.constants"
              dest="build.config.constants" />
  </project>

  <!-- Device kernel modules -->
  <project path="kernel_device_modules-6.1"
           name="android_kernel_device_modules_6.1"
           revision="lineage-23.0"
           remote="nothing-galaga">
    <linkfile src="build.config.galaga"
              dest="build.config" />
  </project>

  <!-- MediaTek vendor modules -->
  <project path="vendor/mediatek/kernel_modules"
           name="android_vendor_mediatek_kernel_modules"
           revision="lineage-23.0"
           remote="nothing-galaga" />

  <!-- Bazel rules overrides -->
  <project path="build/bazel_mgk_rules"
           name="kernel-build-bazel_mgk_rules"
           revision="lineage-23.0"
           remote="nothing-galaga">
    <linkfile src="BUILD.bazel" dest="BUILD" />
    <linkfile src="kleaf/bazel.WORKSPACE" dest="WORKSPACE" />
  </project>

</manifest>
EOF

repo sync -c -j$(nproc) --force-sync --no-tags --no-clone-bundle

# Add KernelSu / KSU-Next ( uncomment below path to add KSU / KSU NEXT SUPPORT)
 cd $KERNEL/kernel-6.1/

# Uncomment this for KernelSU-next
 curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -

# UNcomment this for KernelSU
# curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -

sleep 1
cd ..

bazel run //kernel-6.1:kernel_aarch64_dist -- --destdir=out
