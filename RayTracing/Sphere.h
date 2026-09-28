#pragma once
#ifndef SPHERE_H
#define SPHERE_H

#include "Hittable.h"

class Sphere : public Hittable
{
public:
	Sphere(const Point3& center, double radius)
		: mCenter(center)
		, mRadius(std::fmax(0.0, radius)){}

	bool Hit(const Ray& ray, const Interval& rayT, HitRecord& hitRecord) const override
	{
		Vec3 originToCenter = mCenter - ray.Origin();

		// 6.2 에서 단순화한 광선 - 구 교차식
		auto a = ray.Direction().LengthSquared();
		auto h = Dot(ray.Direction(), originToCenter);
		auto c = originToCenter.LengthSquared() - mRadius * mRadius;

		auto discriminant = h * h - a * c;

		if (discriminant < 0.0)
		{
			return false;
		}

		auto sqrtd = std::sqrt(discriminant);

		// 카메라에 가장 가까운 첫 번째 근부터 검사
		auto root = (h - sqrtd) / a;

		if (!rayT.Surrounds(root))
		{
			// 첫 번째 근이 범위 밖이면 뒤쪽 교차점을 검사한다.
			root = (h + sqrtd) / a;

			if (!rayT.Surrounds(root))
				return false;
		}

		hitRecord.T = root;
		hitRecord.P = ray.At(hitRecord.T);

		// 반지름으로 나누면 길이가 1인 바깥쪽 법선이 된다.
		Vec3 outwardNormal = (hitRecord.P - mCenter) / mRadius;

		hitRecord.SetFaceNormal(ray, outwardNormal);

		return true;
	}

private:
	Point3 mCenter;
	double mRadius;
};

#endif