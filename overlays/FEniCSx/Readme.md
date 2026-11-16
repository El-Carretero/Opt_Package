# FEniCSx / DOLFINx 0.11.0

공식 저장소: https://github.com/FEniCS/dolfinx

장점: 유한요소법과 변분 형식으로 열전도, 탄성·응력 등 PDE를 구현하며 PETSc와 MPI를 활용할 수 있습니다. 재료·형상·경계조건을 직접 구성하는 연구에 유연합니다.

단점: 레이저용 열·응력·굴절률 결합 모델을 제공하는 완성 앱은 아닙니다. 재료 물성, 열원과 냉각·지지 조건, 응력광학 결합을 사용자가 구성해야 합니다. Windows 네이티브 conda 패키지는 beta이며 PETSc 제약이 있어 이 설치는 WSL2 Linux를 사용합니다.

사용처: Ti:Sapphire·Nd:YLF 결정의 온도장, 열응력, 표면 변형과 열렌즈 계산에 필요한 PDE 솔버.

버전: 소스 tag v0.11.0.post0 / commit fefdb2201b80a8f59527de2d461b9056906661d8. 실행 패키지는 conda-forge DOLFINx 0.11.0, Python 3.12, PETSc 3.25.6. 정확한 모든 의존성은 install/conda-linux-64.lock의 URL·해시로 고정합니다.

설치: install/install.bat. 기존 WSL2 Ubuntu-24.04에 프로젝트 전용 micromamba 환경을 만들며 전역 apt/Python 패키지를 변경하지 않습니다. 환경 위치는 ~/.local/share/Opt_Package/FEniCSx/env이고 캐시와 bootstrap도 같은 프로젝트 상태 디렉터리에 있습니다. 실제 위치는 install/wsl-env-path.txt에 기록합니다.

실행: launch.bat으로 전용 환경 셸을 열고 python을 실행합니다. source 코드는 이 Desktop 폴더에 보관되며 conda 패키지를 실행합니다. Windows Python에서 직접 import하지 않습니다.

이동·재설치: 이 소스 폴더 전체를 다른 PC로 복사한 뒤 WSL2 Ubuntu를 준비하고 install/install.bat을 실행합니다. 네트워크가 필요합니다. 배포판 이름이 다르면 OPT_PACKAGE_WSL_DISTRO를 설정합니다. Linux 단독 컴퓨터에서는 bash install/install-wsl.sh로 설치할 수 있습니다. 바이너리 가상환경 자체를 복사하지 않고 lock 파일로 재생성합니다.

검증: 2차 유한요소를 사용해 단위 정사각형의 2D Poisson 방정식을 풀고 정확해 x²+y²와 비교했습니다. L2 오차 5.437e-15로 통과했습니다. install/smoke.py 및 install/logs/smoke.log 참고. 원문 문서는 README.upstream.md에 보존합니다.

WSL이 없는 새 PC에서는 관리자 터미널에서 wsl --install -d Ubuntu-24.04를 실행하거나 install/prepare-wsl.bat을 관리자 실행합니다. Windows가 요구하면 재부팅하고 Ubuntu를 처음 열어 Linux 사용자를 만든 다음 install/install.bat을 다시 실행합니다. 

공개 패키지 재설치: `OPT_PACKAGE_WSL_DISTRO`로 배포판(기본 Ubuntu-24.04), `OPT_PACKAGE_WSL_USER`로 선택적 Linux 사용자를 지정합니다. 기본값은 해당 배포판의 기본 사용자입니다. 환경은 `~/.local/share/Opt_Package` 아래에 새로 생성되며 `OPT_PACKAGE_STATE_ROOT`로 Linux 경로를 지정할 수 있습니다. 새 Windows PC의 WSL 기능 활성화·재부팅·첫 사용자 생성은 `install/prepare-wsl.bat` 안내를 따른 후 재실행합니다. conda explicit lock에는 정확한 아티팩트 URL과 체크섬이 있습니다.
