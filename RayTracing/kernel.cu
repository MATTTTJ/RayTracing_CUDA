
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "RTWeekend.h"
#include "Interval.h"
#include "Hittable.h"
#include "HittableList.h"
#include "Sphere.h"

#include <stdio.h>

cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);

__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}

Color RayColor(const Ray& ray, const Hittable& world)
{
    HitRecord hitRecord;

    // 카메라 앞쪽의 모든 교차점을 허용한다. 
    if (world.Hit(ray, Interval(0.0, Infinity), hitRecord))
    {
        // 저장된 법선을 RGB 범위로 변환한다.
        return 0.5 * (hitRecord.Normal + Color(1.0, 1.0, 1.0));
    }

    // 아무 물체와도 만나지 않으면 하늘 배경으로 반환한다.
    Vec3 unitDirection = UnitVector(ray.Direction());
    auto a = 0.5 * (unitDirection.Y() + 1.0);

    return (1.0 - a) * Color(1.0, 1.0, 1.0) + a * Color(0.5, 0.7, 1.0);
}

int main()
{
    auto aspectRatio = 16.0 / 9.0;
    int imageWidth = 400;

    // 높이 계산, 최소 1 이상
    int imageHeight = int(imageWidth / aspectRatio);
    imageHeight = (imageHeight < 1) ? 1 : imageHeight;

    // World
    HittableList world;

    // 화면 중앙의 작은 구
    world.Add(std::make_shared<Sphere>(Point3(0.0, 0.0, -1.0), 0.5));
    
    // 바닥처럼 보이는 매우 큰 구
    world.Add(std::make_shared<Sphere>(Point3(0.0, -100.5, -1.0), 100.0));

    // 뷰포트 계산
    auto viewportHeight = 2.0;
    auto viewportWidth = viewportHeight * (double(imageWidth) / imageHeight);

    // Camera 
    auto focalLength = 1.0;
    auto cameraCenter = Point3(0, 0, 0);

    // 뷰포트 전체 너비와 높이를 나타내는 벡터
    auto viewportU = Vec3(viewportWidth, 0, 0);
    auto viewportV = Vec3(0, -viewportHeight, 0);

    // 픽셀 한 칸의 이동 거리
    auto pixelDeltaU = viewportU / imageWidth;
    auto pixelDeltaV = viewportV / imageHeight;

    // 뷰포트의 왼쪽 위 모서리
    auto viewportUpperLeft =
        cameraCenter - Vec3(0, 0, focalLength)
        - viewportU / 2
        - viewportV / 2;

    // 왼쪽 위 첫 번째 픽셀의 중심
    auto pixel00Loc = viewportUpperLeft + 0.5 * (pixelDeltaU + pixelDeltaV);

    // Render
    std::cout << "P3\n" << imageWidth << ' ' << imageHeight << "\n255\n";

    for (int j = 0; j < imageHeight; j++)
    {
        std::clog << "\rSacnline remaining: " << (imageHeight - j) << ' ' << std::flush;
        for (int i = 0; i < imageWidth; i++)
        {
            // 현재 픽셀의 3D 위치
            auto pixelCenter = pixel00Loc + i * pixelDeltaU + j * pixelDeltaV;

            // 카메라에서 픽셀 중심으로 향하는 방향
            auto rayDirection = pixelCenter - cameraCenter;

            // 광선 생성
            Ray r(cameraCenter, rayDirection);

            // 광선 방향에서 보이는 색상 계산
            Color pixelColor = RayColor(r, world);
            WriteColor(std::cout, pixelColor);

            /*auto PixelColor = Color(double(i) / (imageWidth - 1), double(j) / (imageHeight - 1), 0);
            WriteColor(std::cout, PixelColor);*/
        }
    }

    std::clog << "\rDone.             \n";
    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernel<<<1, size>>>(dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}
