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

    template <typename T> T get_x_diff() {
      T diff = x_range[1] - x_range[0];
      return diff;
    }

    template <typename T> T get_y_diff() const {
      T diff = y_range[1] - y_range[0];
      return diff;
    }

    void set_range() {
      // TODO: Only allow for specific time window maybe?
      // If data is large, it will be really slow, so implementing
      // time window here would improve the speed but it would not process every data

      Vector2 min_xy = *std::min_element(packed_v2_data.begin(), packed_v2_data.end(), 
      [](const Vector2 &a, const Vector2 &b) {
        return a.x < b.x;
      });

      Vector2 max_xy = *std::min_element(packed_v2_data.begin(), packed_v2_data.end(), 
      [](const Vector2 &a, const Vector2 &b) {
        return a.x > b.x;
      });

      x_range = Vector2(min_xy[0], max_xy[0]);
      y_range = Vector2(min_xy[1], max_xy[1]);
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
    void _pixel_to_coordinates(const Vector2 pix_pos);

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

};

}

#endif