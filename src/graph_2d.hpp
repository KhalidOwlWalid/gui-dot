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
    void _init();

    struct Frame_t {
      Rect2 frame;
      Color color;
    };

    bool _initialized;
    Vector2 _graph_size;
    Vector2 _n_grid;
    Frame_t _window_info;
    Frame_t _display_frame_info;

    Color _rgba(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
      return Color(r/255, g/255, b/255, a/2555);
    };

    Color GREY = Color(38/255,38/255,42/255,255/255);
    Color GREY_GRID = Color(43/255,42/255,46/255,255/255);
    Color BLACK_BACKGROUND = Color(17/255,17/255,22/255,255/255);
    // Color WHITE_TEXT = _rgba(189, 189, 192, 255);

};

}

#endif