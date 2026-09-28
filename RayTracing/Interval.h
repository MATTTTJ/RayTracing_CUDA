#pragma once
#ifndef INTERVAL_H
#define INTERVAL_H

#include "RTWeekend.h"

struct Interval
{
public:
	Interval() : Min(+Infinity), Max(-Infinity) {}
	Interval(double minimum, double maximum)
		: Min(minimum),
		Max(maximum)
	{
	}

	double Size() const
	{
		return Max - Min;
	}

	// 경계를 포함한 범위 검사 : Min <= value <= Max
	bool Contains(double value) const
	{
		return Min <= value && value <= Max;
	}

	// 경계를 제외한 범위 검사 : Min < value < Max
	bool Surrounds(double value) const
	{
		return Min < value && value < Max;
	}

	static const Interval Empty;
	static const Interval Universe;

	double Min;
	double Max;
};

// 헤더가 여러 파일에 포함되어도 중복 정의되지 않도록 inline을 사용한다.
const Interval Interval::Empty(+Infinity, -Infinity);
const Interval Interval::Universe(-Infinity, +Infinity);

#endif