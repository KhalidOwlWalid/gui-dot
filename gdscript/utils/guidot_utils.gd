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

static var some_val: int = 10

# Programmatically add action keys
static func add_action_with_keycode(action, key):
	var event = InputEventKey.new()
	event.physical_keycode = key
	InputMap.add_action(action)
	InputMap.action_add_event(action, event)
	Guidot_Log.gd_log(LOG_INFO, "UTILS", [action, " hotkeys registered"])

static func generate_unique_name(node: Node, type: String) -> String:
	var name: String = type + "[" + str(node.get_instance_id()) + "]"
	return name

static func get_color(guidot_color: String) -> Color:
	var color_dict: Dictionary = {
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
	return color_dict[guidot_color]

static func create_dropdown_selection_row(label_text: String,  dropdown_items: Array, custom_min_size: Vector2) -> MarginContainer:

	# Internal properties of the dropdown selection row
	var margin_size: int = 5
	
	# All nodes required to create the dropdown
	var panel_container1 = MarginContainer.new()
	var hbox1 = HBoxContainer.new()
	var label1 = Label.new()
	var option_button1 = OptionButton.new()

	hbox1.custom_minimum_size = custom_min_size
	label1.custom_minimum_size = custom_min_size
	option_button1.custom_minimum_size = custom_min_size

	# Control the margin size of each dropdown selection so that it looks nicer in the GUI
	panel_container1.add_theme_constant_override("margin_top", margin_size)
	panel_container1.add_theme_constant_override("margin_bottom", margin_size)
	panel_container1.add_theme_constant_override("margin_left", margin_size)
	panel_container1.add_theme_constant_override("margin_right", margin_size)
	
	# Set the labels properties
	label1.text = label_text
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	option_button1.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in len(dropdown_items):
		option_button1.add_item(str(dropdown_items[i]))

	# Add the labels and the dropdown selection to the HBOX Container
	hbox1.add_child(label1)
	hbox1.add_child(option_button1)
	panel_container1.add_child(hbox1)

	return panel_container1

static func create_label_row(label_text: String, label_value, custom_min_size: Vector2,) -> MarginContainer:
	# Internal properties of the dropdown selection row
	var margin_size: int = 5
	
	# All nodes required to create the dropdown
	var panel_container1 = MarginContainer.new()
	var hbox1 = HBoxContainer.new()
	var label = Label.new()
	var value = Label.new()

	hbox1.custom_minimum_size = custom_min_size
	label.custom_minimum_size = custom_min_size
	value.custom_minimum_size = custom_min_size

	# Control the margin size of each dropdown selection so that it looks nicer in the GUI
	panel_container1.add_theme_constant_override("margin_top", margin_size)
	panel_container1.add_theme_constant_override("margin_bottom", margin_size)
	panel_container1.add_theme_constant_override("margin_left", margin_size)
	panel_container1.add_theme_constant_override("margin_right", margin_size)
	
	# Set the labels properties
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	value.text = str(label_value)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Add the labels and the dropdown selection to the HBOX Container
	hbox1.add_child(label)
	hbox1.add_child(value)
	panel_container1.add_child(hbox1)

	return panel_container1

# Takes in the configuration tab and helps populate the internal VBoxContainer
static func add_config_rows(config_tab: AspectRatioContainer, config_rows: Array[Node]) -> void:
	var config_tab_vbox: VBoxContainer  = config_tab.get_children()[0]
	
	for row in config_rows:
		config_tab_vbox.add_child(row)

static func _create_checkbox_with_label(label: String, flag: bool) -> HBoxContainer:
	var l_hbox1: HBoxContainer = HBoxContainer.new()
	var l_cbox1: CheckBox = CheckBox.new()
	l_cbox1.text = label
	l_cbox1.button_pressed = flag

	l_hbox1.add_child(l_cbox1)

	return l_hbox1
