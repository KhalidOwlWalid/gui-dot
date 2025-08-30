@tool
class_name Guidot_Utils
# extends Node

static var color_dict: Dictionary = {
	"white": Color.WHITE,
	"black": Color(0.1, 0.1, 0.1, 1),
	"grey": Color(0.12, 0.12, 0.12, 1),
	"red": Color.RED,
	"blue": Color.BLUE,
	"gd_black": Color.BLACK
}

static var test_dict: Dictionary = {
    "1": 1
}

static var some_val: int = 10

static func hello_world() -> void:
    print("Hello")