# HASEonGPU 2.1.1

공식 소스: https://github.com/ComputationalRadiationPhysics/haseongpu

장점: GPU/CPU 병렬 Monte Carlo 광선 추적 기반 ASE와 펌프·반전 상태 계산. 고에너지 벌크 증폭기 형상과 저장 에너지 손실 연구에 적합합니다.

단점: 코히런트 초단 펄스의 완전한 전파·증폭 시뮬레이터는 아닙니다. Windows 네이티브 지원은 실험적이므로 WSL2 Linux를 사용합니다.

설치: install/install.bat 실행. 독립 micromamba 환경과 CUDA 빌드 도구는 WSL의 ~/.local/share/Opt_Package/HASEonGPU에 설치합니다. 시스템 Python·CUDA 설치를 변경하지 않습니다. 소스 원본은 이 폴더이며 빠른 빌드를 위해 Linux에 소스를 복사합니다. 수정 후 재설치하면 복사가 갱신됩니다.

실행: launch.bat으로 전용 환경 셸을 열고 Python에서 import HASEonGPU를 사용합니다.

버전: 소스 2.1.1, commit f7d7494f96fc9138e2d476021087fc8ff9fe6913. 원문 문서는 README.upstream.md에 보존합니다. 의존성의 정확한 버전은 install/conda-linux-64.lock 및 install/pip-freeze.txt에 기록됩니다.

재설치에는 WSL2 Ubuntu(기본 Ubuntu-24.04)와 인터넷이 필요합니다. 다른 배포판은 OPT_PACKAGE_WSL_DISTRO 환경 변수로 선택합니다. 가상환경 자체를 복사하는 대신 소스 폴더를 복사한 뒤 BAT를 실행하세요. 검증 로그는 install/logs에 보관합니다.

WSL이 없는 새 PC에서는 관리자 터미널에서 wsl --install -d Ubuntu-24.04를 실행하거나 install/prepare-wsl.bat을 관리자 실행합니다. 필요시 재부팅하고 Ubuntu를 열어 Linux 사용자를 만든 뒤 install/install.bat을 다시 실행합니다. GPU 실행에는 Windows의 NVIDIA 드라이버가 필요하며 CUDA Toolkit은 이 프로젝트의 Linux 가상환경에만 설치합니다.

현재 설치: CUDA Toolkit 12.9, GCC 13.4, CPU/OpenMP/TBB 및 CUDA 백엔드, openPMD 0.17.1의 HDF5/ADIOS 기능을 사용합니다. MPI는 비활성화했습니다. 새 PC에서는 NVIDIA GPU를 감지하여 native 아키텍처로 다시 빌드하고, 보이는 NVIDIA GPU가 없으면 CPU 백엔드로 빌드합니다. 의존성 lock은 GPU 도구까지 포함하므로 CPU 컴퓨터에서도 도구의 디스크 공간은 사용합니다. build backend scikit-build-core 1.1.2도 고정했습니다.

검증: 6개 샘플 지점에서 각 64개 Monte Carlo 광선으로 실제 ASE 계산을 CPU와 RTX 4060 CUDA 양쪽에서 수행했습니다. 모든 결과가 유한하고 양수이며 샘플당 광선 수를 확인했습니다. 계산 정확도를 보증하는 수렴 연구는 아니며 작은 설치 확인용 문제입니다. install/logs/numerical-smoke.log와 smoke-results.json 참조. 전체 소스 빌드 로그는 install/logs/build.log, 의존성 설치 로그는 install/logs/install.log에 있습니다. install/logs/reinstall-dry-run.json은 lock 기반 재설치 검토 성공 기록입니다.

공개 패키지 재설치: `OPT_PACKAGE_WSL_DISTRO`로 배포판(기본 Ubuntu-24.04), `OPT_PACKAGE_WSL_USER`로 선택적 Linux 사용자를 지정합니다. 기본값은 해당 배포판의 기본 사용자입니다. 환경은 `~/.local/share/Opt_Package` 아래에 새로 생성되며 `OPT_PACKAGE_STATE_ROOT`로 Linux 경로를 지정할 수 있습니다. 새 Windows PC의 WSL 기능 활성화·재부팅·첫 사용자 생성은 `install/prepare-wsl.bat` 안내를 따른 후 재실행합니다. conda explicit lock에는 정확한 아티팩트 URL과 체크섬이 있습니다.
