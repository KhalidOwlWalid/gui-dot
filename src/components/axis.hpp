#pragma once

#include "guidot_common.hpp"
#include "line.hpp"

namespace godot {

class Axis_t : public Line_t {
	String x_label;
	String y_label;
};

}

