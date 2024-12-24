#include "plot_2d.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Plot_2D::_bind_methods() {
  // TODO: Create a macro to make this process faster?
	ClassDB::bind_method(D_METHOD("get_background_color"), &Plot_2D::get_background_color);
	ClassDB::bind_method(D_METHOD("set_background_color", "color"), &Plot_2D::set_background_color);

	ADD_PROPERTY(PropertyInfo(Variant::COLOR, "_background_color"), "get_background_color", "set_background_color");
}

Plot_2D::Plot_2D() {
  _background_color = Color(0.2, 0.2, 0.2, 1.0);
}

Plot_2D::~Plot_2D() {
}

Color Plot_2D::get_background_color() {
  return _background_color;
}

void Plot_2D::set_background_color(Color color) {
  _background_color = color;
}

void Plot_2D::_draw() {

  // Draw the background
  Rect2 background_rect = Rect2(Vector2(0, 0), get_size());
  draw_rect(background_rect, _background_color);
}