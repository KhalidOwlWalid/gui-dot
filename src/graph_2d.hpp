#pragma once

#include "guidot_common.hpp"
#include "components/frame.hpp"
#include "components/line.hpp"
#include "components/axis.hpp"
#include "components/data.hpp"

namespace godot {

struct sliding_window_info {
	float t_min;
	float t_max;
	float t_min_floor;
	float t_max_floor;
	float multiples;

	Vector2 range() {return Vector2(t_min, t_max);}
};

class Graph_2D : public Control {

	GDCLASS(Graph_2D, Control);
	const String __class__ = "Graph_2D";

	public:

		enum Status {
			FAIL,
			SUCCESS
		};

		Graph_2D();
		~Graph_2D();

		void _process(double delta) override;

		void set_window_background_color(const Color &color);
		Color get_window_background_color() const;

		void set_window_size(const Vector2 &win_size);
		Vector2 get_window_size() const;

		void set_display_background_color(const Color &color);
		Color get_display_background_color() const;

		void set_grid_size(const Vector2 &grid_size);
		Vector2 get_grid_size() const;

		void set_data(const PackedVector2Array &data, const int n);
		PackedVector2Array get_data(const int n) const;

		void set_y_range(const String keyword, const float min, const float max);
		Vector2 get_y_range(const String keyword) const;

		void set_x_range(const String keyword, const float min, const float max);
		Vector2 get_x_range(const String keyword) const;

		void set_antialiased_flag(const bool flag);

		Status add_new_data_with_keyword(const String &keyword, const PackedVector2Array &data, const Color color);
		Status update_data_with_keyword(const String &keyword, const PackedVector2Array &data);
		PackedVector2Array get_data_with_keyword(const String &keyword) const;
		Status append_data_with_keyword(const String &keyword, const float &data);
		Status append_data_array_with_keyword(const String &keyword, const PackedVector2Array &data_array);


		void set_data_line_color(const Color &color, const int n);
		Color get_data_line_color(const int n) const;

		// TODO: Populate this
		void get_font();
		Ref<Font> set_font();

		void _draw() override;

	protected:
		static void _bind_methods();
		void _notification(const int p_what);

	private:
		void _draw_window();
		void _draw_display();
		void _draw_grids();
		void _draw_axis();
		void _draw_ticks();
		void _draw_plot();
		void _preprocess_data();
		void _init_font();

		void _calculate_grid_spacing();
		void _init();

		void _setup_axes();
		void _draw_content();

		bool use_antialiased = false;
		Vector2 _coordinate_to_pixel(const Vector2 &data, const Vector2 &x_range, const Vector2 &y_range);

		// TODO: Make this a template
		String _format_axis_label(const float &val, int dp);

		bool _initialized {false};
		Vector2 _grid_spacing;
		Vector2 _n_grid {Vector2(10, 5)};
		Vector2 _frame_margin {Vector2(100, 100)};
		Ref<Font> _font_manager;

		// Frame related properties
		Frame_t _window;
		Frame_t _display;

		// Line properties
		Line_t _axis;
		Line_t _grid;

		// Data vector allows us to store multiple sets of data
		// for multi-axis plot
		std::vector<Data_t> data_vector;
		PackedVector2Array test_data;

		uint64_t ticks;
		uint64_t last_update_ticks;

		Node2D *_label_parent;

		// Color properties
		Color white = Color(1.0, 1.0, 1.0, 1.0);
		Color grey = Color(0.17, 0.17, 0.17, 1.0);
		Color black = Color(0.07, 0.07, 0.07, 1.0);
		Color red = Color(1.0, 0.07, 0.07, 1.0);
		Color gd_grey = Color::hex(0x363d4a);
		Color gd_blue = Color::hex(0x252b34);
		Color green = Color::hex(0x469d5a);

		// Temporary constant use
		const int font_size = 16;
		const int font_margin = font_size + 20;
		const int label_margin = 20;
		const int dp = 2;
		int max_digit_size = 1;

		float sliding_window_duration = 15.0;

		sliding_window_info _sw_info;

		Control *axes;

};

};

VARIANT_ENUM_CAST(Graph_2D::Status);
