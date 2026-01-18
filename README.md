# Galaga Kernel Automated Build Script

This repository provides a **fully automated build system** for the Galaga kernel (6.1) with optional **KernelSU-Next integration** and **automatic GoFile upload** of build outputs.

The script is designed for developers who want a clean, repeatable kernel build environment with minimal manual work.

---

## ✨ Features

* 🔄 Fresh workspace every build (clean & reproducible)
* ⚠️ Safety confirmation before deleting files
* 🎨 Colored, readable logs
* 🧠 Dependency checks before starting
* 🔐 Optional **KernelSU-Next** integration (prompt-based)
* ⚙️ Bazel-based official build flow
* 📦 Automatically finds `Image` and `boot.img`
* ☁️ Auto uploads build outputs to **GoFile**
* 🔗 Prints direct download links at the end

---

## 📂 What this script does

1. Deletes and recreates the working directory
2. Downloads `repo` and `bazelisk` locally
3. Initializes and syncs the Nothing Galaga kernel manifest
4. Optionally injects KernelSU-Next into the kernel source
5. Builds the kernel using Bazel
6. Searches for `Image*` and `boot.img`
7. Uploads found files to GoFile automatically

---

## 🧰 Requirements

Make sure your Linux system has:

* `git`
* `curl`
* `python3`
* Standard build essentials (gcc, make, etc.)

Ubuntu example:

```bash
sudo apt update
sudo apt install git curl python3 build-essential -y
```

You also need a stable internet connection (repo sync is large).

---

## 🚀 Usage

### 1. Save the script

Create the build script:

```bash
nano build-galaga.sh
```

Paste the full script and save.

---

### 2. Make it executable

```bash
chmod +x build-galaga.sh
```

---

### 3. Run

```bash
./build-galaga.sh
```

---

## 🧠 During execution you will be asked:

* Confirm deleting the build folder
* Whether to integrate **KernelSU-Next**

Example:

```text
Continue? [y/N]:
Integrate KernelSU-Next? [y/N]:
```

---

## 📤 Upload results

After a successful build, the script will:

* Locate kernel `Image`
* Locate `boot.img`
* Upload both to GoFile
* Print direct shareable links

Example output:

```text
Uploaded: Image
👉 https://gofile.io/d/xxxxxx

Uploaded: boot.img
👉 https://gofile.io/d/yyyyyy
```

---

## 📁 Output structure

```
galaga-kernel/
├── kernel-6.1/
├── out/
│   ├── Image
│   ├── boot.img
│   └── ...
├── repo
└── bazel
```

---

## 🔐 KernelSU-Next

If enabled, the script automatically runs:

```
https://github.com/KernelSU-Next/KernelSU-Next
```

This injects KernelSU-Next into the kernel tree before build.

You can choose every build whether you want a **rooted** or **non-rooted** kernel.

---

## 🛠 Customization

Inside the script you can change:

```bash
WORKDIR="$(pwd)/galaga-kernel"
MANIFEST_BRANCH="master"
JOBS="$(nproc)"
```

You can also extend it to:

* Auto-create AnyKernel3 zip
* Auto pack boot.img + dtbo
* Auto send links to Telegram
* Auto version naming

---

## ⚠️ Disclaimer

* Building and flashing custom kernels can brick your device.
* This script is for developers and testers.
* Always keep a backup boot image and recovery.
* You are fully responsible for what you flash.

---
