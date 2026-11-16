# Elmer FEM 26.2-devel (11c118114)

공식 저장소: https://github.com/ElmerCSC/elmerfem

장점: 열전도·구조역학·유동·전자기장 등 다양한 PDE를 결합하며 GUI와 명령행 솔버, 메쉬 도구를 제공합니다. 벌크 결정의 열과 변형을 계산하는 데 활용할 수 있습니다.

단점: 레이저 열원과 냉각, 결정의 재료 물성·비등방성, 응력광학 및 광학 전파와의 결합은 사용자가 모델링해야 합니다. 이 설치는 Windows nompi 바이너리로 OpenMP 스레드를 지원하지만 MPI 분산 실행은 포함하지 않습니다.

사용처: 결정 온도장, 열응력, 변형, 열렌즈 모델의 열·구조 부분, 다중물리 검증.

버전: 공식 Windows portable nompi 개발 빌드 26.2-devel, 2026-09-17, commit 11c118114ba44bdcf732d087144dd4d0c3098b4f. 소스도 이 바이너리의 commit에 맞추었으며 Zoltan 하위 모듈을 포함합니다. 최신 안정판 소스 tag는 release-26.2.1이지만 설치된 공식 Windows 바이너리는 위 개발 빌드입니다.

실행: launch.bat으로 ElmerGUI 실행. 명령행 계산기는 runtime 아래 bin/ElmerGrid.exe, ElmerSolver.exe입니다. launch.bat이 현재 프로세스의 ELMER_HOME과 PATH만 설정합니다.

재설치: 이 소스 폴더 전체를 다른 Windows x64 PC에 복사하고 install/install.bat을 실행합니다. 공식 ZIP을 runtime으로 해제하며 시스템에 등록하거나 기존 환경을 변경하지 않습니다. Python 프로그램이 아니므로 Python venv 대신 전용 portable runtime으로 격리합니다. Qt와 MinGW 실행 라이브러리가 공식 ZIP에 포함됩니다. ZIP이 없으면 인터넷으로 같은 파일을 다운로드합니다. SHA256은 install/package.sha256에 보관합니다.

검증: 공식 HeatAniso 예제에서 1001개 절점·900개 요소의 비등방성 열전도와 열유속을 계산했습니다. 원본 참조 norm 비교 2개 모두 통과했으며 상대 오차는 각각 4.95e-10, 4.15e-10입니다. 재검증은 install/smoke.ps1, 결과는 install/smoke-HeatAniso에 있습니다. 원본 설명은 README.adoc에 보존됩니다.
