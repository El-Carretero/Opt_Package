# Luna.jl — 독립 설치 안내

## 버전과 출처

- 설치 준비 기준일: 2026-11-15 (Asia/Seoul).
- Luna 소스 버전: **0.6.2**.
- 고정 소스 commit: `7bc2f156feb0df62fdd48c5678cef2ade8fedd94`.
- 원본: https://github.com/LupoLab/Luna.jl
- Julia: **1.10.13**, Windows x64 portable 배포본. 프로젝트 호환 조건 Julia ≥1.9를 만족한다.
- Python: **3.11.15**, matplotlib용 독립 `.venv`. 전체 Python 의존성은 `install/python-requirements.lock.txt`에 기록한다.
- Julia 전체 의존성은 루트 `Manifest.toml`에 고정한다. 설치 검증 결과는 `install/logs/smoke.log`를 확인한다.
- 원본 사용 설명은 `README.upstream.md`에 보존했다.

## 장점

UPPE와 GNLSE를 지원하며 모드 평균·다중 모드 도파관, 원통 대칭과 전체 3+1차원 자유공간 전파를 다룰 수 있다. 분산, Kerr 효과, Raman 효과, 광이온화·플라스마와 파라미터 스캔 도구가 있다. 특히 가스 충전 중공 광섬유와 모세관 시뮬레이션의 고수준 인터페이스가 잘 갖추어져 있다.

## 단점과 적용 한계

레이저 이득, 반전 고갈, 열전도·열응력, 리젠의 스위칭 동역학을 자동으로 계산하는 전체 레이저 설계 도구는 아니다. 모드 평균 근사의 적합성은 사용자가 확인해야 한다. 고차원 계산은 메모리·시간이 많이 필요하며 저수준 예제 일부는 upstream에서도 유지보수를 보장하지 않는다. 이 설치의 작은 계산 검증은 모든 물리 모델의 정확성을 입증하지 않는다.

## 사용처

초단 펄스의 벌크·가스 비선형 전파, 포스트 압축, 초연속광, 중공 광섬유 및 자유공간 비선형 효과 분석. Ti:Sapphire 증폭기의 이득·펌프·열 계산은 별도 모델과 결합해야 한다.

## 실행

`launch.bat`를 열면 이 폴더 전용 Julia REPL이 열린다. 다음을 입력할 수 있다.

```julia
using Luna
output = prop_capillary(125e-6, 0.01, :He, 1;
    λ0=800e-9, energy=1e-6, τfwhm=30e-15,
    λlims=(200e-9, 2e-6), trange=400e-15, plasma=false)
```

첫 사용의 Julia 컴파일·FFT 계획에 시간이 걸릴 수 있다. 예제는 `examples`에 있다.

## 다른 PC에 재설치

1. 이 소스 폴더 전체를 복사한다. 용량을 줄이려면 생성물 `.venv`, `.python`, `.julia`, `.conda`, `.cache`, `runtime`을 제외할 수 있다. **소스·install·Project.toml·Manifest.toml은 보존한다.**
2. Windows x64 PC에서 `install/install.bat`를 실행한다. 인터넷에서 고정 Julia 및 Python 패키지를 받아 독립 환경을 구성한다. Julia ZIP은 SHA256으로 검사한다.
3. 설치 완료 뒤 `launch.bat`를 실행한다.

기존 `.venv`가 다른 경로에서 복사된 경우 설치 스크립트가 기존 환경을 `.venv.previous-날짜`로 보존한 뒤 이 프로젝트의 `.venv`를 다시 만든다. PyCall도 현재 경로의 Python으로 재빌드한다. 다른 폴더의 환경이나 시스템 PATH는 변경하지 않는다. 이 BAT는 Windows x64용이며 Linux/macOS에서는 해당 OS의 Julia를 설치하고 이 Project/Manifest를 사용해야 한다. 모든 OS에 대한 오프라인 설치 묶음은 아니다.

## 폴더 구조와 격리

- `runtime/julia-1.10.13`: 독립 Julia 실행 파일.
- `.julia`: 이 프로젝트 전용 Julia 패키지 depot와 컴파일 캐시.
- `.python`, `.venv`: 이 프로젝트 전용 Python 런타임과 matplotlib 환경.
- `.conda`: 필요시 Julia Conda가 사용할 전용 경로.
- `install`: 재설치 BAT/PowerShell, 다운로드, 버전 잠금, 검사 코드와 로그.

설치 시 원본 `deps/build.jl`을 전체 프로젝트에 강제 실행하지 않는다. 대신 `Pkg.instantiate()`로 의존성을 설치하고 PyCall을 독립 Python에 연결한다. 계산 소스는 수정하지 않았다.

## 검증

`install/smoke.jl`은 실제 GNLSE 솔버로 짧은 선형 분산 전파를 계산하고 출력이 유한하며 에너지가 0.1% 내에서 보존되는지 검사한다. 실행 기록은 `install/logs/smoke.log`에 저장된다.
