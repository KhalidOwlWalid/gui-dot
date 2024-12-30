#ifndef GRAPH_2D_HPP
#define GRAPH_2D_HPP

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/font.hpp>

#include <algorithm>

#include "logger.hpp"

namespace godot {

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

  public:
    Vector2 x_range;
    Vector2 y_range;
    PackedVector2Array packed_v2_data;
    PackedVector2Array packed_v2_norm_data;

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

    double x_max() {return x_range[1]; }
    double x_min() {return x_range[0]; }
    double y_max() {return y_range[1]; }
    double y_min() {return y_range[0]; }

    template <typename T> T get_x_diff() {
      T diff = x_range[1] - x_range[0];
      return diff;
    }

    template <typename T> T get_y_diff() const {
      T diff = y_range[1] - y_range[0];
      return diff;
    }

    void set_range() {
      Vector2 min = packed_v2_data[0];
      Vector2 max = packed_v2_data[0];
      for (size_t i = 0; i < packed_v2_data.size(); i++) {
        min.x = std::min(min.x, packed_v2_data[i].x);
        min.y = std::min(min.y, packed_v2_data[i].y);
        max.x = std::max(max.x, packed_v2_data[i].x);
        max.y = std::max(max.y, packed_v2_data[i].y);
      }
      x_range = Vector2(min.x, max.x);
      y_range = Vector2(min.y, max.y);
    }

};

class Graph_2D : public Control {

  GDCLASS(Graph_2D, Control);
  const String __class__ = "Graph_2D";

  public:
    Graph_2D();
    ~Graph_2D();

    void _process(double delta) override;

    void set_window_background_color(const Color color);
    Color get_window_background_color() const;

    void set_window_size(const Vector2 win_size);
    Vector2 get_window_size() const;

    void set_display_background_color(const Color color);
    Color get_display_background_color() const;

    void set_grid_size(const Vector2 grid_size);
    Vector2 get_grid_size() const;

    void set_data(const PackedVector2Array data);
    PackedVector2Array get_data() const;

    void _draw() override;

  protected:
    static void _bind_methods();

  private:
    void _draw_window();
    void _draw_display();
    void _draw_grids();
    void _draw_axis();
    void _draw_ticks();
    void _draw_plot();

    void _calculate_grid_spacing();
    void _init();
    PackedVector2Array _coordinate_to_pixel(const PackedVector2Array &coords);

    // TODO: Make this a template
    String _format_string(const float &val, int dp);

    bool _initialized;
    Vector2 _grid_spacing;
    Vector2 _n_grid {Vector2(10, 5)};
    Vector2 _frame_margin {Vector2(100, 100)};

    // Frame related properties
    Frame_t _window;
    Frame_t _display;

    // Line properties
    Line_t _axis;
    Line_t _grid;

    // Create data class
    Data_t _data1;

    // Color properties
    Color white = Color(1.0, 1.0, 1.0, 1.0);
    Color grey = Color(0.17, 0.17, 0.17, 1.0);
    Color black = Color(0.07, 0.07, 0.07, 1.0);
    Color red = Color(1.0, 0.07, 0.07, 1.0);

};

}

#endif