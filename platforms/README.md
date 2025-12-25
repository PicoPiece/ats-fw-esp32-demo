# Platform-Specific CI/CD Pipelines

Cấu trúc pipeline được tổ chức theo platform để dễ mở rộng và quản lý.

## Cấu trúc

```
platforms/
  ESP32/
    Jenkinsfile          # Build pipeline cho ESP32
    Jenkinsfile.test     # Test pipeline cho ESP32
  RaspberryPi/
    Jenkinsfile          # Build pipeline cho Raspberry Pi
    Jenkinsfile.test     # Test pipeline cho Raspberry Pi
  nRF52/
    Jenkinsfile          # Build pipeline cho nRF52
    Jenkinsfile.test     # Test pipeline cho nRF52
```

## Setup trong Jenkins

### 1. Build Job
- **Job name**: `ats-fw-esp32-demo` (hoặc tên repo của bạn)
- **Type**: Pipeline
- **Definition**: Pipeline script from SCM
- **Script Path**: `platforms/ESP32/Jenkinsfile`

### 2. Test Job
- **Job name**: `ats-fw-esp32-demo-ESP32-test`
- **Type**: Pipeline
- **Definition**: Pipeline script from SCM
- **Script Path**: `platforms/ESP32/Jenkinsfile.test`

## Thêm Platform Mới

1. Tạo thư mục mới: `platforms/{PlatformName}/`
2. Copy `Jenkinsfile` và `Jenkinsfile.test` từ platform tương tự
3. Cập nhật:
   - `PLATFORM` environment variable
   - `FW_ARTIFACT` tên file output
   - Build commands (idf.py, cmake, ...)
   - Tag prefix
4. Tạo Jenkins jobs tương ứng

## Naming Convention

- **Build Job**: `{repo-name}` (có thể chọn platform qua parameter)
- **Test Job**: `{repo-name}-{PLATFORM}-test`
- **Firmware Artifact**: `firmware-{platform}.bin`
- **Git Tag**: `{TAG_PREFIX}-{BUILD_NUMBER}-{COMMIT_SHORT}`

