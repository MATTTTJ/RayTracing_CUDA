#ifndef COLOR_H
#define COLOR_H

#include "Vec3.h"
#include "Interval.h"

#include <iostream>

using Color = Vec3;

void WriteColor(std::ostream& out, const Color& pixelColor)
{
    auto red = pixelColor.X();
    auto green = pixelColor.Y();
    auto blue = pixelColor.Z();

    // 출력 가능한 범위로 제한한다. 최댓값 255을 넘지 않게 0.999 설정
    static const Interval intensity(0.000, 0.999);

    int redByte = static_cast<int>(256.0 * intensity.Clamp(red));
	int greenByte = static_cast<int>(256.0 * intensity.Clamp(green));
	int blueByte = static_cast<int>(256.0 * intensity.Clamp(blue));

	out << redByte << ' ' << greenByte << ' ' << blueByte << '\n';
}

#endif