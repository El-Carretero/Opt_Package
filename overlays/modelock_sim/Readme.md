# modelock_sim 설치 안내 (Opt_Package)

- 소스: https://github.com/YossiLev/modelock_sim
- 버전: Git e97d1075eb60 (release tag 없음)
- 고정 commit: `e97d1075eb60be6e85f6b2e3e71b8fdab594894a`
- 실행환경: Python 3.11.15 .venv + 개별 CPython runtime + w64devkit 2.11.0 CPU DLL
- 원본 README는 `README.upstream.md` 또는 `README.rst`에 보존합니다.

## 장점

Ti:Sapphire Kerr-lens 공진기의 시간·공간 변화와 Gaussian 빔 안정성을 웹 UI에서 실험할 수 있습니다. 소스가 작고 파라미터와 부품 구성이 직접 노출됩니다.

## 단점과 한계

Python 3.12/3.13 비호환이 upstream에 명시되어 3.11을 사용합니다. 현재 CPU 빌드의 CUDA 전용 Maxwell-Bloch diode 경로는 계산을 수행하지 않는 조건부 함수가 있으므로 이 기능을 사용하면 안 됩니다. CUDA 빌드/검증은 별도이며, CPU KLM 시험 통과가 모든 모델의 물리적 검증을 뜻하지 않습니다.

## 사용처

Ti:Sapphire oscillator의 KLM 동역학 탐색, ABCD/Gaussian cavity 설계, 파라미터 민감도 비교. 벌크 리젠/MPA 전체 시스템 계산기는 아닙니다.

## 실행

launch.bat 실행 후 http://127.0.0.1:8000 접속. Ctrl+C로 서버 종료.

## 재설치 및 다른 PC로 이동

`install\install.bat`을 실행합니다. 각 폴더가 독립적이며 다른 도구의 환경에 의존하지 않습니다. Windows x64 대상이고 기본적으로 인터넷을 사용하는 재설치 도구입니다. 설치 파일/버전/다운로드 SHA256을 고정했지만 전체 오프라인 미러는 아닙니다.

Python 도구는 프로젝트별 `.venv`와 `.runtime\python`을 사용합니다. 다른 PC·경로로 이동할 때 `.venv`, `.runtime\python`, `install\cache`를 제외하고 소스와 install 폴더를 복사한 뒤 설치 BAT로 재생성하는 방식을 권장합니다. 전체 폴더를 복사했으면 `pyvenv.cfg`의 이전 Python 경로를 감지하여 `.venv`를 `.venv.previous-날짜`로 보존한 후 새 환경을 만듭니다. 기존 venv를 그대로 이동해 실행하는 것은 지원하지 않습니다.

KLM-Sim과 NPAmp는 Python venv 대상이 아닌 독립 실행환경을 `.runtime`에 둡니다. 시스템 PATH·전역 Python 패키지를 변경하지 않습니다. `install/downloads`의 공식 배포파일과 버전 고정 설치 스크립트를 보관합니다.

## 검증

CPU libdiode.dll 로드; 64 bins Kerr cavity 3 round trips 유한값; FastHTML 루트 HTTP 200

검증 출력: `install/smoke-test.log`. 환경 상세: `install/status.json`, Python 도구의 의존성 버전: `install/requirements-lock.txt`. 짧은 설치 동작 시험이며 연구 결과의 정확성·수렴성 검증을 대체하지 않습니다.

## 공개 설치기 구성

이 overlay에는 바이너리, 가상환경, 개인 로그가 포함되지 않습니다. upstream의 고정 commit 소스를 먼저 확보한 뒤 적용합니다. 런타임 URL/SHA256은 `install/downloads.json`, Python 패키지 버전과 배포파일 해시는 `install/requirements-hashed.txt`(Python 도구)에 있습니다. 설치 결과는 해당 PC에서 `install/status.json`과 smoke 로그로 새로 생성됩니다. upstream 라이선스·저작권 고지는 원본 소스 폴더에 그대로 유지합니다. Windows 10/11 x64 및 Windows PowerShell 5.1이 필요합니다. Python runtime 추출은 Windows 기본 `tar.exe`를 사용합니다.
