# OPOSSUM 0.8.1

공식 저장소: https://github.com/opossum-labs/opossum

장점: 광학계를 계층적 그래프로 구성하고 에너지 흐름, 광선, ghost focus를 함께 분석할 수 있습니다. 대형 레이저 시스템 구조를 설계하고 자체 시스템 모델의 구조를 참고하기에 좋습니다.

단점: 초기 연구 개발 단계이며 API와 파일 형식이 바뀔 수 있습니다. 소신호·상수 이득 모델을 반전 고갈 및 포화 증폭의 시간 동역학 모델로 해석하면 안 됩니다. 재생 증폭기 전체 펄스 에너지 예측에는 추가 모델이 필요합니다.

사용처: 전체 레이저 체인 구성, 광학 경로와 손실·에너지 예산 검토, ghost focus 위험 위치 분석.

설치 버전: 공식 Windows GUI/CLI 0.8.1 (2026-10-07), 소스 commit 565a9e66663fe650607b31c4dfed093657b809ce. Graphviz 14.1.5를 보고서 그래프 생성용으로 함께 격리 설치합니다.

실행: launch.bat. 명령행 계산기는 runtime/OpossumGui/opossum_cli.exe이며 --help로 옵션을 확인합니다. 공식 Kepler telescope 예제를 install/smoke.ps1로 계산할 수 있습니다.

재설치: 이 소스 폴더 전체를 다른 Windows x64 컴퓨터에 복사하고 install/install.bat을 실행합니다. MSI를 관리자 설치하지 않고 runtime으로 관리용 추출합니다. Python 프로그램이 아니므로 Python venv 대신 프로젝트 전용 portable runtime으로 라이브러리를 분리합니다. 시스템 PATH나 다른 Python 환경을 변경하지 않습니다. 실제 Rust 소스 개발에는 별도 Rust/C++ 개발 도구가 필요하며 공식 배포 바이너리 실행에는 필요하지 않습니다.

install 폴더의 스크립트는 공식 MSI와 Graphviz ZIP을 자동 다운로드하고 고정 SHA256을 검사합니다. 검증 결과는 실행한 PC에서 생성됩니다. 원본 README는 README.upstream.md에 보존했습니다. 설치된 가상환경을 그대로 복사해서 실행하는 방식보다 BAT로 환경을 재구성하는 방식을 권장합니다.

검증: 공식 workshop_00_kepler_paraxial.opm을 CLI로 해석하여 보고서 생성 성공. 결과 위치 install/smoke-reports, 로그 install/smoke.log.

GUI 선행 조건: Microsoft Edge WebView2 Runtime이 필요합니다. 설치 스크립트는 기존 WebView2를 재사용하며, 없으면 공식 Microsoft 설치 파일의 고정 SHA256과 서명을 검사한 다음 현재 사용자용 Runtime을 자동 설치합니다. 이 선행조건은 Windows 사용자 환경에 설치되며 OPOSSUM portable 폴더와 별개입니다. 기존 버전은 강제로 바꾸지 않습니다. Visual C++ 런타임은 Graphviz portable bin에 포함되어 있으며 launcher가 해당 디렉터리를 현재 프로세스 PATH에 추가합니다. 공식 안내: https://developer.microsoft.com/microsoft-edge/webview2/
