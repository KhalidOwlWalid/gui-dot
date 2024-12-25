#include "gdexample.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void GDExample::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_amplitude"), &GDExample::get_amplitude);
	ClassDB::bind_method(D_METHOD("set_amplitude", "p_amplitude"), &GDExample::set_amplitude);

	ClassDB::bind_method(D_METHOD("get_speed"), &GDExample::get_speed);
	ClassDB::bind_method(D_METHOD("set_speed", "p_speed"), &GDExample::set_speed);

	ClassDB::bind_method(D_METHOD("get_test"), &GDExample::get_test);
	ClassDB::bind_method(D_METHOD("set_test", "test"), &GDExample::set_test);

	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "amplitude"), "set_amplitude", "get_amplitude");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "speed", PROPERTY_HINT_RANGE, "0,20,0.01"), "set_speed", "get_speed");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "_test", PROPERTY_HINT_RANGE, "0,20,0.01"), "set_test", "get_test");

	ADD_SIGNAL(MethodInfo("position_changed", PropertyInfo(Variant::OBJECT, "node"), PropertyInfo(Variant::VECTOR2, "new_pos")));

}

GDExample::GDExample() {
	// Initialize any variables here.
	time_passed = 0.0;
	amplitude = 10.0;
	speed = 1.0;
	time_emit = 0.0;
	_test = 0.0;
}

GDExample::~GDExample() {
	// Add your cleanup here.
}

void GDExample::_process(double delta) {
	time_passed += delta;

	Vector2 new_position = Vector2(
		speed * (amplitude + (amplitude * sin(time_passed * 2.0))),
		speed * (amplitude + (amplitude * cos(time_passed * 1.5)))
	);

	set_position(new_position);
	
	time_emit += delta;
	if (time_emit > 1.0) {
		emit_signal("position_changed", this, new_position);
		time_emit = 0.0;
	}
}

void GDExample::set_amplitude(const double p_amplitude) {
	amplitude = p_amplitude;
}

double GDExample::get_amplitude() const {
	return amplitude;
}

void GDExample::set_speed(const double p_speed) {
	speed = p_speed;
}

double GDExample::get_speed() const {
	return speed;
}

double GDExample::get_test() const {
	return _test;
}

void GDExample::set_test(const double test) {
	_test = test;
}