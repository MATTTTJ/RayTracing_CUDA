#pragma once
#ifndef HITTABLE_H
#define HITTABLE_H

#include "Interval.h"
#include "Ray.h"

class HitRecord
{
public:
	void SetFaceNormal(const Ray& ray, const Vec3& outwardNormal)
	{
		// 내적이 음수면 광선이 물체 바깥에서 들어온 것이다.
		bFrontFace = Dot(ray.Direction(), outwardNormal) < 0.0;

		// 최종 법선은 항상 들어오는 광선의 반대 방향을 향한다.
		Normal = bFrontFace ? outwardNormal : -outwardNormal;
	}

	Point3 P;
	Vec3 Normal;
	double T = 0.0;
	bool bFrontFace = false;
};

class Hittable
{
public:
	virtual ~Hittable() = default;

	virtual bool Hit(const Ray& ray, const Interval& rayT, HitRecord& hitRecord) const = 0;
};

#endif