#pragma once
#ifndef HITTABLE_LIST_H
#define HITTABLE_LIST_H

#include "Hittable.h"
#include <vector>

class HittableList : public Hittable
{
public:
	HittableList() = default;

	explicit HittableList(const std::shared_ptr<Hittable>& object)
	{
		Add(object);
	}

	void Clear()
	{
		mObjects.clear();
	}

	void Add(const std::shared_ptr<Hittable>& object)
	{
		mObjects.push_back(object);
	}

	bool Hit(const Ray& ray, const Interval& rayT, HitRecord& hitRecord) const override
	{
		HitRecord temporaryHitRecord;
		bool bHitAnything = false;
		
		// 처음에는 전달받은 최대 범위까지 검사한다.
		auto closestSoFar = rayT.Max;

		for (const auto& object : mObjects)
		{
			// 이미 발견된 교차점보다 가까운 범위만 검사한다. 
			Interval currentRayT(rayT.Min, closestSoFar);

			if (object->Hit(ray, currentRayT, temporaryHitRecord))
			{
				bHitAnything = true;
				closestSoFar = temporaryHitRecord.T;
				hitRecord = temporaryHitRecord;
			}
		}

		return bHitAnything;
	}

private:
	std::vector <std::shared_ptr<Hittable>> mObjects;
};

#endif