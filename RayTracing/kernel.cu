
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "Color.h"
#include "Vec3.h"
#include "Ray.h"

#include <iostream>
#include <stdio.h>
#include <cmath>

cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);

__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}

double HitSphere(const Point3& center, double radius, const Ray& r)
{
    // 광선 출발점에서 구 중심으로 향하는 벡터
    Vec3 oc = center - r.Origin();

    // 광선-구 교차식을 이차방정식으로 정리한 계수
    auto a = Dot(r.Direction(), r.Direction());
    auto b = -2.0 * Dot(r.Direction(), oc);
    auto c = Dot(oc, oc) - radius * radius;

    // 판별식이 0 이상이면 실수 t가 존재하므로 구와 만난다.
    auto discriminant = b * b - 4 * a * c;

	// 실수 해가 없으면 구와 만나지 않는다.
	if (discriminant < 0.0)
	{
		return -1.0;
	}
	// 두 교차점 중 카메라에 더 가까운 쪽의 t를 반환한다.
	return (-b - std::sqrt(discriminant)) / (2.0 * a);
}

Color RayColor(const Ray& r)
{
	const Point3 sphereCenter(0, 0, -1);

	auto t = HitSphere(sphereCenter, 0.5, r);

	if (t>0.0)
	{
		// 광선 위의 실제 교차점
		Point3 hitPoint = r.At(t);

		// 구 중심에서 교차점으로 향하는 바깥쪽 단위 법선
		Vec3 outwardNormal = UnitVector(hitPoint - sphereCenter);

		// 법선 범위 -1~1을 색상 범위 0~1로 변환한다.
		return 0.5 * Color(
			outwardNormal.X() + 1.0,
			outwardNormal.Y() + 1.0,
			outwardNormal.Z() + 1.0
		);
	}

	// 구와 만나지 않으면 기존 하늘 배경을 그린다. 
	Vec3 unitDirection = UnitVector(r.Direction());
	auto a = 0.5 * (unitDirection.Y() + 1.0);

    return (1.0 - a) * Color(1.0, 1.0, 1.0) + a * Color(0.5, 0.7, 1.0);
}

int main()
{
    //const int arraySize = 5;
    //const int a[arraySize] = { 1, 2, 3, 4, 5 };
    //const int b[arraySize] = { 10, 20, 30, 40, 50 };
    //int c[arraySize] = { 0 };

    //// Add vectors in parallel.
    //cudaError_t cudaStatus = addWithCuda(c, a, b, arraySize);
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "addWithCuda failed!");
    //    return 1;
    //}

    //printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
    //    c[0], c[1], c[2], c[3], c[4]);

    //// cudaDeviceReset must be called before exiting in order for profiling and
    //// tracing tools such as Nsight and Visual Profiler to show complete traces.
    //cudaStatus = cudaDeviceReset();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaDeviceReset failed!");
    //    return 1;
    //}

    // Image
    //int ImageWidth = 256;
    //int ImageHeight = 256;

    auto aspectRatio = 16.0 / 9.0;
    int imageWidth = 400;

    // 높이 계산, 최소 1 이상
    int imageHeight = int(imageWidth / aspectRatio);
    imageHeight = (imageHeight < 1) ? 1 : imageHeight;

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
            Color pixelColor = RayColor(r);
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
