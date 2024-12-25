#include "graph_2d.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Graph_2D::_bind_methods() {
  // TODO: draw a macro to make this process faster?
	ClassDB::bind_method(D_METHOD("get_window_background_color"), &Graph_2D::get_window_background_color);
	ClassDB::bind_method(D_METHOD("set_window_background_color", "color"), &Graph_2D::set_window_background_color);

	ClassDB::bind_method(D_METHOD("get_window_size"), &Graph_2D::get_window_size);
	ClassDB::bind_method(D_METHOD("set_window_size", "win_size"), &Graph_2D::set_window_size);

	ClassDB::bind_method(D_METHOD("get_display_background_color"), &Graph_2D::get_display_background_color);
	ClassDB::bind_method(D_METHOD("set_display_background_color", "color"), &Graph_2D::set_display_background_color);

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "_window_info.color"), "set_window_background_color", "get_window_background_color");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "_window_info.frame.size"), "set_window_size", "get_window_size");

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "_display_frame_info.color"), "set_display_background_color", "get_display_background_color");
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

  // You need to always ensure that window is drawn on top of the display frame
  /* TODO: Draw lines and circles at the boundary to allow user to resize their window
  upon receiving inputs from mouse */
  _draw_window();
  _draw_display_frame();
}

void Graph_2D::_process(double delta) {
}

Color Graph_2D::get_window_background_color() const {
  return _window_info.color;
}

void Graph_2D::set_window_background_color(const Color color) {
  _window_info.color = color;
}

Vector2 godot::Graph_2D::get_window_size() const {
  return _window_info.frame.size;
}

void godot::Graph_2D::set_window_size(const Vector2 win_size) {
  _window_info.frame.set_size(win_size);
  LOG("Set window size to ", String(_window_info.frame.size));
  LOG("Current bounding box size is ", String(_window_info.frame.get_size()));
}

Color Graph_2D::get_display_background_color() const {
  return _display_frame_info.color;
}

void Graph_2D::set_display_background_color(const Color color) {
  _display_frame_info.color = color;
}

void Graph_2D::_draw_window() {
  draw_rect(_window_info.frame, _window_info.color);
}

void Graph_2D::_draw_grids() {
}

void Graph_2D::_draw_display_frame() {
  
  // Calculate the margins between the window and display frame
  Vector2 frame_pos;
  Vector2 window_pos_center = _window_info.frame.get_center();
  Vector2 window_pos_top_left = _window_info.frame.get_position();
  Vector2 window_size = _window_info.frame.get_size();

  Vector2 margin = Vector2(30, 30);
  // _display_frame_info.frame.set_position(window_pos_top_left + margin);
  // LOG(String(window_size), " ", String(_display_frame_info.frame.size));
  _display_frame_info.frame.set_size(window_size - 2*margin);
  _display_frame_info.frame.set_position(margin);
  LOG(String(window_size), " ", String(window_size - margin));
  // _display_frame_info.frame = Rect2(Vector2(10, 10), Vector2(100, 100));
  LOG(String(window_pos_top_left), " ", String(_display_frame_info.frame.position));
  draw_rect(_display_frame_info.frame, _display_frame_info.color);

}