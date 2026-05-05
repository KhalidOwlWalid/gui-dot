@tool
class_name Guidot_Movable_Panel
extends PanelContainer

const LOG_DEBUG = Guidot_Log.Log_Level.DEBUG
const LOG_WARNING = Guidot_Log.Log_Level.WARNING
const LOG_INFO = Guidot_Log.Log_Level.INFO
const LOG_ERROR = Guidot_Log.Log_Level.ERROR
const border_width: int = 2

@export var _panel_default_size: Vector2 = Vector2(450, 550)
@onready var _guidot_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var _menu_cont_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var margin_val: int = 8

@onready var _last_mouse_position: Vector2 = Vector2()
@onready var _mouse_in: bool = false

@onready var _new_position: Vector2 = Vector2()
@onready var _drag_direction: Vector2 = Vector2()
@onready var _is_dragging: bool = false
@onready var _dragging_distance: float = 0
@onready var _last_position: Vector2 = Vector2()
var _drag_offset: Vector2

@onready var _is_resizing: bool = false

@onready var _is_in_focus: bool = false
@onready var _is_in_edit_mode: bool = false
@onready var _is_holding_left_click: bool = false
@onready var _exit_edit_mode_ms: float = 1000 # ms, if no second escape is pressed within a second, then the user just wants to exit select mode
@onready var _exit_mode_timer_ms: float = 0

@onready var _menu_panel: PanelContainer = PanelContainer.new()

var i: float = 0
var rate: float = 0.05
var sign: float = 1.0

@onready var _curr_ui_mode: UI_Mode = UI_Mode.NORMAL

@onready var _close_button: Button = Button.new()
@onready var _close_icon: Texture2D = load("res://addons/guidot/icons/close_icon.png")

func _on_close_pressed():
	self.visible = true

@onready var _maximize_button: Button = Button.new()
@onready var _maximize_icon: Texture2D = load("res://addons/guidot/icons/maximize_icon.png")

@onready var _move_button: Button = Button.new()
@onready var _move_icon: Texture2D = load("res://addons/guidot/icons/move_icon.png")

enum UI_Mode {
	NORMAL,
	HOVER,
	SELECTED,
	ACTION,
}

enum Resize_Corner {
	NONE,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
}

enum Edit_Mode {
	NONE,
	POSSIBLE_RESIZING,
	RESIZE,
	POSSIBLE_MOVING,
	MOVE,
}

@onready var edit_mode_str: Dictionary = {
	Edit_Mode.NONE: "NONE",
	Edit_Mode.POSSIBLE_RESIZING: "POSSIBLE_RESIZING",
	Edit_Mode.RESIZE: "RESIZE",
	Edit_Mode.POSSIBLE_MOVING: "POSSIBLE_MOVING",
	Edit_Mode.MOVE: "MOVE",
}

@onready var _curr_edit_mode: Edit_Mode = Edit_Mode.NONE
@onready var _last_edit_mode: Edit_Mode = self._curr_edit_mode

@onready var _active_resize_corner: Resize_Corner = Resize_Corner.NONE
@onready var _last_active_resize_corner: Resize_Corner = Resize_Corner.NONE

func get_component_size() -> Vector2:
	return self.size

func top_left() -> Vector2:
	# Godot's origin system works from the top left
	# So, we know that the top left should always be (0, 0)
	var _top_left: Vector2 = Vector2(0, 0)
	return _top_left

func top_right() -> Vector2:
	var _top_right: Vector2
	var x_new: float
	var y_new: float
	x_new = self.get_component_size().x
	y_new = 0
	_top_right = Vector2(x_new, y_new)
	return _top_right
	
func bottom_left() -> Vector2:
	var _bot_left: Vector2
	var x_new: float
	var y_new: float
	x_new = 0
	y_new = self.get_component_size().y
	_bot_left = Vector2(x_new, y_new)
	return _bot_left

func bottom_right() -> Vector2:
	var _bot_right: Vector2
	var x_new: float
	var y_new: float
	x_new = self.get_component_size().x
	y_new = self.get_component_size().y
	_bot_right = Vector2(x_new, y_new)
	return _bot_right

func _ready() -> void:
	self.name = "Guidot_Movable_Panel"
	self.size = self._panel_default_size

	# Sets the base color of the panel to fit the theme
	_guidot_stylebox.bg_color = Guidot_Utils.get_guidot_base_color()
	_guidot_stylebox.border_color = _guidot_stylebox.bg_color
	_guidot_stylebox.border_width_left   = border_width
	_guidot_stylebox.border_width_right  = border_width
	_guidot_stylebox.border_width_top    = border_width
	_guidot_stylebox.border_width_bottom = border_width
	set_margin_size(self._guidot_stylebox, margin_val)
	add_theme_stylebox_override("panel", _guidot_stylebox)

	self._last_position = self.position
	self._last_mouse_position = self.get_viewport().get_mouse_position()

	# Signals connection
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

	var _vbox: VBoxContainer = VBoxContainer.new()
	var _hbox: HBoxContainer = HBoxContainer.new()
	var _label: Label = Label.new()
	_label.text = self.name
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.custom_minimum_size = Vector2(120, 0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hbox.add_child(_label)

	var _menu_cont_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	_menu_cont_stylebox.bg_color = Guidot_Utils.get_color("menu_panel_cont")
	_menu_cont_stylebox.border_color = _menu_cont_stylebox.bg_color
	var _menu_border_width: int = 2
	_menu_cont_stylebox.border_width_left   = _menu_border_width
	_menu_cont_stylebox.border_width_right  = _menu_border_width
	_menu_cont_stylebox.border_width_top    = _menu_border_width
	_menu_cont_stylebox.border_width_bottom = _menu_border_width
	self.set_margin_size(_menu_cont_stylebox, 5)
	_menu_cont_stylebox
	var _panel_cont: PanelContainer = PanelContainer.new()
	_panel_cont.custom_minimum_size = Vector2(10, 500)
	_panel_cont.add_theme_stylebox_override("panel", _menu_cont_stylebox)

	self._close_button = self.setup_ui_button(self._close_button, self._close_icon, 0, self._on_close_pressed, "Close panel")
	self._maximize_button = self.setup_ui_button(self._maximize_button, self._maximize_icon, 1, self._on_close_pressed, "Maximize panel")
	self._move_button = self.setup_ui_button(self._move_button, self._move_icon, 2, self._on_close_pressed, "Move panel")
	_hbox.add_child(self._move_button)
	_hbox.add_child(self._maximize_button)
	_hbox.add_child(self._close_button)

	_vbox.add_child(_hbox)
	_vbox.add_child(_panel_cont)
	self.add_child(_vbox)

 
	var _menu_vbox: VBoxContainer = VBoxContainer.new()
	var filter_prop_line_edit: LineEdit = LineEdit.new()
	filter_prop_line_edit.placeholder_text = "Filter Properties"
	_menu_vbox.add_child(filter_prop_line_edit)

	var _menu_tab_cont: PanelContainer = PanelContainer.new()
	_menu_tab_cont.custom_minimum_size = Vector2(100, 100)

	self._menu_cont_stylebox.bg_color = Guidot_Utils.get_guidot_base_color()
	self.set_margin_size(self._menu_cont_stylebox, 3)
	_menu_tab_cont.add_theme_stylebox_override("panel", self._menu_cont_stylebox)
	_menu_vbox.add_child(_menu_tab_cont)

	_panel_cont.add_child(_menu_vbox)

func setup_ui_button(ui_button: Button, icon: Texture2D, n_col: int, button_cb: Callable, tooltip: String = ""):
	ui_button.size = Vector2(20, 20)
	var resized_icon: Texture2D = self.resize_button_icon(icon)

	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	ui_button.add_theme_stylebox_override("normal", empty_stylebox)
	ui_button.add_theme_stylebox_override("hover", empty_stylebox)
	ui_button.add_theme_stylebox_override("focus", empty_stylebox)
	ui_button.set_button_icon(resized_icon)
	ui_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
	ui_button.tooltip_text = tooltip
	ui_button.position = Vector2(self.size.x - n_col * ui_button.size.x, ui_button.size.y)
	ui_button.pressed.connect(button_cb)
	return ui_button

func resize_button_icon(button_icon: Texture2D) -> Texture2D:
	var resized_img: Image = button_icon.get_image()
	resized_img.resize(20, 20)
	var resized_icon = ImageTexture.create_from_image(resized_img)
	return resized_icon

func _on_mouse_entered() -> void:
	self._mouse_in = true

func _on_mouse_exited() -> void:
	self._mouse_in = false

func _on_parent_focused() -> void:
	self._is_in_focus = true
	self.log(LOG_INFO, ["On parent focused", self._is_in_focus])

func set_stylebox_color(stylebox: StyleBoxFlat, color: Color) -> void:
	stylebox.border_color = color

func set_graph_opacity(alpha: float) -> void:
	var a: float = clamp(alpha, 0.0, 1.0)
	self.set_self_modulate(Color(1.0, 1.0, 1.0, a))	

func set_margin_size(stylebox: StyleBoxFlat, val: int) -> void:
	stylebox.content_margin_left = val
	stylebox.content_margin_right = val
	stylebox.content_margin_bottom = val
	stylebox.content_margin_top = val

func set_panel_size(new_size: Vector2) -> void:
	pass

func _is_point_near(from: Vector2, target: Vector2, margin: int) -> bool:
	return from.distance_to(target) <= margin

func _get_hovered_resize_corner(hover_margin: int) -> Resize_Corner:
	var curr_local_mouse_pos: Vector2 = self.get_local_mouse_position()
	var curr_resize_corner: Resize_Corner

	if (self._is_holding_left_click and self._curr_edit_mode == Edit_Mode.RESIZE):
		# If we are currently resizing that corner, then let the user finish the resizing process first
		# before we allow them to perform it for other corners
		self._last_active_resize_corner = self._active_resize_corner
		curr_resize_corner = _last_active_resize_corner
	else:
		if (self._is_point_near(curr_local_mouse_pos, self.top_left(), hover_margin)):
			curr_resize_corner =  Resize_Corner.TOP_LEFT
		elif (self._is_point_near(curr_local_mouse_pos, self.top_right(), hover_margin)):
			curr_resize_corner =  Resize_Corner.TOP_RIGHT
		elif (self._is_point_near(curr_local_mouse_pos, self.bottom_left(), hover_margin)):
			curr_resize_corner =  Resize_Corner.BOTTOM_LEFT
		elif (self._is_point_near(curr_local_mouse_pos, self.bottom_right(), hover_margin)):
			curr_resize_corner =  Resize_Corner.BOTTOM_RIGHT
		else:
			curr_resize_corner = Resize_Corner.NONE
	# Return this only if we cant detect the mouse hovering on top of any of those points
	return curr_resize_corner

func _draw_resizing_hover_circle(circle_size: int) -> void:
	var circle_pos_to_draw: Vector2 = Vector2()
	match (self._active_resize_corner):
		Resize_Corner.NONE:
			pass

		Resize_Corner.TOP_LEFT:
			circle_pos_to_draw = self.top_left()

		Resize_Corner.TOP_RIGHT:
			circle_pos_to_draw = self.top_right()

		Resize_Corner.BOTTOM_LEFT:
			circle_pos_to_draw = self.bottom_left()

		Resize_Corner.BOTTOM_RIGHT:
			circle_pos_to_draw = self.bottom_right()

	if (self._active_resize_corner != Resize_Corner.NONE):
		self.draw_circle(circle_pos_to_draw, circle_size, Color.RED, false)
	else:
		pass

func _draw() -> void:
	var resizing_circle_size: int  = 4
	var resizing_hover_circle_size: int = 10
		
	# Draw 4 circle points for user reference where to resize
	self.draw_circle(self.top_left(), resizing_circle_size, Color.RED)
	self.draw_circle(self.top_right(), resizing_circle_size, Color.RED)
	self.draw_circle(self.bottom_left(), resizing_circle_size, Color.RED)
	self.draw_circle(self.bottom_right(), resizing_circle_size, Color.RED)

	# Show active corner the user is hovering above to enable resizing
	self._draw_resizing_hover_circle(resizing_hover_circle_size)

func _process(delta: float) -> void:

	if (self._mouse_in):
		self.set_stylebox_color(self._guidot_stylebox, Guidot_Utils.get_color("red"))
		self._active_resize_corner = self._get_hovered_resize_corner(10)
	else:
		self.set_stylebox_color(self._guidot_stylebox, Guidot_Utils.get_color("gd_black"))

	# TODO: Remove, this is temporary to always trigger a redraw
	self.queue_redraw()

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, "MASTER_PANEL", msg)
