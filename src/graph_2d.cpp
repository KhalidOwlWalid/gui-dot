#include "graph_2d.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Graph_2D::_bind_methods() {

  // Test
  BIND_ENUM_CONSTANT(FAIL);
  BIND_ENUM_CONSTANT(SUCCESS);

	ClassDB::bind_method(D_METHOD("get_window_background_color"), &Graph_2D::get_window_background_color);
	ClassDB::bind_method(D_METHOD("set_window_background_color", "color"), &Graph_2D::set_window_background_color);

	ClassDB::bind_method(D_METHOD("get_window_size"), &Graph_2D::get_window_size);
	ClassDB::bind_method(D_METHOD("set_window_size", "win_size"), &Graph_2D::set_window_size);

	ClassDB::bind_method(D_METHOD("get_display_background_color"), &Graph_2D::get_display_background_color);
	ClassDB::bind_method(D_METHOD("set_display_background_color", "color"), &Graph_2D::set_display_background_color);

	ClassDB::bind_method(D_METHOD("get_grid_size"), &Graph_2D::get_grid_size);
	ClassDB::bind_method(D_METHOD("set_grid_size", "grid_size"), &Graph_2D::set_grid_size);

  ClassDB::bind_method(D_METHOD("add_data_with_keyword", "data", "keyword"), &Graph_2D::add_new_data_with_keyword);
  ClassDB::bind_method(D_METHOD("update_data_with_keyword", "data", "keyword"), &Graph_2D::update_data_with_keyword);
  ClassDB::bind_method(D_METHOD("get_data_with_keyword", "keyword"), &Graph_2D::get_data_with_keyword);
  ClassDB::bind_method(D_METHOD("append_data_with_keyword", "keyword", "data"), &Graph_2D::append_data_with_keyword);
  ClassDB::bind_method(D_METHOD("append_data_array_with_keyword", "keyword", "data_array"), &Graph_2D::append_data_array_with_keyword);

	ClassDB::bind_method(D_METHOD("get_data_line_color", "n"), &Graph_2D::get_data_line_color);
	ClassDB::bind_method(D_METHOD("set_data_line_color", "color", "n"), &Graph_2D::set_data_line_color);

	ClassDB::bind_method(D_METHOD("get_y_range"), &Graph_2D::get_y_range);
	ClassDB::bind_method(D_METHOD("set_y_range", "keyword", "min", "max"), &Graph_2D::set_y_range);

	ClassDB::bind_method(D_METHOD("get_x_range"), &Graph_2D::get_x_range);
	ClassDB::bind_method(D_METHOD("set_x_range", "keyword", "min", "max"), &Graph_2D::set_x_range);

	ClassDB::bind_method(D_METHOD("set_antialiased_flag", "flag"), &Graph_2D::set_antialiased_flag);

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
  _init_font();

  // add_new_data_with_keyword("Drone speed (m/s)", test_data, red);

  ticks = Time::get_singleton()->get_ticks_usec();
  last_update_ticks = ticks;
  _initialized = true;
}

void Graph_2D::_notification(const int p_what) {
  // switch (p_what) {

  //   case NOTIFICATION_POSTINITIALIZE: {
  //     LOG(INFO, "NOTIFICATION_POSTINITIALIZE");
  //     break;
  //   }

  //   case NOTIFICATION_ENTER_TREE: {
  //     LOG(INFO, "NOTIFICATION_ENTER_TREE");
  //     break;
  //   }

  //   case NOTIFICATION_READY: {
  //     LOG(INFO, "NOTIFICATION_READY");
  //     break;
  //   }

  //   case NOTIFICATION_EXIT_TREE: {
  //     LOG(INFO, "NOTIFICATION_EXIT_TREE");
  //     break;
  //   }

  //   case NOTIFICATION_PREDELETE: {
  //     LOG(INFO, "NOTIFICATION_PREDELETE");
  //     break;
  //   }
  // }
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
  _preprocess_data();
  _draw_grids();
  _draw_axis();
  if (not data_vector.empty()) {
    _draw_plot();
  }
}

void Graph_2D::_process(double delta) {
}

void Graph_2D::_init_font() {
  _font_manager = get_theme_default_font();
}

Color Graph_2D::get_window_background_color() const {
  return _window.color;
}

void Graph_2D::set_window_background_color(const Color &color) {
  _window.color = color;
  queue_redraw();
}

Vector2 Graph_2D::get_window_size() const {
  return _window.frame.size;
}

void Graph_2D::set_window_size(const Vector2 &win_size) {
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

Color Graph_2D::get_data_line_color(const int n) const {
  return data_vector.at(n).color;
}

void Graph_2D::set_data_line_color(const Color &color, const int n) {
  data_vector.at(n).color = color;
}

Vector2 Graph_2D::get_y_range(const String keyword) const {
  Vector2 tmp;
  return tmp;
}

void Graph_2D::set_y_range(const String keyword, const float min, const float max) {
  for (size_t i=0; i < data_vector.size(); i++) {
    if (data_vector.at(i).keyword.casecmp_to(keyword) == 0) {
      data_vector.at(i).set_y_range(min, max);
      LOG(INFO, "Setting y range with the following setting: ", data_vector.at(i).y_range);
      // Lock the y-axis since the user is taking over
      // If not, the axis will be dynamically drawn to reflect the changes of the data
      data_vector.at(i).is_y_axis_lock = true;
      queue_redraw();
      // Note: This function should only do for one keyword, no need to iterate anymore once found
      break;
    }
  }
}

Vector2 Graph_2D::get_x_range(const String keyword) const {
  Vector2 tmp;
  return tmp;
}

void Graph_2D::set_x_range(const String keyword, const float min, const float max) {
  for (size_t i=0; i < data_vector.size(); i++) {
    if (data_vector.at(i).keyword.casecmp_to(keyword) == 0) {
      data_vector.at(i).set_x_range(min, max);
      LOG(INFO, "Setting y range with the following setting: ", data_vector.at(i).y_range);
      // Lock the y-axis since the user is taking over
      // If not, the axis will be dynamically drawn to reflect the changes of the data
      data_vector.at(i).is_x_axis_lock = true;
      queue_redraw();
      // Note: This function should only do for one keyword, no need to iterate anymore once found
      break;
    }
  }
}

void Graph_2D::set_antialiased_flag(const bool flag) {
  LOG(INFO, "Antialised flag set to", flag);
  use_antialiased = flag;
}

Graph_2D::Status Graph_2D::add_new_data_with_keyword(const String &keyword, const PackedVector2Array &data, const Color line_color) {
  Data_t new_data;
  // TODO: Check if the current keyword exist or not before placing the data
  // TODO: Do some assertion by checking if the new keyword is updated in the vector or not
  new_data.packed_v2_data = data;
  new_data.keyword = keyword;
  new_data.color = line_color;
  data_vector.push_back(new_data);
  return SUCCESS;
}

Graph_2D::Status Graph_2D::update_data_with_keyword(const String &keyword, const PackedVector2Array &data) {
  for (size_t i = 0; i < data_vector.size(); i++) {
    Data_t &curr_data = data_vector.at(i);
    if (curr_data.keyword.casecmp_to(keyword) == 0) {
      curr_data.packed_v2_data = data;
      queue_redraw();
      return SUCCESS;
    } else {
      LOG(INFO, "No data with keyword (", keyword, ") found.");
    }
  }
  return FAIL;
}

// TODO: Implement this so we can append data instead of referencing the whole data multiple times
Graph_2D::Status Graph_2D::append_data_with_keyword(const String &keyword, const float &data) {
  for (size_t i = 0; i < data_vector.size(); i++) {
    Data_t &curr_data = data_vector.at(i);
    if (curr_data.keyword.casecmp_to(keyword) == 0) {
      float curr_time = Time::get_singleton()->get_ticks_usec();
      curr_data.packed_v2_data.append(Vector2(curr_time * 1e-6, data));
      queue_redraw();
      return SUCCESS;
    } else {
      LOG(INFO, "No data with keyword (", keyword, ") found.");
    }
  }
  return FAIL; 
}

Graph_2D::Status Graph_2D::append_data_array_with_keyword(const String &keyword, const PackedVector2Array &data_array) {
  for (size_t i = 0; i < data_vector.size(); i++) {
    Data_t &curr_data = data_vector.at(i);
    if (curr_data.keyword.casecmp_to(keyword) == 0) {
      curr_data.packed_v2_data.append_array(data_array);
      queue_redraw();
      return SUCCESS;
    } else {
      LOG(INFO, "No data with keyword (", keyword, ") found.");
    }
  }
  return FAIL; 
}

PackedVector2Array Graph_2D::get_data_with_keyword(const String &keyword) const {
  if (data_vector.empty()) {
    LOG(INFO, "No data available to get");
    return PackedVector2Array();
  }
  for (size_t i = 0; i < data_vector.size(); i++) {
    Data_t curr_data = data_vector.at(i);
    if (curr_data.keyword.casecmp_to(keyword) == 0) {
      return curr_data.packed_v2_data;
    } else {
      LOG(INFO, "No data with keyword (", keyword, ") found.");
    }
  }
  // If no such keyword is found, then return an empty vector array
  return PackedVector2Array();
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
  int display_margin;
  if (data_vector.empty()) {
    // Force 1 to ensure that the display is correctly drawn
    // Resize the display to accomodate for the number of expected data type plotted
    display_margin = (_axis.width + font_size + font_margin + label_margin);
  } else {
    // TODO: Refactor this code, this is a temporary hack to gauge the size of the tick labels
    String tmp;
    for (size_t i = 0; i < max_digit_size; i++) {
      tmp = tmp + "0";
    }
    // NOTE: +30 added on Vector2.y to pretify format
    display_margin = data_vector.size() * (_axis.width + _font_manager->get_string_size(tmp).x + _axis.width + 30);
  }

  // NOTE: +50 added on top of display_margin to contain the display within the borders of window frame
  _display.set_size(window_size - Vector2(display_margin + 50, 60));
  _display.frame.set_position(Vector2(display_margin, 30));

  draw_rect(_display.frame, _display.color);
}

/// @brief Data preprocessing is done to minimize the number of data points needed to be plotted
/// by calculating the necessary level of details (LOD). This method implements a sliding window
/// method for achieving LOD plots.
void Graph_2D::_preprocess_data() {
  // Take the full dataset and calculate the required data to be displayed 
  if (data_vector.empty()) {
    return;
  }

  for (size_t n = 0; n < data_vector.size(); n++) { 
    // If the current data has no populated data, then do not proceed, skip to the next dataset
    Data_t &curr_data = data_vector.at(n);
    // tmp to avoid crash
    if (curr_data.packed_v2_data.is_empty()) {
        continue;
    }

    // TODO(Khalid): Change this to a parameter controlled by the user
    int min_samples_required = 10;
    const int data_size = curr_data.packed_v2_data.size();

    // Skip time calculations if insufficient data is available
    // The +1 accounts for the fact that sample times are calculated between the current sample time
    // and the next sample time
    if (data_size < min_samples_required + 1) {
      curr_data.lod_data = curr_data.packed_v2_data;
    } else {
      curr_data.calculate_sample_time(min_samples_required);
      // Extract the most recent data within the sliding window duration
      // TODO(Khalid): Allow this setting to be configurable to the user through the use of API
      int  sliding_window_length = static_cast<int>(floor(sliding_window_duration/curr_data.ts));
      curr_data.lod_data = curr_data.packed_v2_data.slice(data_size - std::min(data_size, sliding_window_length), data_size - 1);
    }
    // Obtain the max and min value of both x and y axis
    curr_data.set_range();
  }

  float curr_time = static_cast<float>(Time::get_singleton()->get_ticks_usec() * 1e-6);
  float min_window_time = static_cast<float>(curr_time - sliding_window_duration);
  _sw_info.t_min = std::max((float)0.0, min_window_time);
  _sw_info.t_max = std::max(sliding_window_duration, curr_time);
}

void Graph_2D::_draw_grids() {
  _calculate_grid_spacing();
  // For column, we start with index 1 since we start drawing from the left, which will overlap with the y-axis
  // To perform moving grid axis, we first need to calculate the required number of grids on the x-axis as the axis moves
  float multiples = 5.0;
  float t_min_floor = static_cast<float>(round_down_to_nearest_multiple(_sw_info.t_min, multiples));
  float t_max_floor = static_cast<float>(round_down_to_nearest_multiple(_sw_info.t_max, multiples));
  const int n_grid_x = static_cast<int>((t_max_floor - t_min_floor) / multiples);

  LOG(DEBUG, "Inside draw grids: ", t_min_floor, " ", t_max_floor, " ", n_grid_x);

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

String Graph_2D::_format_axis_label(const float &val, int dp = 1) {

  // TODO: Allow formatting to be dynamic
  String fmt_str(String::num(val, dp));
  
  // Note: Checks if the value has decimal or not, if not add
  // To ensure consistency, we first check that the value has decimal
  // Then, determine the number of characters there before the decimal
  // We should probably return this to allow for dynamic font formatting when drawing the axis

  // Check if decimals exist on the value, a value of 2 means that there is the number
  // before and after the decimal
  if (fmt_str.get_slice_count(".") < 2) {
    fmt_str = fmt_str + ".";
    for (size_t i = 0; i < dp; i++) {
      fmt_str = fmt_str + "0";
    }
  }

  // Although we have already padded zeros in the above implementation
  // This is to catch if there is any unpadded zeros for labels that already
  // have decimals but is less than the set number of dp
  int num_digits_after_delim = fmt_str.get_slice(".", 1).length();
  if (num_digits_after_delim != dp) {
    int zeros_to_pad = abs(num_digits_after_delim - dp);
    for (size_t i = 0; i < zeros_to_pad; i++) {
      fmt_str = fmt_str + "0";
    }
  }

  /* BUGFIX: This is just a temporary solution, the function is called for both x and y axis
  So the way y tick labels are drawn is affected by the string size of x.
  Example: if x-tick label is 10 digit long, and y-tick label is less than that, the margins
  created on the y-tick labels are based on the x-tick label (which is not what it is supposed
  to be doing)*/ 
  max_digit_size = fmt_str.length() > max_digit_size ? fmt_str.length() : max_digit_size;

  return fmt_str;
}

void Graph_2D::_draw_axis() { 
  // Ensure that axis is still drawn eventhough data vector is still empty
  if (data_vector.empty()) {
    // Just draw the axis line
    draw_line(_display.top_left(), _display.bottom_left(), _axis.color, _axis.width);
    // x-axis
    draw_line(_display.bottom_left(), _display.bottom_right(), _axis.color, _axis.width);
    return;
  }

  // Draw multiple y-axis
  for (size_t n = 0; n < data_vector.size(); n++) {
    const Vector2 offset = Vector2(n*(_axis.width + font_size + font_margin + 20), 0);
    // y-axis
    draw_line(_display.top_left() - offset, _display.bottom_left() - offset, _axis.color, _axis.width);
    // x-axis
    draw_line(_display.bottom_left(), _display.bottom_right(), _axis.color, _axis.width);
    
    // If the current data has no populated data, then do not proceed, skip to the next dataset
    Data_t &curr_data = data_vector.at(n);
    if (curr_data.lod_data.is_empty()) {
        continue;
    }
  
    const int tmp = _n_grid.y;
    float y_step = curr_data.get_y_diff<float>() / tmp;

    for (size_t i = 0; i <= tmp; i++) {
      /* NOTE: Added offset before performing the spacing calculation due to the frame margin
      When dealing with the row grid, remember that we are drawing from the bottom to top
      where top right corner is origin (0, 0) */
      /* HACK: For now, this formatting works for multiple y-axis but this is a really terrible hack.
      Figure out a way to parametrize all of the below parameters or magic number. At the moment, this formatting works
      for 1 dp or 2 dp, as soon as 3dp and above is used, it becomes really horrible to read. I'd assume, no one would
      really use 3 dp, but sometimes, you have to take that into consideration. */
      float y = curr_data.y_min() + (i) * y_step;
      String fmt_y_str = _format_axis_label(y, dp);
      // NOTE: +30 to x font pos to prettify tick labels position
      Vector2 font_pos = Vector2(_window.x() + 30, _display.y() + (tmp - i) * _grid_spacing.y + _font_manager->get_string_size(fmt_y_str).y - 20);
      draw_string(_font_manager, font_pos, fmt_y_str, HORIZONTAL_ALIGNMENT_LEFT, (-1.0F), font_size);
    } 
    // Orient this in 90 degree clockwise
    draw_set_transform(Vector2(0, 0), -Math_PI/2);
    draw_string(_font_manager, Vector2(-(_window.bottom_left().y - _window.y_size()/2 + _font_manager->get_string_size(curr_data.keyword).x/2), 15), curr_data.keyword);
    // WARNING: This transform needs to be reset if not it will affect all drawings that comes after!
    draw_set_transform(Vector2(0, 0), 0);
  }

  /* HACK: This shouldnt be left in production, for now, only use one of the data struct to set the x-axis
  The graph should be able to support multiple axis. This will cause issues if data vector 1 is empty. */
  // Data_t curr_data = data_vector.at(0);
  // float x_step = curr_data.get_x_diff<float>() / _n_grid.x;
  // for (size_t i = 0; i <= _n_grid.x; i++) {
  //   // Added offset before performing the spacing calculation due to the frame margin
  //   Vector2 font_pos = Vector2(_display.x() + i * _grid_spacing.x, _display.y() + _display.y_size());
  //   // Add minimum to offset the axis label
  //   float x = curr_data.x_min() + i * x_step;
  //   String fmt_x_str = _format_axis_label(x);
  //   // Added offset here (hardcoded for now) to prettify formatting
  //   draw_string(_axis.font, Vector2(font_pos.x - font_size/2, font_pos.y + font_margin/2), fmt_x_str, HORIZONTAL_ALIGNMENT_CENTER, (-1.0F), font_size);
  // }

  Data_t curr_data = data_vector.at(0);
  float x_step = sliding_window_duration / _n_grid.x;
  for (size_t i = 0; i <= _n_grid.x; i++) {
    // Added offset before performing the spacing calculation due to the frame margin
    Vector2 font_pos = Vector2(_display.x() + i * _grid_spacing.x, _display.y() + _display.y_size());
    // Add minimum to offset the axis label
    float x = _sw_info.t_min + i * x_step;
    String fmt_x_str = _format_axis_label(x);
    // Added offset here (hardcoded for now) to prettify formatting
    draw_string(_axis.font, Vector2(font_pos.x - font_size/2, font_pos.y + font_margin/2), fmt_x_str, HORIZONTAL_ALIGNMENT_CENTER, (-1.0F), font_size);
  }
}

Vector2 Graph_2D::_coordinate_to_pixel(const Vector2 &data, const Vector2 &x_range, const Vector2 &y_range) {
  PackedVector2Array data_pixel_pos;

  float x_min = x_range[0];
  float x_max = x_range[1];
  float y_min = y_range[0];
  float y_max = y_range[1];

  Vector2 pixel_pos;
  pixel_pos.x = UtilityFunctions::remap(data.x, x_min, x_max, _display.bottom_left().x, _display.x() + _display.x_size());
  pixel_pos.y = UtilityFunctions::remap(data.y, y_min, y_max, _display.bottom_left().y, _display.bottom_left().y - _display.y_size());

  return pixel_pos;
}

void Graph_2D::_draw_plot() {
  // FIXME: When plotting a constant value over time, the whole axis will be that constant value
  // For instance, if you're plotting 1 at the y-axis constantly, it will be 1 to 1
  if (data_vector.empty()) {
    LOG(DEBUG, "Data vector is empty. Plot will not be drawn.");
    return;
  }

  for (size_t n = 0; n < data_vector.size(); n++) {
    Data_t &curr_data = data_vector.at(n);
    if (curr_data.lod_data.is_empty()) {
      continue;
    }

    /* Technically, we only care about the rendering. Data storing should only be done by another data server node (To be made).
    Hence, we can run some pre-processing to remove any non-visible data by taking it into chunks. In a way the relationship works this way:
    
    IO -> Data server -> call update data method of graph_2d -> graph 2d pre-process the data -> plot only visible datasets
    
    Pre-process step:
    - Graph 2D creates local copy of the data from the server data node
    - Data is split into chunks (decide how this will be split, maybe half, quarter?)
    - Data is pre-processed through the use of multiple threads to determine which points are visible
    - Merge
    - Plot only visible datasets

    */
    for (size_t i = 0; i < curr_data.lod_data.size() - 1; i++) {

      // const Vector2 curr_pixel_pos = _coordinate_to_pixel(curr_data.lod_data[i], curr_data.x_range, curr_data.y_range);
      // const Vector2 next_pixel_pos = _coordinate_to_pixel(curr_data.lod_data[i + 1], curr_data.x_range, curr_data.y_range);

      const Vector2 curr_pixel_pos = _coordinate_to_pixel(curr_data.lod_data[i], _sw_info.range(), curr_data.y_range);
      const Vector2 next_pixel_pos = _coordinate_to_pixel(curr_data.lod_data[i + 1], _sw_info.range(), curr_data.y_range);
      bool curr_point_visible = curr_pixel_pos.y < _display.bottom_left().y && curr_pixel_pos.y > _display.top_left().y;
      bool next_point_visible = next_pixel_pos.y < _display.bottom_left().y && next_pixel_pos.y > _display.top_left().y;

      if (not curr_point_visible && not next_point_visible) {
        // If both points are not visible, then skip to the next dataset
        continue;
      } else if (curr_point_visible && next_point_visible) {
        // Enable anti-aliasing for better resolution
        // Source: https://docs.godotengine.org/en/stable/tutorials/2d/2d_antialiasing.html
        // This will help in optimizing the performance when we are drawing multiple lines at once
        draw_line(curr_pixel_pos, next_pixel_pos, curr_data.color, 1.0, use_antialiased);
        // BUGFIX?: For some reason, drawing with circles make the program to run really slow
        // draw_circle(curr_data.pixel_pos_v2_data[i + 1], 5.0, curr_data.color);
      } else {
        // Interpolate
        float y3;
        float m = (curr_pixel_pos.y - next_pixel_pos.y) / (curr_pixel_pos.x - next_pixel_pos.x);
        // NOTE: Pixel coordinates increment from top to bottom, so points above the top display border would be smaller
        if ((not next_point_visible && next_pixel_pos.y < _display.top_left().y) || (not curr_point_visible && curr_pixel_pos.y < _display.top_left().y)) {
          y3 = _display.top_left().y;
        } else {
          // Conditions trigger if either points not visible, but it is bigger than the bottom display border
          y3 = _display.bottom_left().y;
        }
        float x3 = (y3 - curr_pixel_pos.y)/(m) + curr_pixel_pos.x;
        if (next_point_visible) {
          draw_line(Vector2(x3, y3), next_pixel_pos, curr_data.color, 1.0, use_antialiased);
        } else {
          // HACK: Solution to ghost point, without this, there will be unconnected points between the ghost point and the next point (i+1)
          draw_line(Vector2(x3, y3), next_pixel_pos, curr_data.color, 1.0, use_antialiased);
        }
      }
    }
  }
}
