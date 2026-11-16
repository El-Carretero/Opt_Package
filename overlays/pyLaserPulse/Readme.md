# pyLaserPulse 설치 안내 (Opt_Package)

- 소스: https://github.com/jsfeehan/pyLaserPulse
- 버전: 0.1.0
- 고정 commit: `9397befa6e04f92c111ad7a5ee7e4efe502dc128`
- 실행환경: Python 3.11.15 .venv + 별도 CPython runtime
- 원본 README는 `README.upstream.md` 또는 `README.rst`에 보존합니다.

## 장점

편광 분해 GNLSE와 Giles 이득/ASE 모델, 광섬유·부품 catalog, counter-pumping 경계값 문제와 compressor 모델을 함께 제공합니다.

## 단점과 한계

(준)단일모드 광섬유를 위한 모델이며 Ti:Sapphire/Nd:YLF 벌크 증폭 모델로 직접 쓸 수 없습니다. 고해상도 시간·주파수 계산과 active-fiber 경계값 계산은 별도 수렴 검증이 필요합니다.

## 사용처

Yb/Er 도핑 광섬유 증폭기, 펄스 광섬유 시스템·supercontinuum·펄스 압축 설계와 이득/비선형 결합 알고리즘 참고.

## 실행

launch.bat으로 가상환경 콘솔 실행. python install/smoke.py로 확인하고 examples를 참고합니다.

## 재설치 및 다른 PC로 이동

`install\install.bat`을 실행합니다. 각 폴더가 독립적이며 다른 도구의 환경에 의존하지 않습니다. Windows x64 대상이고 기본적으로 인터넷을 사용하는 재설치 도구입니다. 설치 파일/버전/다운로드 SHA256을 고정했지만 전체 오프라인 미러는 아닙니다.

Python 도구는 프로젝트별 `.venv`와 `.runtime\python`을 사용합니다. 다른 PC·경로로 이동할 때 `.venv`, `.runtime\python`, `install\cache`를 제외하고 소스와 install 폴더를 복사한 뒤 설치 BAT로 재생성하는 방식을 권장합니다. 전체 폴더를 복사했으면 `pyvenv.cfg`의 이전 Python 경로를 감지하여 `.venv`를 `.venv.previous-날짜`로 보존한 후 새 환경을 만듭니다. 기존 venv를 그대로 이동해 실행하는 것은 지원하지 않습니다.

KLM-Sim과 NPAmp는 Python venv 대상이 아닌 독립 실행환경을 `.runtime`에 둡니다. 시스템 PATH·전역 Python 패키지를 변경하지 않습니다. `install/downloads`의 공식 배포파일과 버전 고정 설치 스크립트를 보관합니다.

## 검증

512점 grid와 200 fs sech pulse 생성, pulse energy 2.2954567585414995e-12 J

검증 출력: `install/smoke-test.log`. 환경 상세: `install/status.json`, Python 도구의 의존성 버전: `install/requirements-lock.txt`. 짧은 설치 동작 시험이며 연구 결과의 정확성·수렴성 검증을 대체하지 않습니다.

## 공개 설치기 구성

이 overlay에는 바이너리, 가상환경, 개인 로그가 포함되지 않습니다. upstream의 고정 commit 소스를 먼저 확보한 뒤 적용합니다. 런타임 URL/SHA256은 `install/downloads.json`, Python 패키지 버전과 배포파일 해시는 `install/requirements-hashed.txt`(Python 도구)에 있습니다. 설치 결과는 해당 PC에서 `install/status.json`과 smoke 로그로 새로 생성됩니다. upstream 라이선스·저작권 고지는 원본 소스 폴더에 그대로 유지합니다. Windows 10/11 x64 및 Windows PowerShell 5.1이 필요합니다. Python runtime 추출은 Windows 기본 `tar.exe`를 사용합니다.
