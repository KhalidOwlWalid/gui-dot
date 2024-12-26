#ifndef GRAPH_2D_HPP
#define GRAPH_2D_HPP

#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "logger.hpp"

namespace godot {

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

    void _draw() override;

  protected:
    static void _bind_methods();

  private:
    void _draw_window();
    void _draw_display_frame();
    void _draw_grids();
    void _draw_axis();
    void _draw_ticks();
    void _init();

    struct Frame_t {
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

    struct Line_t {
      Color color;
      float width;

      inline Color get_color() const {return color;}
      inline void set_color(const Color new_color) {color = new_color;}

      inline float get_width() const {return width;}
      inline void set_width(const float new_width) {width = new_width;}
    };

    bool _initialized;
    Vector2 _graph_size;
    Vector2 _n_grid;
    Vector2 _grid_spacing;

    // Frame related properties
    Frame_t _window_info;
    Frame_t _display_frame_info;

    Color white = Color(1.0, 1.0, 1.0, 1.0);
    Color grey = Color(0.17, 0.17, 0.17, 1.0);
    Color black = Color(0.07, 0.07, 0.07, 1.0);

    // Line properties
    Line_t _axis {
      .color = white,
      .width = 3.0
    };

    Line_t _grid {
      .color = grey,
      .width = 1.5
    };

    Color BLACK_BACKGROUND = Color(17/255,17/255,22/255,255/255);

    // Color WHITE_TEXT = _rgba(189, 189, 192, 255);

};

}

#endif