#pragma once
#ifndef RTWEEKEND_H
#define RTWEEKEND_H

#include <cmath>
#include <iostream>
#include <limits>
#include <memory>

using std::make_shared;
using std::shared_ptr;

// 공통 상수
constexpr double Infinity = std::numeric_limits<double>::infinity();
constexpr double Pi = 3.1415926535897932385;

// 각도를 라디안으로 변환한다.
inline double DegreesToRadians(double degree)
{
	return degree * Pi / 180.0;
}

// 공통 프로젝트 헤더
#include "Color.h"
#include "Interval.h"
#include "Ray.h"
#include "Vec3.h"

#endif