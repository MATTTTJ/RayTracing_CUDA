#pragma once
#ifndef CAMERA_H
#define CAMERA_H

#include "Hittable.h"

class Camera
{
public:
    // 이미지의 가로 / 세로 비율
    double aspectRatio = 1.0;
    // 이미지의 가로 픽셀 수
    int imageWidth = 100;       
    // 픽셀 하나에서 조사할 위치의 수
	int samplesPerPixel = 10;

    void Render(const Hittable& world)
    {
        // 출력 전에 카메라와 픽셀 위치를 준비
        Initialize();

        std::cout << "P3\n" << imageWidth << ' ' << mImageHeight << "\n255\n";

        // 이미지의 각 행을 방문 -> 그 행의 각 픽셀을 방문 -> 그 픽셀 안을 여러 번 조사
        for (int scanlineIndex = 0; scanlineIndex < mImageHeight; scanlineIndex++)
        {
            std::clog
                << "\rScanlines remaining: "
                << (mImageHeight - scanlineIndex)
                << ' '
                << std::flush;

            for (int pixelIndex = 0; pixelIndex < imageWidth; pixelIndex++)
            {
                // 이 픽셀에서 얻은 색을 더할 준비
				Color pixelColor(0.0, 0.0, 0.0);

                // 픽셀 안의 서로 다른 위치를 여러 번 조사
                for (int sampleIndex = 0; sampleIndex < samplesPerPixel; sampleIndex++)
                {
                    Ray ray = GetRay(pixelIndex, scanlineIndex);
                    pixelColor += RayColor(ray, world);
                }

                // 색의 합을 평균으로 바꿔 출력
                WriteColor(std::cout, mPixelSamplesScale * pixelColor);
            }
        }

        std::clog << "\rDone.                 \n";
    }

private:
    void Initialize()
    {
        // 이미지 높이를 계산하고 최소 1로 제한한다.
        mImageHeight = static_cast<int>(imageWidth / aspectRatio);
        mImageHeight = (mImageHeight < 1) ? 1 : mImageHeight;

        // 색의 합에 곱하면 평균이 되는 값
        mPixelSamplesScale = 1.0 / static_cast<double>(samplesPerPixel);

        mCenter = Point3(0.0, 0.0, 0.0);

        // 뷰포트 크기
        auto focalLength = 1.0;
        auto viewportHeight = 2.0;
        auto viewportWidth =
            viewportHeight * (static_cast<double>(imageWidth) / mImageHeight);

        // 뷰포트의 가로 방향과 아래 방향
        auto viewportU = Vec3(viewportWidth, 0.0, 0.0);
        auto viewportV = Vec3(0.0, -viewportHeight, 0.0);

        // 뷰포트의 왼쪽 위 모서리
        mPixelDeltaU = viewportU / imageWidth;
        mPixelDeltaV = viewportV / mImageHeight;

        // 첫 번째 픽셀의 중심
        auto viewportUpperLeft =
            mCenter
            - Vec3(0.0, 0.0, focalLength)
            - viewportU / 2.0
            - viewportV / 2.0;

        mPixel00Location =
            viewportUpperLeft + 0.5 * (mPixelDeltaU + mPixelDeltaV);
    }

    Ray GetRay(int pixelIndex, int scanlineIndex) const
    {
        // 픽셀 중심에서 움직일 무작위 이동량
        auto offset = SampleSquare();

        // 이번에 조사할 뷰포트상의 위치
        auto pixelSample = mPixel00Location + ((pixelIndex + offset.X()) * mPixelDeltaU) + ((scanlineIndex + offset.Y()) * mPixelDeltaV);

        auto rayOrigin = mCenter;
        auto rayDirection = pixelSample - rayOrigin;

        return Ray(rayOrigin, rayDirection);
    }

    Vec3 SampleSquare() const
    {
        // 픽셀 중심을 기준으로 가로/세로 최대 -0.5 ~ 0.5 범위의 무작위 위치를 반환한다.
        return Vec3(RandomDouble(-0.5, 0.5), RandomDouble(-0.5, 0.5), 0.0);
	}

    Color RayColor(const Ray& ray, const Hittable& world) const
    {
        HitRecord hitRecord;

        if (world.Hit(ray, Interval(0.0, Infinity), hitRecord))
        {
            // 법선의 -1~1 범위를 색상의 0 ~ 1범위로 변환한다.
            return 0.5 * (hitRecord.Normal + Color(1.0, 1.0, 1.0));
        }

        // 물체와 만나지 않으면 하늘 배경색을 반환한다.
        Vec3 unitDirection = UnitVector(ray.Direction());
        auto a = 0.5 * (unitDirection.Y() + 1.0);

        return (1.0 - a) * Color(1.0, 1.0, 1.0)
            + a * Color(0.5, 0.7, 1.0);
    }

private:
    int mImageHeight = 0;        // Rendered image height
    double mPixelSamplesScale = 1.0;
    Point3 mCenter;              // Camera center
    Point3 mPixel00Location;     // Location of pixel 0, 0
    Vec3 mPixelDeltaU;           // Offset to pixel to the right
    Vec3 mPixelDeltaV;           // Offset to pixel below
};

#endif