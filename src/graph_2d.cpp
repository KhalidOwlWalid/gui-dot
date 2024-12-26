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

  Vector2 win_size = Vector2(600, 400);
  _window_info.frame = Rect2(Vector2(0, 0), win_size);
  _window_info.color = Color(0, 0, 0, 1.0);
  this->set_size(win_size);

  // Initialize the display frame so that it is always position in the center part of the window frame
  // Calculate the margins between the window and display frame
  Vector2 window_pos_top_left = _window_info.frame.get_position();
  Vector2 window_size = _window_info.frame.get_size();

  Vector2 margin = Vector2(30, 30);
  /* 2x margin is required in order to compensate for the offset when using the 
  set_position method */
  _display_frame_info.frame.set_size(window_size - 2*margin);
  _display_frame_info.frame.set_position(margin);
  _display_frame_info.color = Color(0, 0, 0, 1.0);

  _n_grid = Vector2(10, 5);

  Vector2 display_top_left = _display_frame_info.frame.get_position();
  Vector2 display_size = _display_frame_info.frame.get_size();

  // Calculate the amount of spacing required per pixel with n_grid
  _grid_spacing.x = static_cast<uint>(_display_frame_info.frame.get_size().x / _n_grid.x);
  _grid_spacing.y = static_cast<uint>(_display_frame_info.frame.get_size().y / _n_grid.y);

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
  /* TODO: Draw lines and circles at the boundary to allow user to resize their window
  upon receiving inputs from mouse */

  /* Drawing order is very important to avoid lines overlapping on top of each other 
  (e.g. Drawing display frame before window would cause display frame to be hidden behind
  the window) */
  _draw_window();
  _draw_display_frame();
  _draw_grids();
  _draw_axis();
  _draw_ticks();
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
  // Update the size of the node bounding box
  this->set_size(win_size);
  LOG("Using Inspector edit to resize window");
}

Color Graph_2D::get_display_background_color() const {
  return _display_frame_info.color;
}

void Graph_2D::set_display_background_color(const Color color) {
  _display_frame_info.color = color;
}

void Graph_2D::_draw_window() {
  /* _draw() is called every frame, so this allows user to resize the 
  window by controlling the Node bounding box */
  _window_info.frame.set_size(this->get_size());
  draw_rect(_window_info.frame, _window_info.color);
}

void Graph_2D::_draw_display_frame() {
  // Calculate the margins between the window and display frame
  Vector2 window_pos_top_left = _window_info.frame.get_position();
  Vector2 window_size = _window_info.frame.get_size();

  Vector2 margin = Vector2(30, 30);
  /* 2x margin is required in order to compensate for the offset when using the 
  set_position method */
  _display_frame_info.frame.set_size(window_size - 2*margin);
  _display_frame_info.frame.set_position(margin);
  _display_frame_info.color = BLACK_BACKGROUND;
  draw_rect(_display_frame_info.frame, _display_frame_info.color);
}

void Graph_2D::_draw_grids() {
  Vector2 display_top_left = _display_frame_info.frame.get_position();
  Vector2 display_size = _display_frame_info.frame.get_size();

  Color grey_gridlines = Color(0.17, 0.17, 0.17, 1.0);
  float line_width = 2.0;

  // For column, we start with index 1 since we start drawing from the left, which will overlap with the y-axis
  for (size_t i = 1; i <= _n_grid.x; i++) {
    // Added offset before performing the spacing calculation due to the frame margin
    Vector2 top_column_grid = Vector2(display_top_left.x + i * _grid_spacing.x, display_top_left.y);
    Vector2 bottom_column_grid = Vector2(display_top_left.x + i * _grid_spacing.x, display_top_left.y + display_size.y);
    draw_line(top_column_grid, bottom_column_grid, grey_gridlines, line_width);
  }

  // For row, we start with index 0, since we start drawing from the top
  for (size_t i = 0; i <= _n_grid.y; i++) {
    // Added offset before performing the spacing calculation due to the frame margin
    // When dealing with the row grid, remember that we are drawing from the top to bottom
    // where top right corner is origin (0, 0)
    Vector2 left_row_grid = Vector2(display_top_left.x, display_top_left.y + i * _grid_spacing.y);
    Vector2 right_row_grid = Vector2(display_top_left.x + display_size.x, display_top_left.y + i * _grid_spacing.y);
    draw_line(left_row_grid, right_row_grid, grey_gridlines, line_width);
  }
}

void Graph_2D::_draw_axis() {
  Vector2 display_bottom_left = Vector2(_display_frame_info.x(), _display_frame_info.y() + _display_frame_info.y_size());
  Vector2 display_bottom_right = Vector2(_display_frame_info.x() + _display_frame_info.x_size(), _display_frame_info.y() + _display_frame_info.y_size());

  // y-axis
  draw_line(_display_frame_info.top_left(), _display_frame_info.bottom_left(), _axis.color, _axis.width);
  // x-axis
  draw_line(_display_frame_info.bottom_left(), _display_frame_info.bottom_right(), _axis.color, _axis.width);
}

void Graph_2D::_draw_ticks() {

}