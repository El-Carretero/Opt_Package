# Oscillator / amplifier / legacy Python installer group

이 문서는 `modelock_sim`, `KLM-Sim`, `NPAmp`, `PyNLO`, `pyLaserPulse`, `PyFiberAmp`의 설치 방식을 설명합니다. 소스 commit은 `manifests/legacy.json`에 고정되어 있습니다. 공개 저장소의 overlay에는 작성한 설치 스크립트·패키지 잠금·실행기·간단한 계산 시험만 포함하며, upstream 소스 전체나 바이너리·가상환경·설치 로그를 포함하지 않습니다.

## 설치 환경과 검증 범위

| 도구 | 프로젝트별 실행환경 | 설치 후 실행하는 시험 | 주요 한계 |
|---|---|---|---|
| modelock_sim | CPython 3.11.15, w64devkit 2.11.0 CPU DLL | 64 bins, Kerr cavity 3 round trips, 웹 루트 HTTP 200 | CUDA Maxwell–Bloch diode 경로는 지원하지 않음. CPU 시험은 GPU 모델 검증이 아님 |
| KLM-Sim | GNU Octave 11.3.0 Windows x64 | settings, MLSpatial, NLloss, SatGain | 원래 MATLAB 코드. 전체 2000회 oscillator 계산과 GUI 호환성은 검증 범위 밖 |
| NPAmp 1.2.18 | 공식 Windows 배포에서 추출한 app-local Python 2.7 | 1 pulse 증폭, energy gain 1.32532784093 | VC++2008 x86 시스템 CRT 필요. 소스 수정의 재빌드는 별도 구형 도구체인 필요 |
| PyNLO 0.1.2 | CPython 3.10.20, NumPy 1.23.5, SciPy 1.10.1 | 256점 sech pulse, 2 step SSFM, 출력 에너지 약 1e-12 J | 오래된 NumPy API를 위해 버전 고정. χ² 전체 경로·횡방향 효과 검증은 별도 |
| pyLaserPulse 0.1.0 | CPython 3.11.15 | 512점 grid 및 200 fs sech pulse 생성 | 광섬유용. 벌크 Ti:Sapphire/Nd:YLF 모델로 바로 쓸 수 없음. 전체 active-fiber 전파 검증은 별도 |
| PyFiberAmp 0.5.0 | CPython 3.11.15, NumPy 1.26.4, SciPy 1.12.0, Numba 0.59.1 | 0.1 m Yb fiber의 pump/signal/4 ASE bins steady-state 계산 | upstream Python3.9용 C++ addon은 사용하지 않음. coherent pulse 전파 모델이 아님 |

Windows 10/11 x64, Windows PowerShell 5.1, 인터넷 연결을 사용합니다. Python은 Windows 기본 `tar.exe`로 해당 프로젝트의 `.runtime/python`에 직접 추출하고, `uv`로 그 Python을 지정해 `.venv`를 만듭니다. 전역 Python 등록·전역 pip 설치·시스템 PATH 변경은 하지 않습니다. Octave와 NPAmp는 Python venv 대신 자체 `.runtime`을 사용합니다.

## 고정 버전과 다운로드 검증

- `install/downloads.json`: 각 프로젝트의 런타임/설치 도구 URL과 SHA256입니다. 기존 캐시도 해시가 맞아야 사용합니다. 다운로드는 `.part`로 받은 뒤 검증하여 최종 이름으로 저장합니다.
- uv는 0.11.6 ZIP과 추출한 `uv.exe`를 모두 검사합니다. CPython은 python-build-standalone 20260408 빌드의 정확한 URL과 SHA256을 고정했습니다. 출처는 [uv 0.11.6 Python 다운로드 메타데이터](https://github.com/astral-sh/uv/blob/0.11.6/crates/uv-python/download-metadata.json)입니다.
- `requirements-lock.txt`는 사람이 읽는 Python 패키지 버전 목록이며 `requirements-hashed.txt`는 동일 버전의 배포파일 해시 목록입니다. 설치기는 `--require-hashes`를 사용합니다. PyPI와 upstream 배포 서버가 계속 해당 파일을 제공해야 합니다.
- Python 라이브러리 소스는 중앙 설치기가 고정 commit으로 확보하고, 세 라이브러리(PyNLO/pyLaserPulse/PyFiberAmp)는 그 로컬 소스를 `--no-deps --no-build-isolation -e .`로 설치합니다. modelock_sim은 원본 앱 디렉터리에서 실행합니다.
- 실행 파일과 패키지의 고정·해시 확인은 다운로드 일치성을 확인합니다. 모든 물리 모델의 정확성이나 장시간 계산의 수렴성을 보증하는 것은 아닙니다.

폴더를 옮긴 뒤 Python 환경을 다시 설치하면 `pyvenv.cfg`의 인터프리터 경로를 확인해 이전 `.venv`를 날짜가 붙은 이름으로 보존하고 새 환경을 만듭니다. 새 PC에서는 소스와 설치 파일만 옮긴 뒤 재설치하는 편이 간단합니다. 패키지 잠금 파일에는 개발자의 절대 경로나 editable 경로가 들어 있지 않습니다.

## NPAmp의 VC++2008 선행 구성요소

NPAmp 공식 배포는 **Microsoft Visual C++ 2008 x86 Runtime**에 의존합니다. Python 2.7을 폴더 안에 추출하는 것만으로 이 시스템 구성요소를 대신하지 못합니다. 기존 검증 PC에는 VC90 CRT가 이미 설치되어 있었습니다. 새 디렉터리의 재설치는 확인해도 **VC90가 전혀 없는 깨끗한 Windows에서의 설치까지 시험했다는 뜻은 아닙니다.**

NPAmp 기본 설치기는 먼저 실제 증폭 계산을 실행합니다. 실패하면 로그와 선행 구성요소 설치 명령을 안내합니다. 다음 명령은 공식 포함 `vcredist_x86.exe`를 사용할 수 있도록 허용합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install\install.ps1 -InstallPrerequisites
```

도구 폴더의 `install/install-prerequisites.bat`으로도 실행할 수 있습니다. 중앙 설치기의 같은 옵션은 NPAmp 설치기로 전달됩니다. 정상 실행되는 PC에서는 이 옵션이 있어도 선행 구성요소를 다시 설치하지 않습니다. 필요할 때만 SHA256을 확인한 공식 재배포기를 `/q /r:n`로 실행하고, 권한이 부족하면 Windows UAC 승인을 요청합니다. 시스템 런타임 설치이므로 여기만 완전한 폴더 격리의 예외입니다. 설치 후 계산을 다시 검사하며, 재부팅이 필요하면 오류 안내에 따라 재부팅 후 재실행합니다.

앱 로컬 CRT 배포도 조사했지만 포함된 CRT manifest 버전은 `9.0.30729.1`, NPAmp·GNPAmp·python27.dll의 embedded dependency는 `9.0.21022.8`입니다. DLL만 복사하면 버전 바인딩이 해결되지 않아 Microsoft 바이너리나 manifest를 임의 수정하지 않았습니다. 관련 Windows 동작은 [Microsoft의 side-by-side 구성 문서](https://learn.microsoft.com/en-us/windows/win32/sbscs/application-configuration-files)를 참고했습니다.

현재 PC의 시스템 구성요소를 바꾸는 방식으로 `-InstallPrerequisites` 분기를 시험하지 않았습니다. 공식 재배포기 실행과 Windows 관리자 승인은 새 PC에서 필요할 수 있는 단계로 명시합니다.

무인 실행 및 재부팅 억제 인자 `/q /r:n`은 [Microsoft의 VC++2008 배포 지침](https://learn.microsoft.com/en-us/security-updates/securitybulletins/2011/ms11-025)에 따릅니다. 이후 VC++ 버전의 `/norestart`와 구분합니다. 접근 거부나 계산 실패를 런타임 누락으로 취급하지 않으며, 시스템 설치는 확인된 side-by-side/DLL 누락 오류일 때만 시도합니다.

## 라이선스와 원본 보존

원본 다운로드의 라이선스·저작권 파일을 삭제하거나 이 프로젝트의 라이선스로 대체하지 않습니다. KLM-Sim의 `LICENSE`, PyNLO의 `COPYING`, pyLaserPulse의 `LICENSE`, PyFiberAmp의 `LICENSE.txt`는 GPL 계열 고지이며 NPAmp의 `LICENSE`는 BSD 형태의 조건을 포함합니다. 정확한 적용 조건은 각 원본 파일을 확인해야 합니다. modelock_sim의 고정 commit에는 별도 LICENSE 파일이 없으므로 공개 소스라는 이유만으로 재배포·수정 권한을 추정하지 않습니다. 이 패키지는 해당 코드 사본을 배포하지 않고 원본 URL과 commit을 참조합니다.

modelock_sim의 `readme.md`와 KLM-Sim의 `README.md`는 Windows에서 overlay의 `Readme.md`와 이름이 겹칩니다. 중앙 설치기는 overlay 적용 전에 원본을 `README.upstream.md`로 보존합니다. 나머지 도구는 원본 `README.rst`가 유지됩니다. 다운로드한 uv/CPython/Octave/w64devkit/innoextract/공식 NPAmp 배포 안의 라이선스 고지도 추출된 폴더에 유지합니다.

## 재현 시험 기록

저장소 밖의 새 폴더에서 PyNLO의 소스·uv·CPython·의존성을 실제 다운로드하여 설치하고 `pip check`와 SSFM 계산을 통과했습니다. 출력 에너지는 `1.0000000000000002e-12 J`였습니다. 이 검증은 기존 `Opt_sim`의 venv나 다운로드 캐시를 복사하지 않았습니다. 공개 저장소에는 컴퓨터별 로그와 경로를 넣지 않으며, 각 설치 대상 폴더에 `install/status.json`, `smoke-test.log`, `smoke-stderr.log`를 새로 생성합니다.

modelock_sim도 새 폴더에서 소스·CPython·126개 패키지·w64devkit을 다운로드해 CPU DLL을 빌드했고, 3 Kerr round trips와 HTTP 200 시험을 통과했습니다. NPAmp는 공식 배포와 innoextract를 새로 다운로드·추출하여 energy gain `1.32532784093` 계산을 통과했습니다. 새 실행 파일의 일시적 접근/공유 오류는 1초 간격으로 최대 5회 시도하며, 이 오류를 CRT 누락으로 오인해 시스템 설치를 실행하지 않습니다. NPAmp 검증 PC의 VC90가 기설치되어 있다는 한계는 앞 절과 같습니다.
