#include "graph_2d.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Graph_2D::_bind_methods() {
  // TODO: draw a macro to make this process faster?
	ClassDB::bind_method(D_METHOD("get_background_color"), &Graph_2D::get_background_color);
	ClassDB::bind_method(D_METHOD("set_background_color", "color"), &Graph_2D::set_background_color);

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "_background_color"), "set_background_color", "get_background_color");
}

Graph_2D::Graph_2D() {

  _window_info.frame = Rect2(Vector2(0, 0), Vector2(120, 120));
  _window_info.color = Color(0.0, 0.0, 0.0, 1.0);


  // Initialize the display frame so that it is always position in the center part of the window frame
  _display_frame_info.frame = Rect2(Vector2(10, 10), Vector2(100, 100));
  _display_frame_info.color = Color(1.0, 1.0, 1.0, 1.0);

  _initialized = false;

  LOG("draw default values");
}

Graph_2D::~Graph_2D() {
  LOG("Cleaning Graph_2D construct");
}

void Graph_2D::_init() {
  _draw_window();
  _draw_display_frame();
  _initialized = true;
}

void Graph_2D::_draw() {
  // Draw the background
  // _draw_grids();

  if (not _initialized) {
    _init();
    LOG("Initializing the graph");
  }

  _window_info.frame.size = get_size();
  _draw_window();
  _draw_display_frame();

  LOG(String(get_size()));

  LOG("Redrawing rectange with another color");
}

void Graph_2D::_process(double delta) {
}

Color Graph_2D::get_background_color() const {
  return _window_info.color;
}

void Graph_2D::set_background_color(const Color color) {
  _window_info.color = color;
}

void Graph_2D::_draw_window() {
  draw_rect(_window_info.frame, _window_info.color);
}

void Graph_2D::_draw_grids() {
}

void Graph_2D::_draw_display_frame() {
  draw_rect(_display_frame_info.frame, _display_frame_info.color);
}