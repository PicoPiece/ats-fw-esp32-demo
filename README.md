# ATS ESP32 Firmware Demo

> **ESP32 firmware designed for automated hardware testing**

This firmware exists solely to demonstrate automated hardware testing and is not intended to be a production product.

---

## 📁 Repository Structure

```
ats-fw-esp32-demo/
├── README.md
├── CMakeLists.txt
├── main/
│   ├── CMakeLists.txt
│   ├── app_main.c
│   ├── gpio_demo.c
│   ├── oled_demo.c
│   └── ota.c
├── platforms/
│   ├── ESP32/
│   │   ├── Jenkinsfile          # Build pipeline
│   │   └── Jenkinsfile.test     # Test pipeline
│   ├── RaspberryPi/
│   └── README.md
└── sdkconfig
```

---

## 🎯 Purpose

This firmware is built on the Xeon server as part of the CI/CD pipeline.

**Key points:**

- ✅ Firmware is built on the Xeon server (build agents with `fw-build` label)
- ✅ ATS nodes never build firmware
- ✅ ATS nodes only consume signed/versioned artifacts for hardware validation
- ✅ **Firmware artifacts produced by this repository are validated using `ats-test-esp32-demo`**
- ✅ **This repository is responsible ONLY for firmware source code and build pipelines**

## 📋 Repository Responsibilities

### ✅ What This Repository Does

- **Firmware source code** (ESP-IDF project)
- **Build pipeline** (`Jenkinsfile` in `platforms/ESP32/`)
- **Artifact generation**:
  - Firmware binary (`firmware-esp32.bin`)
  - ATS manifest (`ats-manifest.yaml`) - see [ATS Manifest Spec v1](../ats-platform-docs/architecture/ats-manifest-spec-v1.md)
- **Git tagging** (local tags for versioning)
- **Triggering test pipeline** (asynchronous, non-blocking)

### ❌ What This Repository Does NOT Do

- **Hardware testing** → `ats-test-esp32-demo` and `ats-ats-node`
- **Hardware interaction** (flashing, USB detection) → `ats-ats-node`
- **Test execution** → `ats-test-esp32-demo`
- **CI orchestration** → `ats-ci-infra`

---

## 🔄 Build Process

1. **Source checkout** from Git repository
2. **ESP-IDF build** on Jenkins build agent (`fw-build` label)
3. **Artifact generation:**
   - `firmware-esp32.bin` (firmware binary)
   - `ats-manifest.yaml` (build metadata)
4. **Artifact archiving** in Jenkins
5. **Tag creation** (local Git tag for versioning)

---

## 🧪 Test Integration

Firmware artifacts are automatically tested using the `ats-test-esp32-demo` framework:

- **Build pipeline** (`Jenkinsfile`) triggers test pipeline (`Jenkinsfile.test`) asynchronously
- **Test pipeline** copies artifacts from build job and runs on ATS nodes (Raspberry Pi)
- **ATS Node** (`ats-ats-node`) handles all hardware interaction (flashing, USB detection)
- **Test Runner** (`ats-test-esp32-demo`) executes pure test logic
- Hardware validation includes:
  - UART boot validation
  - GPIO behavior
  - OLED display
  - Firmware stability

**The firmware repository does not contain test execution logic** — that responsibility belongs to `ats-test-esp32-demo` and `ats-ats-node`.

---

## 🏗️ Multi-Platform Support

The repository is organized by platform:

```
platforms/
├── ESP32/          # ESP32 firmware build and test
├── RaspberryPi/    # Raspberry Pi image build (future)
└── nRF52/          # nRF52 firmware build (future)
```

Each platform has its own:
- Build pipeline (`Jenkinsfile`)
- Test pipeline (`Jenkinsfile.test`)

---

## 📦 Artifacts

### Firmware Binary

- **Name:** `firmware-{PLATFORM}.bin`
- **Format:** ESP32 binary image
- **Location:** Jenkins artifact archive

### ATS Manifest

- **Name:** `ats-manifest.yaml`
- **Schema:** v1 (see [ATS Manifest Specification v1](../ats-platform-docs/architecture/ats-manifest-spec-v1.md))
- **Contains:**
  - Build metadata (CI system, job name, build number)
  - Git information (repo, commit, branch)
  - Artifact checksum (SHA256)
  - Device target information
  - Test plan references
- **Purpose:** Single contract between build, ATS node, test runner, and CI system

---

## 🔗 Relationship to Other Repositories

- **`ats-ci-infra`**: Build infrastructure and pipeline orchestration
- **`ats-test-esp32-demo`**: Hardware test execution framework
- **`ats-platform-docs`**: System documentation and architecture

---

## 👤 Author

**Hai Dang Son**  
Senior Embedded / Embedded Linux / IoT Engineer
