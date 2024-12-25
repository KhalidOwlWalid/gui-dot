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
    void _init();

    struct Frame_t {
      Rect2 frame;
      Color color;
    };

    bool _initialized;
    Vector2 _graph_size;
    Vector2 _grid_spacing;
    Frame_t _window_info;
    Frame_t _display_frame_info;

};

}

#endif