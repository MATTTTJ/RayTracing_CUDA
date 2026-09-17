# Raytracing_CUDA

CUDA 프로젝트 환경에서 C++로 *Ray Tracing in One Weekend*를 따라 구현하는 학습 프로젝트입니다.
현재 렌더링 계산은 CPU에서 실행되며, CUDA를 이용한 병렬 처리로 확장할 예정입니다.

## 진행 상황

현재 5장까지 구현했습니다.

| 단계 | 학습 내용 | 상태 | 학습 노트 |
|---|---|:---:|---|
| 환경 설정 | CUDA와 Visual Studio 프로젝트 구성 | 완료 | [Notion](https://app.notion.com/p/CUDA-3dd834e5c09e8023a2a5f921f7dc66c1?pvs=25) |
| 1장 | 개요 | 완료 | [Notion](https://app.notion.com/p/1-3dd834e5c09e80d08fc5dffc6284c204?pvs=25) |
| 2장 | 이미지 출력 | 완료 | [Notion](https://app.notion.com/p/2-Output-an-Image-3dd834e5c09e80fdb4e3ec7fde86424b?pvs=25) |
| 3장 | `vec3` 클래스 | 완료 | [Notion](https://app.notion.com/p/3-The-vec3-Class-vec3-3dd834e5c09e803092dcf9497580336c?pvs=25) |
| 4장 | 광선, 간단한 카메라와 배경 | 완료 | [Notion](https://app.notion.com/p/4-Rays-a-Simple-Camera-and-Background-3dd834e5c09e80138df5eab29d5c1eec?pvs=25) |
| 5장 | 구 추가하기 | 완료 | [Notion](https://app.notion.com/p/5-Adding-a-Sphere-3de834e5c09e806ea050f087ad2ee9ce?pvs=25) |

전체 학습 노트는 [Notion 목차](https://app.notion.com/p/Ray-Tracing-By-On-Weekends-3dd834e5c09e80dfa4a4fedac42ddb07)에서 볼 수 있습니다.

## 현재 구현 내용

- PPM 이미지 출력
- 3차원 벡터와 색상 연산
- 광선 표현과 위치 계산
- 핀홀 카메라와 픽셀 광선 생성
- 흰색과 파란색의 배경 그라디언트
- 광선과 구의 교차 판정
- 첫 번째 빨간 구 렌더링

## 개발 환경

- Windows
- Visual Studio Community 2022
- C++17
- CUDA Toolkit 13.x
- NVIDIA GPU

현재 프로젝트의 CUDA 코드 생성 설정은 `compute_120, sm_120`입니다. 다른 GPU에서 빌드할 때는 GPU의 Compute Capability에 맞게 프로젝트 설정을 변경해야 합니다.

## 프로젝트 구성

```text
Raytracing_CUDA/
├── RayTracing.sln
└── RayTracing/
    ├── RayTracing.vcxproj
    ├── kernel.cu
    ├── Vec3.h
    ├── Color.h
    └── Ray.h
```

## 빌드 및 실행

1. Visual Studio에서 `RayTracing.sln`을 엽니다.
2. 빌드 구성을 `Debug`, 플랫폼을 `x64`로 선택합니다.
3. `Ctrl + Shift + B`로 프로젝트를 빌드합니다.
4. 저장소 루트에서 CMD를 열고 다음 명령을 실행합니다.

```cmd
x64\Debug\RayTracing.exe > image.ppm
```

렌더링 결과는 저장소 루트의 `image.ppm`으로 생성됩니다. 생성된 이미지와 빌드 결과물은 Git 추적에서 제외됩니다.

## 참고 자료

- [Ray Tracing in One Weekend](https://raytracing.github.io/)
- [RayTracinginOneWeekendinCUDA](https://github.com/eazuooz/RayTracinginOneWeekendinCUDA)
