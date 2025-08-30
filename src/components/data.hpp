#pragma once

#include "../guidot_common.hpp"
#include "line.hpp"

namespace godot {

class Data_t : public Line_t {

	const String __class__ = "Data_t";
	friend class Graph_2D;

	Vector2 x_range;
	Vector2 y_range;
	// TODO: Once data server is implemented, this should be move there?
	PackedVector2Array packed_v2_data; // Stores all of the data
	PackedVector2Array pixel_pos_v2_data;
	PackedVector2Array lod_data; // Level Of Detail data - only plot visible data
	float ts; // Calculated Sample time
	bool use_antialiased;
	String keyword;
	String unit;
	Dictionary data_dict;

	bool is_y_axis_lock = false;
	bool is_x_axis_lock = false;

	public:

		// TODO: Create an assertion to ensure x_max is always bigger than x_min
		template <typename T> void set_x_max(const T val) {
			x_range[1] = val;
		};

		template <typename T> void set_x_min(const T val) {
			x_range[0] = val;
		}

		template <typename T> void set_y_max(const T val) {
			y_range[1] = val;
		}

		template <typename T> void set_y_min(const T val) {
			y_range[0] = val;
		}

		inline double x_max() {return x_range[1]; }
		inline double x_min() {return x_range[0]; }
		inline double y_max() {return y_range[1]; }
		inline double y_min() {return y_range[0]; }

		template <typename T> T get_x_diff() {
			T diff = x_range[1] - x_range[0];
			return diff;
		}

		template <typename T> T get_y_diff() const {
			T diff = y_range[1] - y_range[0];
			return diff;
		}

		// Sets the range for the x and y axis by obtaining the min and max value of the data
		void set_range() {
			Vector2 min = lod_data[0];
			Vector2 max = lod_data[0];
			// TODO: Find a better optimized way to do this
			for (size_t i = 0; i < lod_data.size(); i++) {
					min.x = std::min(min.x, lod_data[i].x);
					max.x = std::max(max.x, lod_data[i].x);
					min.y = std::min(min.y, lod_data[i].y);
					max.y = std::max(max.y, lod_data[i].y);
			}
			// Only update the range if the axis is not lock
			x_range = is_x_axis_lock ? x_range: Vector2(min.x, max.x);
			// A scale of 0.1 is added for both min and max y to ensure the data is not drawn at the border of the display
			y_range = is_y_axis_lock ? y_range: Vector2(min.y, max.y) + Vector2(0.1, 0.1) * Vector2(min.y, max.y);
		}

		void set_y_range(float min, float max) {
			if (min > max) {
				LOG(WARNING, "min > max! Defaults to min,", y_min(), " and max,", y_max());
				return;
			}
			y_range[0] = min;
			y_range[1] = max;
		}

		void set_x_range(float min, float max) {
			if (min > max) {
				LOG(WARNING, "min > max! Defaults to min,", x_min(), " and max,", x_max());
				return;
			}
			x_range[0] = min;
			x_range[1] = max;
		}

		void calculate_sample_time(float window_sample_size) {
			float ts_sum = 0;
			// In order to get the sample time with the size of the moving window, we need to add one more since we are calculating
			// the next time minus the current time
			for (size_t i = packed_v2_data.size() - window_sample_size - 1; i < packed_v2_data.size() - 1; i++) {
				ts_sum += (packed_v2_data[i + 1].x - packed_v2_data[i].x);
			}
			ts = ts_sum / window_sample_size;
		}

		void info() const {
			LOG(INFO, "Keyword: ", keyword, " - Current V2 data: ", lod_data);
		}

};
}
