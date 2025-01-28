#ifndef GRAPH_2D_HPP
#define GRAPH_2D_HPP

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/node2d.hpp>

#include <algorithm>
#include <vector>

#include "logger.hpp"
#include "util.hpp"

using namespace godot;

using uf = UtilityFunctions;

class Frame_t {
  public:
    Rect2 frame;
    Color color;

    // Helper function to get the top left position of the frame
    inline Vector2 get_pos() const {return frame.position;}
    inline void set_pos(const Vector2 pos) {frame.set_position(pos);}
    inline int x() const {return frame.position.x;}
    inline int y() const {return frame.position.y;}

    // Useful to get different coordinates of the frame
    inline Vector2 top_left() const {return Vector2(frame.position.x, frame.position.y);}
    inline Vector2 top_right() const {return Vector2(frame.position.x + frame.size.x, frame.position.y);}
    inline Vector2 bottom_left() const {return Vector2(frame.position.x, frame.position.y + frame.size.y);}
    inline Vector2 bottom_right() const {return Vector2(frame.position.x + frame.size.x, frame.position.y + frame.size.y);}

    // Helper function to get or set the size of the frame
    inline Vector2 get_size() const {return frame.get_size();}
    inline void set_size(const Vector2 size) {frame.set_size(size);}
    inline uint x_size() const {return frame.size.x;}
    inline uint y_size() const {return frame.size.y;}
};

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

class Axis_t : public Line_t {
  String x_label;
  String y_label;
};

class Data_t : public Line_t {

  const String __class__ = "Data_t";
  friend class Graph_2D;

  Vector2 x_range;
  Vector2 y_range;
  PackedVector2Array packed_v2_data;
  PackedVector2Array pixel_pos_v2_data;
  bool use_antialiased;
  String keyword;
  String unit;

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
      Vector2 min = packed_v2_data[0];
      Vector2 max = packed_v2_data[0];
      // TODO: Find a better optimized way to do this
      for (size_t i = 0; i < packed_v2_data.size(); i++) {
          min.x = std::min(min.x, packed_v2_data[i].x);
          max.x = std::max(max.x, packed_v2_data[i].x);
          min.y = std::min(min.y, packed_v2_data[i].y);
          max.y = std::max(max.y, packed_v2_data[i].y);
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

    void info() const {
      LOG(INFO, "Keyword: ", keyword, " - Current V2 data: ", packed_v2_data);
    }

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

    Status add_new_data_with_keyword(const String &keyword, const PackedVector2Array &data, const Color color);
    Status update_data_with_keyword(const String &keyword, const PackedVector2Array &data);
    PackedVector2Array get_data_with_keyword(const String &keyword) const;

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
    void _init_font();

    void _calculate_grid_spacing();
    void _init();
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

};

VARIANT_ENUM_CAST(Graph_2D::Status);

#endif