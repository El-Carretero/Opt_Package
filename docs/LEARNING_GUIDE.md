# 광학 시뮬레이션 학습 순서

이 안내는 Opt_Package의 **2026-11-16 스냅샷에 포함된 18개 도구**를 대상으로 한다. 기초 개념의 선행 관계, 실습 난이도, 벌크 레이저 광학계 설계 목표와의 관련성을 기준으로 순서를 정했다. 같은 역할의 도구는 하나를 익힌 뒤 비교하고, 이득·비선형·열·ASE 모델은 그 이후에 배치했다.

아래 링크는 GitHub에서 읽는 설명과 설치에 사용될 overlay 파일이다. **overlay만으로 프로그램이 실행되지는 않는다.** 먼저 [저장소 설치 안내](../README.md)에 따라 필요한 도구를 설치한 뒤, 설치 대상 폴더의 `<도구 이름>\learning_examples\RUN.bat`을 실행한다. 설치기는 원본 소스에 overlay를 적용하고 각 도구의 실행환경을 만든다.

## 먼저 할 세 가지

**Optiland → reZonator → LightPipes** 순서로 진행한다. 세 예제는 모두 선형 기초 광학을 다룬다. Python이나 프로그램 사용법에 익숙하지 않아도 먼저 기본값으로 실행하고 그림을 읽을 수 있도록 한국어 안내와 실행기를 포함했다.

| 순서 | 도구와 예제 안내 | 직접 볼 현상 | 실행기 소스 |
|---|---|---|---|
| 1 | [Optiland: 양볼록 렌즈](../overlays/Optiland/learning_examples/README.md) | 평행 광선의 굴절, 초점, 렌즈 두께와 초점거리 | [RUN.bat](../overlays/Optiland/learning_examples/RUN.bat) |
| 2 | [reZonator: 두 거울의 수동 공진기](../overlays/reZonator/learning_examples/Readme.md) | ABCD 행렬, 안정성, Gaussian 빔의 허리와 반경 | [RUN.bat](../overlays/reZonator/learning_examples/RUN.bat) |
| 3 | [LightPipes: Gaussian 전파와 이중 슬릿](../overlays/LightPipes/learning_examples/Readme.md) | 빔의 회절 확산, 강도 분포, 간섭무늬 | [RUN.bat](../overlays/LightPipes/learning_examples/RUN.bat) |

설치 후 Windows 탐색기에서 각 `RUN.bat`을 더블클릭한다. Optiland와 LightPipes는 수치 결과와 PNG 그림을 생성하고, reZonator는 준비한 `.rez` 프로젝트를 로컬 앱으로 연다. 각 안내에 매개변수, 단위, 기대 결과, 직접 바꿔 볼 항목과 재검증 방법을 적었다. 다른 컴퓨터에서는 [설치 안내](../README.md)의 명령으로 환경을 새로 만든다.

### 1. Optiland — 렌즈에서 빛이 꺾이고 모이는 과정

굴절률 1.5, 앞뒤 곡률반경 +50/−50 mm, 중심 두께 5 mm인 렌즈에 평행 광선을 입사시킨다. 먼저 [광선 그림](../overlays/Optiland/learning_examples/output/single_lens_rays.png)을 읽고, 입력값을 하나씩 바꾸면서 초점이 이동하는 이유를 설명해 본다.

두꺼운 렌즈의 유효 초점거리(EFL)는 약 **50.8475 mm**, 마지막 면 꼭짓점에서 재는 후초점거리(BFL)는 약 **49.1525 mm**다. 두 값은 기준점이 다르다. 얇은 렌즈 근사에서 얻는 50 mm와도 구분한다. 광축 가까이 지나는 광선과 가장자리 광선이 정확히 같은 위치에 모이지 않는 모습도 확인한다.

학습 목표: 렌즈 면의 곡률 부호와 단위를 읽고, 근축 초점과 실제 광선의 교차 위치를 구분할 수 있다. 굴절률은 상수로 두므로 재료의 분산은 이번 실습에 포함하지 않는다.

### 2. reZonator — Gaussian 빔과 공진기 기하

곡률반경 200 mm인 두 오목거울을 100 mm 간격으로 두고, 파장 632.8 nm에서 안정성과 빔 반경을 본다. `g₁ = g₂ = 0.5`, `g₁g₂ = 0.25`인 안정한 예다. 빔 허리는 두 거울의 가운데에 생긴다. [공진기 예제 미리보기](../overlays/reZonator/learning_examples/preview.png)를 본 뒤 거울 간격을 바꾸면 안정성과 빔 반경이 어떻게 달라지는지 관찰한다.

학습 목표: `0 < g₁g₂ < 1`인 일반적인 안정 영역을 이해하고, 공진기 길이와 빔 반경을 혼동하지 않는다. 이 예제는 수동 공진기의 Gaussian 고유모드만 계산하며, 실제 레이저의 출력·이득·발진 임계값은 계산하지 않는다. 경계와 퇴화 배치의 해석은 개별 예제 안내를 따른다.

### 3. LightPipes — 광선 그림에서 파동의 강도 분포로

파장 632.8 nm, 초기 반경 0.5 mm인 Gaussian 빔을 FFT로 전파한다. 여기서 반경은 **강도가 중심값의 1/e²가 되는 반경**이다. Rayleigh 길이 약 1.24115 m에서 반경이 약 0.707107 mm가 되는지 해석식과 비교한다. [공간 분포](../overlays/LightPipes/learning_examples/output/01_gaussian/01_beam_maps.png)와 [반경·단면 그래프](../overlays/LightPipes/learning_examples/output/01_gaussian/02_radius_and_profiles.png)를 함께 본다.

이어 [이중 슬릿의 간섭무늬](../overlays/LightPipes/learning_examples/output/02_double_slit/01_double_slit_fft.png)를 보고 슬릿 간격과 무늬 간격의 관계를 확인한다. 학습 목표는 진폭과 강도, 빔의 반경과 지름, 회절 포락선과 간섭무늬를 구분하는 것이다. 계산 창 크기와 격자 간격을 바꾸어 수치 결과가 안정적인지도 살펴본다.

## 기본값으로 기대할 결과

아래 값은 예제의 입력값과 해석식으로 확인할 기준이다. 각 예제의 검증 코드는 실행할 때 실제 계산과 다시 비교한다. 수치 일치도를 실제 부품의 제조 정확도나 실험 오차로 해석하지 않는다.

| 예제 | 기대값과 확인할 내용 | 실행 후 생성되는 기록 |
|---|---|---|
| Optiland 양볼록 렌즈 | EFL 50.8474576 mm, BFL 49.1525424 mm. 두꺼운 렌즈 해석식과 비교하고, 축 근처 실광선의 초점이 근축 초점에 가까운지 검사한다. | `Optiland/learning_examples/output/summary.json` |
| reZonator 수동 공진기 | 허리 반경 132.075911 µm, 거울에서 152.508125 µm. T/S 두 방향의 빔 반경과 안정도 표본을 해석식과 비교한다. | `validate_native.bat` 실행 후 `reZonator/learning_examples/validation/latest.json` |
| LightPipes Gaussian 전파 | Rayleigh 길이 약 1.241148 m, 그 위치의 반경 약 0.707107 mm. 반경 해석식 일치, 격자 증가, 계산창 경계와 적분 세기를 검사한다. | `LightPipes/learning_examples/output/01_gaussian/validation.log` |
| LightPipes 이중 슬릿 | 간섭의 cos² 주기 0.6328 mm, 단일 슬릿 포락선의 첫 영점 ±2.5312 mm. 세기 해석식, 격자 증가와 샘플링을 검사한다. | `LightPipes/learning_examples/output/02_double_slit/validation.log` |

개인 실행 로그·CSV·JSON은 저장소에 넣지 않았다. 위 경로는 설치 대상 폴더 기준이며 실행 후 확인할 수 있다. 대표 PNG와 검증 코드는 저장소에 포함되어 있다. reZonator의 기본 `RUN.bat`은 예제를 여는 실행기이고, 계산 검증은 별도의 `validate_native.bat`으로 수행한다.

## 도구 전체의 권장 우선순위

4위 이후는 위 세 실습을 마친 뒤 필요한 과제에 맞춰 선택한다. 각 도구의 세부 버전·장단점·설치 방식은 연결한 README에 있다.

| 순위 | 도구 | 다음에 배울 내용과 배치 이유 |
|---:|---|---|
| **1** | [Optiland](../overlays/Optiland/Readme.md) | 렌즈와 굴절·초점을 그림과 수치로 연결하기 좋다. 이 예제는 NumPy CPU 경로를 사용한다. |
| **2** | [reZonator](../overlays/reZonator/Readme.md) | GUI에서 ABCD·Gaussian 빔·공진기 안정성을 익힌다. 레이저 광학계의 초기 설계와 직접 연결된다. |
| **3** | [LightPipes](../overlays/LightPipes/Readme.md) | 짧은 Python 코드로 회절·간섭·공간 전파를 배운다. 1–2번의 광선·Gaussian 근사를 파동 계산과 연결한다. |
| 4 | [RayOptics](../overlays/RayOptics/Readme.md) | 광선 광학과 렌즈 설계를 다른 도구로 비교한다. Optiland와 겹치는 부분은 복습으로 활용한다. |
| 5 | [Diffractio](../overlays/Diffractio/Readme.md) | LightPipes 다음에 다른 회절 전파 방법과 벡터장으로 확장한다. |
| 6 | [OPOSSUM](../overlays/OPOSSUM/Readme.md) | 개별 소자의 의미를 익힌 뒤 전체 광학계의 연결·광선·에너지·ghost를 모델링한다. |
| 7 | [TorchOptics](../overlays/TorchOptics/Readme.md) | 파동광학을 이해한 뒤 GPU와 자동미분을 이용한 설계·최적화로 나아간다. |
| 8 | [NPAmp](../overlays/NPAmp/Readme.md) | 벌크 증폭기의 반전·포화·펄스 에너지 모델을 공부한다. 구형 실행환경과 4준위 모델의 가정을 먼저 확인한다. |
| 9 | [modelock_sim](../overlays/modelock_sim/Readme.md) | Gaussian 공진기와 이득·Kerr 효과를 공부한 다음 Ti:Sapphire 모드잠금 동역학으로 진행한다. |
| 10 | [Luna.jl](../overlays/Luna.jl/README.md) | 분산과 펄스 개념을 익힌 뒤 비선형 전파·후단 압축을 다룬다. Julia 환경도 함께 익혀야 한다. |
| 11 | [pychi](../overlays/pychi/Readme.md) | 위상정합과 비선형 감수율을 공부한 뒤 χ²·χ³ 과정으로 확장한다. |
| 12 | [PyNLO](../overlays/PyNLO/Readme.md) | 비선형 펄스 전파 알고리즘을 비교한다. 구형 의존성을 사용하므로 먼저 설치된 환경 안에서 실습한다. |
| 13 | [Elmer](../overlays/Elmer/Readme.md) | 광학 다음에 열전도·구조 FEM을 익히고 결정의 열 문제로 진행한다. 재료값과 경계조건을 별도로 준비해야 한다. |
| 14 | [FEniCSx](../overlays/FEniCSx/Readme.md) | PDE와 유한요소의 수학을 익힌 뒤 필요한 열·응력 모델을 코드로 구성한다. |
| 15 | [HASEonGPU](../overlays/HASEonGPU/Readme.md) | 이득·반전·ASE를 이해한 뒤 고에너지 증폭기의 ASE 손실을 계산한다. 기초 광학 이후의 전문 단계다. |
| 16 | [PyFiberAmp](../overlays/PyFiberAmp/Readme.md) | 광섬유를 다룰 때 펌프·신호·ASE 정상상태 모델부터 공부한다. 현재 벌크 레이저 목표에서는 후순위다. |
| 17 | [pyLaserPulse](../overlays/pyLaserPulse/Readme.md) | 광섬유 이득과 분산·비선형 펄스 전파를 함께 다룰 때 진행한다. |
| 18 | [KLM-Sim](../overlays/KLM-Sim/Readme.md) | 모드잠금 알고리즘의 비교·참고용으로 둔다. 이 배포의 검증 범위는 Octave 핵심 함수이며 전체 MATLAB GUI는 검증되지 않았다. |

## 다음 단계로 넘어가는 기준

1. Optiland: EFL과 BFL의 기준점을 설명하고, 곡률이나 개구를 바꾸었을 때의 광선 그림을 예상할 수 있다.
2. reZonator: 거울 간격을 바꾸어 안정성을 판단하고, 빔 허리의 위치와 반경을 읽을 수 있다.
3. LightPipes: Gaussian 반경의 증가와 이중 슬릿 무늬 간격을 식으로 예상하고, 수치 격자 변화가 결과에 주는 영향을 확인할 수 있다.

## 참고 자료와 버전 기준

이 순서는 벌크 레이저 광학계 설계를 목표로 한 학습 제안이다. 예제 API와 수치는 [고정 버전 목록](../packages.lock.json)의 버전을 기준으로 작성했다. 공식 사이트의 최신 예제는 이 버전과 다를 수 있다.

- [Optiland 공식 문서](https://optiland.readthedocs.io/en/latest/): 광선 추적·렌즈 모델링과 학습 자료.
- [reZonator 공식 저장소](https://github.com/orion-project/rezonator2): ABCD, 단일 통과 광학계, 공진기 안정성과 Gaussian 빔 기능.
- [LightPipes 2.1.5 공식 문서](https://opticspy.github.io/lightpipes/): 자유공간 전파, 간섭·회절 예제와 API.

각 `learning_examples`의 한국어 안내에서 모델의 가정, 단위, 검산 기준과 실패했을 때의 점검 방법을 확인한다.
