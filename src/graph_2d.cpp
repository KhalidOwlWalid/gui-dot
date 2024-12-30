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

	ClassDB::bind_method(D_METHOD("get_grid_size"), &Graph_2D::get_grid_size);
	ClassDB::bind_method(D_METHOD("set_grid_size", "grid_size"), &Graph_2D::set_grid_size);

	ClassDB::bind_method(D_METHOD("get_data"), &Graph_2D::get_data);
	ClassDB::bind_method(D_METHOD("set_data", "data"), &Graph_2D::set_data);

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "_window.color"), "set_window_background_color", "get_window_background_color");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "_window.frame.size"), "set_window_size", "get_window_size");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "_display.color"), "set_display_background_color", "get_display_background_color");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "_n_grid"), "set_grid_size", "get_grid_size");
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "_data1.packed_v2_data"), "set_data", "get_data");
}

Graph_2D::Graph_2D() {

  _window.frame = Rect2(Vector2(0, 0), Vector2(600, 400));
  _window.color = black;

  // Ensure the Node Bounding Box is scaled according to the window during init
  this->set_size(_window.get_size());

  _display.frame = Rect2(Vector2(_frame_margin), Vector2(_window.get_size() - 2*_frame_margin));
  _display.color = black;

  _grid.color = grey;
  _grid.width = 1.5;

  _axis.color = white;
  _axis.width = 3.0;

  _calculate_grid_spacing();

  _initialized = false;

  _axis.font = this->get_theme_default_font();

  // // Temp
  // for (size_t i = 0; i < 10; i++) {
  //   float x = UtilityFunctions::randf_range(0, 100);
  //   float y = UtilityFunctions::randf_range(0, 10);
  //   _data1.packed_v2_data.append(Vector2(i, y));
  // }
  _data1.color = red;
  _data1.width = 3.0;
}

Graph_2D::~Graph_2D() {
}

void Graph_2D::_init() {
  _draw_window();
  _draw_display();
  _initialized = true;
}

void Graph_2D::_calculate_grid_spacing() {
  // Calculate the amount of spacing required per pixel with n_grid
  _grid_spacing.x = static_cast<uint>(_display.x_size() / _n_grid.x);
  _grid_spacing.y = static_cast<uint>(_display.y_size() / _n_grid.y);
}

void Graph_2D::_draw() {
  /* TODO: Draw lines and circles at the boundary to allow user to resize their window
  upon receiving inputs from mouse */

  /* Drawing order is very important to avoid lines overlapping on top of each other 
  (e.g. Drawing display frame before window would cause display frame to be hidden behind
  the window) */
  _draw_window();
  _draw_display();
  _draw_grids();

  if (not _data1.packed_v2_data.is_empty()) {
    // Only draw when it is not empty
    _draw_plot();
  }

  _draw_axis();
  _draw_ticks();;
}

void Graph_2D::_process(double delta) {
}

Color Graph_2D::get_window_background_color() const {
  return _window.color;
}

void Graph_2D::set_window_background_color(const Color color) {
  _window.color = color;
}

Vector2 godot::Graph_2D::get_window_size() const {
  return _window.frame.size;
}

void godot::Graph_2D::set_window_size(const Vector2 win_size) {
  _window.frame.set_size(win_size);
  // Update the size of the node bounding box
  this->set_size(win_size);
}

Color Graph_2D::get_display_background_color() const {
  return _display.color;
}

void Graph_2D::set_display_background_color(const Color color) {
  _display.color = color;
}

Vector2 Graph_2D::get_grid_size() const {
  return _n_grid;
}

void Graph_2D::set_grid_size(const Vector2 grid_size) {
  _n_grid = grid_size;
  _window.set_size(this->get_size());
}

PackedVector2Array Graph_2D::get_data() const {
  return _data1.packed_v2_data;
}

void Graph_2D::set_data(const PackedVector2Array data) {
  _data1.packed_v2_data = data;
  // _data1.set_range();
  LOG(_data1.packed_v2_data);
}

void Graph_2D::_draw_window() {
  /* _draw() is called every frame(?) or maybe when there is changes
  to the canvas (need to double check), so this allows user to resize the 
  window by controlling the Node bounding box */
  _window.frame.set_size(this->get_size());
  draw_rect(_window.frame, _window.color);
}

void Graph_2D::_draw_display() {
  // Calculate the margins between the window and display frame
  Vector2 window_pos_top_left = _window.frame.get_position();
  Vector2 window_size = _window.frame.get_size();

  Vector2 margin = Vector2(30, 30);
  /* 2x margin is required in order to compensate for the offset when using the 
  set_position method */
  _display.frame.set_size(window_size - 2*margin);
  _display.frame.set_position(margin);
  _display.color = black;
  draw_rect(_display.frame, _display.color);
}

void Graph_2D::_draw_grids() {
  _calculate_grid_spacing();
  int font_margin = 12;
  // For column, we start with index 1 since we start drawing from the left, which will overlap with the y-axis
  for (size_t i = 1; i <= _n_grid.x; i++) {

    // Ensure every 5 rows, add some width to help distinguish visually
    float line_width = (i % 5 == 0) ? _grid.width + 4.0 : _grid.width; 

    // Added offset before performing the spacing calculation due to the frame margin
    Vector2 top_column_grid = Vector2(_display.x() + i * _grid_spacing.x, _display.y());
    Vector2 bottom_column_grid = Vector2(_display.x() + i * _grid_spacing.x, _display.y() + _display.y_size());
    draw_line(top_column_grid, bottom_column_grid, _grid.color, line_width);
  }

  // For row, we start with index 0, since we start drawing from the top
  for (size_t i = 0; i <= _n_grid.y; i++) {
    // Added offset before performing the spacing calculation due to the frame margin
    // When dealing with the row grid, remember that we are drawing from the top to bottom
    // where top right corner is origin (0, 0)
    float line_width = (i % 5 == 0) ? _grid.width + 4.0 : _grid.width; 
    Vector2 left_row_grid = Vector2(_display.x(), _display.y() + i * _grid_spacing.y);
    Vector2 right_row_grid = Vector2(_display.x() + _display.x_size(), _display.y() + i * _grid_spacing.y);
    draw_line(left_row_grid, right_row_grid, _grid.color, line_width);
  }
}

String Graph_2D::_format_string(const float &val, int dp = 1) {
  String fmt_str(String::num(val, dp));
  if (not fmt_str.contains(".")) {
    fmt_str = fmt_str + ".";
    for (size_t i = 0; i < dp; i++) {
      fmt_str = fmt_str + "0";
    }
  }
  return fmt_str;
}

void Graph_2D::_draw_axis() {
  // y-axis
  draw_line(_display.top_left(), _display.bottom_left(), _axis.color, _axis.width);
  // x-axis
  draw_line(_display.bottom_left(), _display.bottom_right(), _axis.color, _axis.width);

  int font_size = 16;
  int font_margin = font_size + 10;

  float x_step = _data1.get_x_diff<float>() / _n_grid.x;
  float y_step = _data1.get_y_diff<float>() / _n_grid.y;

  LOG("------ _draw_axis() START ------")
  LOG(x_step, " ", y_step);
  LOG(_data1.x_min(), " ", _data1.x_max());
  LOG(_data1.y_min(), " ", _data1.y_max());

  for (size_t i = 0; i <= _n_grid.x; i++) {
    // Added offset before performing the spacing calculation due to the frame margin
    Vector2 font_pos = Vector2(_display.x() + i * _grid_spacing.x, _display.y() + _display.y_size());
    // Add minimum to offset the axis label
    float x = _data1.x_min() + i * x_step;
    String fmt_x_str = _format_string(x);
    // Added offset here (hardcoded for now) to prettify formatting
    draw_string(_axis.font, Vector2(font_pos.x - 10, font_pos.y + font_margin), fmt_x_str, HORIZONTAL_ALIGNMENT_CENTER, (-1.0F), font_size);
  }

  // For row, we start with index 0, since we start drawing from the top
  for (size_t i = 0; i <= _n_grid.y; i++) {
    // Added offset before performing the spacing calculation due to the frame margin
    // When dealing with the row grid, remember that we are drawing from the top to bottom
    // where top right corner is origin (0, 0)
    Vector2 font_pos = Vector2(_display.x(), _display.y() + i * _grid_spacing.y);
    float y = _data1.y_min() + (_n_grid.y - i) * y_step;
    String fmt_y_str = _format_string(y);
    draw_string(_axis.font, Vector2(font_pos.x - font_margin, font_pos.y), fmt_y_str, HORIZONTAL_ALIGNMENT_CENTER, (-1.0F), font_size);
  }
  LOG("------ _draw_axis() END ------")
}

void Graph_2D::_draw_ticks() {
}

PackedVector2Array Graph_2D::_coordinate_to_pixel(const PackedVector2Array &data) {
  PackedVector2Array data_pixel_pos;
  for (size_t i = 0; i < data.size(); i++) {
    double x_pixel = UtilityFunctions::remap(data[i].x, _data1.x_min(), _data1.x_max(), _display.bottom_left().x, _display.x() + _display.x_size());
    double y_pixel = UtilityFunctions::remap(data[i].y, _data1.y_min(), _data1.y_max(), _display.bottom_left().y, _display.bottom_left().y - _display.y_size());
    data_pixel_pos.append(Vector2(x_pixel, y_pixel));
    LOG("Coordinate: ", data[i], " Pixel: ", Vector2(x_pixel, y_pixel));
  }
  return data_pixel_pos;
}

void Graph_2D::_draw_plot() {
  // Ensure the range in the display frame is within range
  _data1.set_range();
  if (_data1.packed_v2_data.is_empty()) {
    return;
  }
  // TODO: Optimize this so that it does not do it multiple times every drawing frame
  PackedVector2Array data = _coordinate_to_pixel(_data1.packed_v2_data);
  // Enable anti-aliasing for better resolution
  // Source: https://docs.godotengine.org/en/stable/tutorials/2d/2d_antialiasing.html
  // TODO: Allow anti-aliasing to be toggled on and off during runtime
  draw_polyline(data, _data1.color, _data1.width, true);
  for (size_t i = 0; i < data.size(); i++) {
    draw_circle(data[i], 5.0, _data1.color);
  }
}