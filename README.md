# Opt_Package

**Windows x64 컴퓨터에서 광학 시뮬레이션 도구 18개의 소스·고정 버전 환경·수정판·기초 예제를 자동으로 내려받아 설치합니다.** 기존 PC의 ZIP을 직접 옮길 필요가 없습니다. 설치 스크립트가 필요한 원본 배포파일을 다운로드하고 압축을 풉니다.

기준 스냅샷: **2026-11-16**. 프로젝트별 Python 가상환경, 네이티브 실행환경, Julia depot, WSL의 개별 환경을 만듭니다. 원본 소스 커밋과 SHA256은 [packages.lock.json](packages.lock.json)에 고정되어 있습니다.

## 새 컴퓨터에서 실행

**64비트 Windows PowerShell**에서 다음 세 줄을 실행합니다. Git이나 기존 Python 설치, GitHub 로그인은 필요하지 않습니다.

```powershell
$setup = Join-Path $env:TEMP 'Opt_Package-bootstrap.ps1'
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/El-Carretero/Opt_Package/main/bootstrap.ps1' -OutFile $setup
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -InstallPrerequisites
```

기본 위치는 실제 Windows 바탕화면의 `Opt_Package`(설치 코드)와 `Opt_sim`(18개 소스·환경)입니다. 다운로드한 설치 코드의 정확한 commit은 `Opt_Package/.downloaded-commit`에 남습니다. `ExecutionPolicy Bypass`는 해당 프로세스에만 적용하며 시스템 실행 정책을 변경하지 않습니다.

이미 `Opt_Package`를 받았거나 중간에 설치가 중단되었다면 다운로드를 반복하지 않고 다음 명령으로 재개합니다.

```powershell
$package = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Opt_Package'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$package\install.ps1" -InstallPrerequisites
```

성공한 프로젝트는 건너뛰고 실패하거나 아직 설치하지 않은 프로젝트를 계속합니다. 기존에 수동으로 만든 동명 폴더나 다른 스냅샷은 덮어쓰지 않습니다. 이 경우 새로운 설치 위치를 지정하세요.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$package\install.ps1" -Destination 'D:\Opt_sim'
```

## 전체 18개 설치의 선행 조건

- **Windows 10/11 x64**, 64비트 PowerShell 5.1 이상, 인터넷. 설치 중 **80 GiB 이상** 여유 공간을 권장합니다. 기존 환경의 논리 용량은 약 33 GiB였으며, 다운로드 캐시와 reZonator 빌드 도구가 추가 공간을 사용합니다.
- **FEniCSx와 HASEonGPU**는 초기 설정이 끝난 WSL2의 Ubuntu-24.04가 필요합니다. 없는 새 PC에서는 관리자 PowerShell에서 아래 명령을 실행하고, 안내에 따라 재시작한 뒤 Ubuntu를 한 번 열어 Linux 사용자 초기 설정을 완료합니다. [Microsoft WSL 설치 설명](https://learn.microsoft.com/en-us/windows/wsl/install).

```powershell
wsl --install -d Ubuntu-24.04
```

- GPU 기능에는 호환 NVIDIA GPU와 드라이버가 필요합니다. TorchOptics는 GPU가 없으면 CPU로 검증합니다. HASEonGPU의 GPU 검증 범위와 CPU 경로는 해당 안내를 확인하세요. 드라이버와 Windows 자체는 이 저장소의 고정 대상이 아닙니다.
- OPOSSUM GUI에 필요한 Microsoft Edge WebView2 Runtime이 없으면 공식 설치 파일의 해시·서명을 확인해 자동 설치합니다. `-InstallPrerequisites`는 NPAmp 실행에 구형 VC++ 2008 x86 Runtime이 필요할 때 공식 재배포기를 실행하도록 허용하며, 이때 Windows 관리자 확인 창이 표시될 수 있습니다. 자세한 내용은 [NPAmp 안내](overlays/NPAmp/Readme.md)에 있습니다. 이 옵션은 Windows 드라이버나 WSL을 설치하지 않습니다.

WSL을 먼저 준비하지 않을 때에는 Windows용 16개를 설치하고, 나중에 WSL용 두 개를 추가할 수 있습니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -SkipWSL -InstallPrerequisites
# WSL 초기 설정을 마친 뒤:
$package = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Opt_Package'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$package\install.ps1" -Projects 'FEniCSx,HASEonGPU'
```

이미 설치 코드를 받았다면 첫 줄 대신 `install.ps1 -SkipWSL`을 실행합니다. 다른 Ubuntu 배포판 이름을 선택하려면 `-WslDistro '배포판이름'`을 지정합니다. 의존성 lock의 대상은 Linux x86_64이며 이 스냅샷의 기준은 Ubuntu-24.04입니다.

## 선택 설치와 사전 확인

```powershell
# 설치 계획만 표시
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$package\install.ps1" -Plan

# 기초 학습 도구 세 개만 설치
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$package\install.ps1" -Projects 'Optiland,reZonator,LightPipes'

# 원본 소스와 설치 파일만 준비, 환경 설치는 나중에
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$package\install.ps1" -PrepareOnly

# 이미 성공한 도구도 다시 설치·검증
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$package\install.ps1" -Projects 'LightPipes' -Reinstall
```

처음부터 다른 폴더에 받으려면 `bootstrap.ps1`에 `-PackageDirectory 'D:\Opt_Package' -Destination 'D:\Opt_sim'`을 전달합니다. 스냅샷을 보관할 때는 저장소 commit SHA도 기록하세요. `bootstrap.ps1 -Ref <40자리 commit SHA>`는 해당 설치 코드 버전을 받습니다.

## 포함된 도구

| 도구 | 실행 버전·구성 |
|---|---|
| OPOSSUM | 0.8.1 + Graphviz 14.1.5 |
| modelock_sim | e97d1075eb60, Python 3.11.15, CPU Kerr 경로 |
| KLM-Sim | 0b63c77b5e12, Octave 11.3.0 |
| reZonator | 2.3.0 + opt-sim-fix1, 고정 소스 자동 빌드 |
| Optiland | 0.6.3+local, NumPy CPU + GUI |
| RayOptics | 0.9.10 |
| LightPipes | 2.1.5 |
| Diffractio | 1.0.0 wheel + 지정 commit의 참고 소스 |
| TorchOptics | 1.0.2, torch 2.11.0+cu128 |
| NPAmp | 1.2.18, 격리된 구형 실행환경 |
| HASEonGPU | 2.1.1, CUDA 12.9, openPMD 0.17.1, WSL |
| Luna.jl | 0.6.2, Julia 1.10.13, 별도 depot |
| pychi | 배포 패키지 0.0.22 wheel + 지정 commit의 참고 소스 |
| PyNLO | 0.1.2, Python 3.10.20 |
| pyLaserPulse | 0.1.0, Python 3.11.15 |
| PyFiberAmp | 0.5.0, Python/Numba 경로 |
| FEniCSx | DOLFINx 0.11.0, PETSc 3.25.6, WSL |
| Elmer | 26.2-devel, 11c118114, nompi |

reZonator는 Qt 6.9.3·MinGW 13.1.0·Python 3.12.10 등 필요한 빌드 도구를 자동 다운로드합니다. 이전의 실패 20개 수정과 회귀 검사 4개를 포함해 **532개 자체 검사**를 다시 실행합니다. 첫 설치는 다른 GUI 도구보다 오래 걸립니다. 수정 내용은 [패치](overlays/reZonator/install/source-fixes.patch)로 확인할 수 있습니다.

설치는 버전·소스·패키지 구성과 계산 설정의 재현을 목표로 합니다. OS·GPU·드라이버 차이, 빌드 시각 때문에 바이너리 전체가 바이트 단위로 같아지는 것을 보장하지는 않습니다. KLM-Sim의 전체 MATLAB GUI, modelock_sim의 CUDA diode 경로 등 원래 검증하지 않은 기능은 이 설치로 새로 지원되는 것이 아닙니다.

## 기초 예제

설치 후 각 프로젝트 안의 `learning_examples/RUN.bat`을 실행합니다.

1. [Optiland](overlays/Optiland/learning_examples/README.md): 양볼록 렌즈의 굴절·초점, EFL/BFL.
2. [reZonator](overlays/reZonator/learning_examples/Readme.md): 두 거울 수동 공진기, Gaussian 빔과 안정성.
3. [LightPipes](overlays/LightPipes/learning_examples/Readme.md): Gaussian 전파와 이중 슬릿 회절·간섭.

소스·한국어 설명·실행기가 함께 설치됩니다. 예제를 실행하면 새 컴퓨터의 계산 결과·그림·검증 로그를 생성합니다. 원래 PC의 사용자 경로나 실행 로그를 가져오지 않습니다.

18개 도구 전체의 학습 순위와 선정 이유는 [학습 안내](docs/LEARNING_GUIDE.md)에 있습니다.

## 구성·검증·문제 해결

- `packages.lock.json`: 실제 설치기가 사용하는 18개 원본 commit, URL, SHA256, 버전.
- `overlays/<도구>/`: 설치기·의존성 lock·런처·문서·필요한 소스 수정과 예제.
- `manifests/`: 도구 그룹별 작성 자료. 설치 기준은 루트 `packages.lock.json`입니다.
- 설치 대상의 `.opt-package/logs/<시각>/summary.json`: 프로젝트별 성공·실패와 로그 경로.
- 각 프로젝트의 `.opt-package.json`: 설치한 스냅샷과 완료 상태. 파일을 지워 기존 폴더 보호를 우회하지 마세요.
- `tests/installer.tests.ps1`: 다운로드 손상 거부, 원본 문서 보존, 기존 데이터 보호, 실패 후 재개, 재실행과 종료 코드 검증.

설치가 실패하면 `summary.json`에서 해당 도구의 로그를 확인하고 같은 명령을 다시 실행합니다. 다운로드 파일의 checksum이 맞지 않으면 중단하며, 손상 파일을 별도 위치로 옮긴 뒤 다시 받으세요. 고정된 원본 파일이 배포처에서 사라진 경우에는 버전을 임의로 바꾸지 않고 실패합니다.

이 저장소는 인터넷 연결형 설치기입니다. 공식 배포처·패키지 저장소의 접근 가능성이 필요합니다. 검증한 항목과 실제 한계는 [검증 기록](docs/VALIDATION.md)에 구분합니다. 각 프로젝트와 의존성의 라이선스는 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참조하세요.
