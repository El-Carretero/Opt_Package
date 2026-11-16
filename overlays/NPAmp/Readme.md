# NPAmp 설치 안내 (Opt_Package)

- 소스: https://github.com/vsemionov/npamp
- 버전: 1.2.18
- 고정 commit: `b1eb07c7fe8204f4e316a26b56b12caa9b54d0b2`
- 실행환경: 공식 Windows 바이너리에서 추출한 app-local Python 2.7 runtime (.runtime/app)
- 원본 README는 `README.upstream.md` 또는 `README.rst`에 보존합니다.

## 장점

벌크 4준위 증폭기의 펄스열, 포화, ASE, 유한한 하준위 수명, 저장에너지·추출효율 계산 코드와 GUI를 제공합니다.

## 단점과 한계

구형 Python 2.7 기반이며 최신 Python venv 패키지가 아닙니다. 격리된 공식 binary runtime으로 실행합니다. 소스 수정의 재컴파일은 별도의 구형 Cython/C 도구체인이 필요합니다. 단일패스·균일 펌프·고정 온도·단순화된 빔 등 upstream 가정을 확인해야 합니다.

## 사용처

벌크 증폭기 이득 포화, 펄스열 에너지, ASE 모델 비교, 하준위 수명 효과 및 자체 벌크 모델 구현 참고.

## 실행

launch.bat은 GNPAmp GUI, run-cli.bat -h는 CLI 도움말. 예: run-cli.bat install/smoke.npc

## 재설치 및 다른 PC로 이동

`install\install.bat`을 실행합니다. 각 폴더가 독립적이며 다른 도구의 환경에 의존하지 않습니다. Windows x64 대상이고 기본적으로 인터넷을 사용하는 재설치 도구입니다. 설치 파일/버전/다운로드 SHA256을 고정했지만 전체 오프라인 미러는 아닙니다.

Python 도구는 프로젝트별 `.venv`와 `.runtime\python`을 사용합니다. 다른 PC·경로로 이동할 때 `.venv`, `.runtime\python`, `install\cache`를 제외하고 소스와 install 폴더를 복사한 뒤 설치 BAT로 재생성하는 방식을 권장합니다. 전체 폴더를 복사했으면 `pyvenv.cfg`의 이전 Python 경로를 감지하여 `.venv`를 `.venv.previous-날짜`로 보존한 후 새 환경을 만듭니다. 기존 venv를 그대로 이동해 실행하는 것은 지원하지 않습니다.

KLM-Sim과 NPAmp는 Python venv 대상이 아닌 독립 실행환경을 `.runtime`에 둡니다. 시스템 PATH·전역 Python 패키지를 변경하지 않습니다. `install/downloads`의 공식 배포파일과 버전 고정 설치 스크립트를 보관합니다.

## 검증

공식 CLI -h 실행; 실제 1 pulse 증폭 계산 완료, energy gain 1.32532784093

검증 출력: `install/smoke-test.log`. 환경 상세: `install/status.json`, Python 도구의 의존성 버전: `install/requirements-lock.txt`. 짧은 설치 동작 시험이며 연구 결과의 정확성·수렴성 검증을 대체하지 않습니다.

## 다른 PC의 Windows 런타임 조건

공식 NPAmp 배포는 Microsoft Visual C++ 2008 x86 runtime을 전제로 합니다. 기존 검증 PC에는 VC90가 설치되어 있었으며, VC90가 없는 깨끗한 Windows에서의 재배포기 설치 분기는 시험하지 않았습니다. 기본 설치는 실제 증폭 계산을 먼저 실행합니다. side-by-side/VC90 오류가 나면 `install/install-prerequisites.bat` 또는 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File install/install.ps1 -InstallPrerequisites`로 재실행합니다. 이 옵션은 필요할 때만 공식 포함 `.runtime/tmp/vcredist_x86.exe`를 SHA256 확인 후 `/q /r:n`로 실행합니다. 시스템 구성요소이므로 Windows가 관리자 권한(UAC)을 요청할 수 있습니다. 설치 후 계산을 다시 검사하며 재부팅이 필요하면 재부팅 후 다시 실행합니다. 이 구성요소는 폴더 격리의 예외입니다. 일반 설치기는 명시적인 옵션 없이 시스템 구성요소를 설치하지 않습니다.

## 공개 설치기 구성

이 overlay에는 바이너리, 가상환경, 개인 로그가 포함되지 않습니다. upstream의 고정 commit 소스를 먼저 확보한 뒤 적용합니다. 런타임 URL/SHA256은 `install/downloads.json`, Python 패키지 버전과 배포파일 해시는 `install/requirements-hashed.txt`(Python 도구)에 있습니다. 설치 결과는 해당 PC에서 `install/status.json`과 smoke 로그로 새로 생성됩니다. upstream 라이선스·저작권 고지는 원본 소스 폴더에 그대로 유지합니다. Windows 10/11 x64 및 Windows PowerShell 5.1이 필요합니다. Python runtime 추출은 Windows 기본 `tar.exe`를 사용합니다.
