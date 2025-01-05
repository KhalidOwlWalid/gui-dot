#include "graph_2d.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Graph_2D::_bind_methods() {

	ClassDB::bind_method(D_METHOD("get_window_background_color"), &Graph_2D::get_window_background_color);
	ClassDB::bind_method(D_METHOD("set_window_background_color", "color"), &Graph_2D::set_window_background_color);

	ClassDB::bind_method(D_METHOD("get_window_size"), &Graph_2D::get_window_size);
	ClassDB::bind_method(D_METHOD("set_window_size", "win_size"), &Graph_2D::set_window_size);

	ClassDB::bind_method(D_METHOD("get_display_background_color"), &Graph_2D::get_display_background_color);
	ClassDB::bind_method(D_METHOD("set_display_background_color", "color"), &Graph_2D::set_display_background_color);

	ClassDB::bind_method(D_METHOD("get_grid_size"), &Graph_2D::get_grid_size);
	ClassDB::bind_method(D_METHOD("set_grid_size", "grid_size"), &Graph_2D::set_grid_size);

	ClassDB::bind_method(D_METHOD("get_data_vector", "n"), &Graph_2D::get_data_vector);
	ClassDB::bind_method(D_METHOD("set_data_vector", "data", "n"), &Graph_2D::set_data_vector);

	ClassDB::bind_method(D_METHOD("get_data_line_color", "n"), &Graph_2D::get_data_line_color);
	ClassDB::bind_method(D_METHOD("set_data_line_color", "color", "n"), &Graph_2D::set_data_line_color);

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "window_color"), "set_window_background_color", "get_window_background_color");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "Window Frame Size"), "set_window_size", "get_window_size");
	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "Display Color"), "set_display_background_color", "get_display_background_color");
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "Grid Size"), "set_grid_size", "get_grid_size");
}

Graph_2D::Graph_2D() {
  _init();
}

Graph_2D::~Graph_2D() {
}

void Graph_2D::_init() {
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

  _axis.font = this->get_theme_default_font();

  test1.width = 1.0;
  test2.width = 1.0;
  
  // For now, im letting data_vector to only be of size 2
  data_vector.push_back(test1);
  data_vector.push_back(test2);
  set_data_line_color(red, 0);
  set_data_line_color(white, 1);

  ticks = Time::get_singleton()->get_ticks_usec();
  last_update_ticks = ticks;
  _initialized = true;
}

void Graph_2D::_notification(const int p_what) {
  switch (p_what) {

    case NOTIFICATION_ENTER_TREE: {
      LOG(INFO, "NOTIFICATION_ENTER_TREE");
      // _init();
      break;
    }

    case NOTIFICATION_READY: {
      LOG(INFO, "NOTIFICATION_READY");
      break;
    }

    case NOTIFICATION_EXIT_TREE: {
      LOG(INFO, "NOTIFICATION_EXIT_TREE");
      break;
    }
  }
}

void Graph_2D::_calculate_grid_spacing() {
  // Calculate the amount of spacing required per pixel with n_grid
  _grid_spacing.x = static_cast<uint>(_display.x_size() / _n_grid.x);
  _grid_spacing.y = static_cast<uint>(_display.y_size() / _n_grid.y);
}

void Graph_2D::_draw() {
  /* Drawing order is very important to avoid lines overlapping on top of each other 
  (e.g. Drawing display frame before window would cause display frame to be hidden behind
  the window) */
  _draw_window();
  _draw_display();
  _draw_grids();
  _draw_plot();
  _draw_axis();
}

void Graph_2D::_process(double delta) {
  // ticks = Time::get_singleton()->get_ticks_usec();
  // if (ticks - last_update_ticks >= 0.1e6) {
  //   for (size_t i = 0; i <= 1; i++) {
  //     uint64_t curr_tick = Time::get_singleton()->get_ticks_usec();
  //     data_vector.at(i).packed_v2_data.append(Vector2(curr_tick * 1e-6, uf::randf_range(-10, 10)));

  //     if (data_vector.at(i).packed_v2_data.size() > 100) {
  //       data_vector.at(i).packed_v2_data.remove_at(0);
  //     }
  //   }
  //   queue_redraw();
  //   last_update_ticks = Time::get_singleton()->get_ticks_usec();
  // }
}

Color Graph_2D::get_window_background_color() const {
  return _window.color;
}

void Graph_2D::set_window_background_color(const Color &color) {
  _window.color = color;
  queue_redraw();
}

Vector2 godot::Graph_2D::get_window_size() const {
  return _window.frame.size;
}

void godot::Graph_2D::set_window_size(const Vector2 &win_size) {
  _window.frame.set_size(win_size);
  // Update the size of the node bounding box
  set_size(win_size);
  queue_redraw();
}

Color Graph_2D::get_display_background_color() const {
  return _display.color;
}

void Graph_2D::set_display_background_color(const Color &color) {
  _display.color = color;
  queue_redraw();
}

Vector2 Graph_2D::get_grid_size() const {
  return _n_grid;
}

void Graph_2D::set_grid_size(const Vector2 &grid_size) {
  _n_grid = grid_size;
  _window.set_size(this->get_size());
  queue_redraw();
}

PackedVector2Array Graph_2D::get_data_vector(const int n) const {
  // TODO: Assert that n is not out of bound
  return data_vector[n].packed_v2_data;
}

void Graph_2D::set_data_vector(const PackedVector2Array &data, const int n) {
  // TODO: Ensure that n is not out of bound
  data_vector.at(n).packed_v2_data = data;
  queue_redraw();
}

Color Graph_2D::get_data_line_color(const int n) const {
  return data_vector.at(n).color;
}

void Graph_2D::set_data_line_color(const Color &color, const int n) {
  data_vector.at(n).color = color;
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

  // HACK: This operation is done twice in both draw axis and display which may cause future bugs 
  // if not done properly. Get the size of the available data vector
  const int n_data = data_vector.size();
  const int font_size = 16;
  const int font_margin = font_size + 15;

  // Resize the display to accomodate for the number of expected data type plotted
  const int display_margin = n_data * (_axis.width + font_size + font_margin);
  _display.set_size(window_size - Vector2(display_margin + 30, 60));
  _display.frame.set_position(Vector2(display_margin, 30));

  // Vector2 margin = Vector2(30, 30);
  /* 2x margin is required in order to compensate for the offset when using the 
  set_position method */
  // _display.frame.set_size(window_size - 2*margin);
  // _display.frame.set_position(margin);
  draw_rect(_display.frame, _display.color);
}

void Graph_2D::_draw_grids() {
  LOG(DEBUG, "Draw grids");
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

  LOG(DEBUG, "Draw axis");
  // Get the size of the available data vector
  const int n_data = data_vector.size();
  const int font_size = 16;
  const int font_margin = font_size + 15;

  for (size_t n = 0; n < n_data; n++) {
    const Vector2 offset = Vector2(n*(_axis.width + font_size + font_margin), 0);
    // y-axis
    draw_line(_display.top_left() - offset, _display.bottom_left() - offset, _axis.color, _axis.width);
    // x-axis
    draw_line(_display.bottom_left(), _display.bottom_right(), _axis.color, _axis.width);
    
    Data_t curr_data = data_vector.at(n);

    float y_step = curr_data.get_y_diff<float>() / _n_grid.y;

    // For row, we start with index 0, since we start drawing from the top
    for (size_t i = 0; i <= _n_grid.y; i++) {
      /* Added offset before performing the spacing calculation due to the frame margin
      // When dealing with the row grid, remember that we are drawing from the top to bottom
      // where top right corner is origin (0, 0) */
      Vector2 font_pos = Vector2(_display.x(), _display.y() + i * _grid_spacing.y);
      // 0.1 * y_min is to allow some spacing between the lower and upper boundary of the y-axis
      float y = curr_data.y_min() + (_n_grid.y - i) * y_step;
      String fmt_y_str = _format_string(y, 3);
      draw_string(_axis.font, Vector2(font_pos.x - (n + 1) * font_margin - n * (font_margin + _axis.width), font_pos.y), fmt_y_str, HORIZONTAL_ALIGNMENT_CENTER, (-1.0F), font_size);
    }

  }

  /* HACK: This shouldnt be left in production, for now, only use one of the data struct to set the axis
  The graph should be able to support multiple axis */
  Data_t curr_data = data_vector.at(0);

  float x_step = curr_data.get_x_diff<float>() / _n_grid.x;
  // float y_step = curr_data.get_y_diff<float>() / _n_grid.y;

  for (size_t i = 0; i <= _n_grid.x; i++) {
    // Added offset before performing the spacing calculation due to the frame margin
    Vector2 font_pos = Vector2(_display.x() + i * _grid_spacing.x, _display.y() + _display.y_size());
    // Add minimum to offset the axis label
    float x = curr_data.x_min() + i * x_step;
    String fmt_x_str = _format_string(x);
    // Added offset here (hardcoded for now) to prettify formatting
    draw_string(_axis.font, Vector2(font_pos.x - 10, font_pos.y + font_margin), fmt_x_str, HORIZONTAL_ALIGNMENT_CENTER, (-1.0F), font_size);
  }

  // // For row, we start with index 0, since we start drawing from the top
  // for (size_t i = 0; i <= _n_grid.y; i++) {
  //   /* Added offset before performing the spacing calculation due to the frame margin
  //   // When dealing with the row grid, remember that we are drawing from the top to bottom
  //   // where top right corner is origin (0, 0) */
  //   Vector2 font_pos = Vector2(_display.x(), _display.y() + i * _grid_spacing.y);
  //   // 0.1 * y_min is to allow some spacing between the lower and upper boundary of the y-axis
  //   float y = curr_data.y_min() + (_n_grid.y - i) * y_step;
  //   String fmt_y_str = _format_string(y);
  //   draw_string(_axis.font, Vector2(font_pos.x - font_margin, font_pos.y), fmt_y_str, HORIZONTAL_ALIGNMENT_CENTER, (-1.0F), font_size);
  // }
}

void Graph_2D::_draw_ticks() {
}

PackedVector2Array Graph_2D::_coordinate_to_pixel(const PackedVector2Array &data, const Vector2 &x_range, const Vector2 &y_range) {
  PackedVector2Array data_pixel_pos;

  float x_min = x_range[0];
  float x_max = x_range[1];
  float y_min = y_range[0];
  float y_max = y_range[1];

  for (size_t i = 0; i < data.size(); i++) {
    // TODO: Optimize this by pre-computing the remap position outside the for loop
    // Use of inline may optimize it to some extent, but calling it every loop is super f**king stupid
    double x_pixel = UtilityFunctions::remap(data[i].x, x_min, x_max, _display.bottom_left().x, _display.x() + _display.x_size());
    double y_pixel = UtilityFunctions::remap(data[i].y, y_min, y_max, _display.bottom_left().y, _display.bottom_left().y - _display.y_size());
    data_pixel_pos.append(Vector2(x_pixel, y_pixel));
  }
  return data_pixel_pos;
}

void Graph_2D::_draw_plot() {
  // FIXME: When plotting a constant value over time, the whole axis will be that constant value
  // For instance, if you're plotting 1 at the y-axis constantly, it will be 1 to 1

  // TEST IMPLEMENTATION
  LOG(DEBUG, "Draw plot");
  for (size_t n = 0; n < data_vector.size(); n++) {
    Data_t &curr_data = data_vector.at(n);
    if (curr_data.packed_v2_data.is_empty()) {
      continue;
    }
    curr_data.set_range();
    curr_data.cached_pixel_v2_data = _coordinate_to_pixel(curr_data.packed_v2_data, curr_data.x_range, curr_data.y_range);
    for (size_t i = 0; i < curr_data.cached_pixel_v2_data.size() - 1; i++) {
      // Enable anti-aliasing for better resolution
      // Source: https://docs.godotengine.org/en/stable/tutorials/2d/2d_antialiasing.html
      // TODO: Allow anti-aliasing to be toggled on and off during runtime
      // This will help in optimizing the performance when we are drawing multiple lines at once
      draw_line(curr_data.cached_pixel_v2_data[i], curr_data.cached_pixel_v2_data[i + 1], curr_data.color, 1.0, true);
    }
  }
}
