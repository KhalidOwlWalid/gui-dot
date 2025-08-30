#pragma once

#include "../guidot_common.hpp"

namespace godot {

class Line_t {

	friend class Axis_t;
	friend class Graph_2D;

	Color color;
	float width;
	Ref<Font> font;

	public:
		inline Color get_color() const {return color;}
		inline void set_color(const Color new_color) {color = new_color;}

		inline float get_width() const {return width;}
		inline void set_width(const float new_width) {width = new_width;}

};

}
