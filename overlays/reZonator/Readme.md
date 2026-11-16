# reZonator 2.3.0 + Opt_Package 수정판

ABCD 공진기 안정성, Gaussian 모드와 단일 통과 광학계를 GUI로 공부하는 도구입니다. 근축 모델이며 포화 이득·펄스 형성·열 모델을 대신하지 않습니다.

`install/install.bat`은 고정된 소스와 의존성을 자동 취득해 **Windows 네이티브 수정판을 소스 빌드**합니다. Qt 6.9.3, MinGW 13.1.0, Python 3.12.10 SDK, Lua 5.4.8, CMake 3.31.10과 Ninja 1.13.2를 프로젝트 안에 격리합니다. 외부 Git/Visual Studio/시스템 Python은 필요하지 않습니다. 최초 설치에는 수 GB와 상당한 빌드 시간이 필요합니다. 기본 병렬 작업 수는 2입니다.

상위 bootstrap가 upstream commit `8eeea944bf6f811a0ec679d294ff5e9d79d6141d`를 받고 overlay의 수정된 5개 소스를 적용합니다. 변경 내역은 `install/source-fixes.patch`입니다. Formula API에 맞춘 시험, 빈 반환값 보호, Python 모듈 재로딩 격리, 누락된 단일 통과 시험 설정을 수정했습니다. 기존 528개 이름을 보존한 532개 시험을 설치 시 모두 실행합니다. 시험을 제외하거나 기대값을 완화하지 않습니다. 실행 로그는 설치한 PC에서만 생성됩니다.

`launch.bat`으로 앱을 열고 [learning_examples/Readme.md](learning_examples/Readme.md)에서 대칭 공진기 실습을 시작하세요. 원본 설명은 `README.upstream.md`입니다.

reZonator 및 수정된 소스는 upstream GNU GPL v3 조건을 유지하며 저작권 헤더와 `LICENSE`를 함께 보존합니다. 이 공개 저장소는 Qt/MinGW/Python을 묶은 바이너리를 배포하지 않습니다. 의존성은 각각의 공식 배포처에서 설치 시 다운로드합니다. 각 의존성의 라이선스·고지는 다운로드한 소스/SDK에 포함되어 있습니다. 소스 수정은 같은 GPL 조건입니다.
