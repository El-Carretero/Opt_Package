# LightPipes 설치 안내

- 고정 배포 설정: Opt_Package의 manifest 및 이 폴더의 install/config.json
- 실행 패키지: `LightPipes 2.1.5`
- Python: `3.12.12`, 각 폴더의 `.venv`로 격리
- 소스: https://github.com/opticspy/lightpipes
- 소스 commit: `cd965c9469bb53bbae2bf185d38c1107408cd5b5`
- 설치 방식: 보관된 소스의 editable 설치

## 장점

Gaussian 빔, 개구, 회절, FFT·Fresnel 전파를 Python에서 간결하게 조합한다.

## 단점과 모델의 범위

기본적으로 scalar 파동광학 모델이다. 펄스 시간 동역학, 포화증폭과 반전분포는 추가 모델이 필요하다.

## 사용처

빔 전달, 회절 손실, 개구와 열파면이 공간 빔에 미치는 영향 계산.

## 기초 광학 실습 — 학습 순위 3

[Gaussian 전파·이중 슬릿 예제 안내](learning_examples/Readme.md)를 읽고 [learning_examples/RUN.bat](learning_examples/RUN.bat)을 실행한다. 설치된 가상환경의 FFT 계산으로 빔 확산과 간섭무늬를 확인하고 해석식·격자 변화와 비교한다. 예제 소스와 대표 그림을 포함하며, 수치 결과와 검증 기록은 실행할 때 생성한다. 전체 학습 순서는 [Opt_sim 학습 안내](https://github.com/El-Carretero/Opt_Package/blob/main/docs/LEARNING_GUIDE.md)를 참조한다.

## 설치 및 다른 컴퓨터로 옮기기

이 프로젝트 폴더 전체를 복사하고 `install\install.bat`를 실행한다. Windows x64와 인터넷 연결이 필요하다. 관리자 권한이나 시스템 Python 변경 없이 폴더 내부 `.runtime`에 Python, `.venv`에 의존성을 설치한다. `.venv`는 경로에 종속되므로 다른 경로/컴퓨터로 복사할 때 기존 `.venv`를 제외하고 복사하면 공간을 절약할 수 있다. BAT는 `.venv`의 이전 Python 경로를 감지하면 `.venv.previous-날짜시간`으로 보관하고 현재 위치에서 환경을 재생성한다. `install\requirements.lock.txt`는 의존성 버전을 고정하며 `install\installed-metadata.json`은 소스 commit과 전체 버전을 기록한다. 패키지 다운로드 서버가 유지되어야 하며 완전한 오프라인 설치 묶음은 아니다. Linux/macOS는 이 BAT의 실행 대상이 아니다.

- `Activate.bat`: 이 프로젝트의 가상환경 터미널
- `Run-smoke-test.bat`: 짧은 계산 검증 재실행
- `install\logs\install.log`: 설치·의존성·계산 검증 로그
- `install\smoke_test.py`: 검증 계산 코드

원 저자 설명과 라이선스는 `README.upstream.md` 또는 `README.rst` 및 `LICENSE`를 확인한다. 이 설치의 smoke test는 실행 가능성을 확인하며 과학 모델 전체의 검증을 뜻하지 않는다.

## Opt_Package 배포 안내

상위 Opt_Package 설치기가 manifest의 정확한 소스 commit을 다운로드한 뒤 이 overlay를 적용합니다. 이 overlay 폴더만으로는 원본 소스가 없어 설치할 수 없습니다. 설치기는 uv 0.11.6의 ZIP과 실행 파일 SHA256을 검사하고, Python 3.12.12를 프로젝트 폴더에 받습니다. `--no-bin --no-registry`를 사용해 시스템 PATH와 Python 등록을 변경하지 않습니다. 기존 lock은 설치 후에도 덮어쓰지 않고 실제 설치 목록을 `install/logs/installed-requirements.txt`에 별도 기록합니다. 캐시·가상환경·다운로드한 실행 파일·개인 실행 로그는 GitHub 배포에 포함하지 않습니다.
