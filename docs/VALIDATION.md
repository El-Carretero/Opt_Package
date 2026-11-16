# 설치 패키지 검증 기록

기준일: 2026-11-16, Windows x64 / Windows PowerShell 5.1. 기존에 검증된 Opt_sim의 실행환경은 보존하고, 별도 폴더에서 설치 패키지를 검사했다.

## 이번에 새로 확인한 것

| 대상 | 결과와 범위 |
|---|---|
| 원본 소스 18개 | 공개 upstream의 full commit ZIP을 모두 실제 다운로드. 총 약 394.87 MiB. 각 SHA256을 `packages.lock.json`에 기록 |
| 중앙 `-PrepareOnly` | 공백을 포함한 새 경로에서 18/18 소스 압축 해제·overlay 적용 성공 |
| Windows 심볼릭 링크 | FEniCSx의 Unix 파일 링크가 Windows tar에서 실패하는 문제 발견. 링크 대상이 압축 내부인지 검사한 뒤 동일 내용을 일반 파일로 복사하도록 수정. 18개 전체 준비 재검증 통과 |
| 설치기 회귀 검사 | `tests/installer.tests.ps1`의 21개 판정 통과. 소스/문서 보존, 심볼릭 링크, 손상 checksum 거부, 기존 사용자 폴더 보호, 오류 전파, 다음 도구 계속 설치, 실패 후 재개, 완료 항목 건너뛰기, 명시적 재설치, 다른 스냅샷 차단 |
| LightPipes | 새 원본 소스 + overlay + 새 Python 3.12.12/.venv에서 설치·의존성 검사·FFT 계산 통과. 예제 실행기의 Gaussian 6개와 이중 슬릿 7개, 총 13개 수치 판정 통과 |
| PyNLO | 새 소스·uv·Python 3.10.20·패키지 설치, editable build, pip check, SSFM의 1e-12 J 계산 통과 |
| modelock_sim | 새 소스·런타임·고정 패키지 126개 설치, CPU DLL 빌드, Kerr 3회 왕복 및 HTTP 200 검증 통과 |
| OPOSSUM | 새 소스 + overlay에서 공식 MSI·Graphviz 취득/해시 확인과 실제 Kepler 광학계 계산 통과 |
| NPAmp | 새 경로에 공식 실행 패키지를 다운로드·추출하고 실제 증폭 계산 통과. 기존 OS의 VC90 Runtime을 사용했으며 관리자 재배포기 설치 분기는 실행하지 않음 |
| reZonator 새 빌드 준비 | 빈 경로에서 소스·submodule 두 개·Python SDK·고정 pip 패키지·Qt 6.9.3·MinGW 13.1.0을 취득/검증. Lua 정적 라이브러리 빌드와 CMake configure/generate 통과. 이번에는 전체 C++ 재컴파일을 반복하지 않음 |
| Git 없는 Python 소스 배포 | Optiland 0.6.3+local, RayOptics 0.9.10, TorchOptics 1.0.2의 archive + overlay wheel build 성공. Git 메타데이터 없이 정확한 버전 산출 |

생성 로그에는 새 PC의 설치 경로 등이 들어가므로 공개 저장소에 복제하지 않는다. 실제 설치 시 해당 PC의 `.opt-package/logs`와 도구별 `install` 로그에 다시 기록된다.

## 검증 범위의 구분

이 컴퓨터의 기존 Opt_sim에서는 18개 도구의 기본 동작을 확인했고, reZonator 수정판의 전체 자체 검사 **532/532**도 통과했다. 이번 패키지 작업에서는 다운로드·이식·경로 독립성을 추가로 검사했다. 모든 도구를 초기화된 별도 Windows OS에서 다시 설치한 시험은 수행하지 않았다.

- 기존 OS에 WebView2와 VC++ 2008 Runtime이 이미 있어, **그 선행조건이 전혀 없는 OS에서의 설치 분기**는 직접 실행하지 않았다. 설치기는 필요한 공식 파일의 해시를 검사하고, NPAmp의 관리자 설치는 `-InstallPrerequisites`를 명시했을 때만 실행한다.
- WSL 최초 설치·재부팅·Linux 사용자 생성, GPU 드라이버 설치는 이 검사에 포함하지 않는다. 기존 WSL 설정을 초기화하지 않았다.
- 기존에 통과한 GPU 검사는 새 PC의 GPU까지 보장하지 않는다. 장치가 없으면 CPU 경로나 명확한 제한 안내를 따른다.
- 버전 고정은 배포처의 영구 가용성을 보장하지 않는다. 다운로드가 사라지거나 해시가 달라지면 임의의 최신 버전으로 대체하지 않는다.

## 직접 다시 확인하기

```powershell
# 인터넷 없이 중앙 설치기 동작 검사: 임시 폴더의 작은 fixture를 사용
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\installer.tests.ps1

# 실제 고정 소스 준비 검사
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Destination 'D:\Opt_sim_verify' -PrepareOnly

# 하나를 골라 실제 설치 및 포함된 계산 검사
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Destination 'D:\Opt_sim_verify' -Projects LightPipes
```

reZonator의 설치기는 빌드 후 532개 자체 검사를 실행한다. 기초 예제의 검증은 각 `learning_examples/Readme.md`를 따른다.
