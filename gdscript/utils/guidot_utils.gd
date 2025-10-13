# @tool
class_name Guidot_Utils
# extends Node

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR

static func per_255(val: float) -> float:
	return (val/255) 

static func rgba(r: int, g: int, b: int, a: int) -> Color:
	return Color(per_255(r), per_255(g), per_255(b), per_255(a))

static var color_dict: Dictionary = {
	"white": Color.WHITE,
	"black": Color(0.1, 0.1, 0.1, 1),
	"dim_black": Color(0.3, 0.3, 0.3, 0.1),
	"grey": Color(0.12, 0.12, 0.12, 1),
	"red": Color.RED,
	"blue": Color.BLUE,

	# Godot editor color scheme
	"gd_black": Color(0.1, 0.12, 0.15, 1), 	# Same as Godot text editor background color
	"gd_bright_green": Color(per_255(172), per_255(221), per_255(206), 1), 	# Same blue color as when files are highlighted when editing the file
	"gd_light_blue": Color(per_255(56), per_255(79), per_255(103), 1), 	# Same blue color as when files are highlighted when editing the file
	"gd_dim_blue": Color(per_255(56), per_255(79), per_255(103), 0.15), 	# Same blue color as when files are highlighted when editing the file but more transparent
	"gd_bright_yellow": rgba(240,223,152,255),  # Same as yellow color for the text in godot text editor
	"gd_grey": rgba(145,149,155,25), # Same as godot's debugging message color,
	"gd_grey_transparent": rgba(54, 61, 74, 125),
}

static var some_val: int = 10

# Programmatically add action keys
static func add_action_with_keycode(action, key):
	var event = InputEventKey.new()
	event.physical_keycode = key
	InputMap.add_action(action)
	InputMap.action_add_event(action, event)
	Guidot_Log.gd_log(LOG_INFO, "UTILS", [action, " hotkeys registered"])
