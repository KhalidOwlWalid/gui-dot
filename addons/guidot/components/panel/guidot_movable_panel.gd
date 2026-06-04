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

@onready var _master_vbox: VBoxContainer = VBoxContainer.new()
@onready var _header_hbox: HBoxContainer = HBoxContainer.new()
@onready var _title_label: Label = Label.new()
@onready var _panel_space: PanelContainer = PanelContainer.new()

class Guidot_Button:

	var _button: Button
	var _shortcuts: Shortcut
	var _default_icon: Texture2D
	
	# TODO: Dictionary of different icons when different action is done
	var _icons: Dictionary

	func init_button(parent: Node, default_icon: Texture2D, size: Vector2, callback_fcn: Callable, tooltip: String):
		self._button = Button.new()
		self._setup_ui_button(default_icon, size, callback_fcn, tooltip) 
		self._attach_to_parent(parent)

	func resize_button_icon(button_icon: Texture2D) -> Texture2D:
		var resized_img: Image = button_icon.get_image()
		resized_img.resize(20, 20)
		var resized_icon = ImageTexture.create_from_image(resized_img)
		return resized_icon

	func _setup_ui_button(icon: Texture2D, size: Vector2, button_cb: Callable, tooltip: String = ""):
		self._button.size = size

		# Remove all of Godot's default settings for a button, customizing it to what I feel is best
		var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
		var theme_to_override: Array[String] = ["normal", "hover", "focus"]
		for theme in theme_to_override:
			self._button.add_theme_stylebox_override(theme, empty_stylebox)

		var resized_icon: Texture2D = self.resize_button_icon(icon)
		self._button.set_button_icon(resized_icon)

		self._button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)
		self._button.tooltip_text = tooltip
		self._button.pressed.connect(button_cb)

	func _attach_to_parent(parent: Node):
		parent.add_child(self._button)

@onready var _close_button: Guidot_Button = Guidot_Button.new()
const _close_icon: Texture2D = preload("res://addons/guidot/icons/close_icon.png")

func _on_close_pressed():
	self.hide()

@onready var _maximize_button: Guidot_Button = Guidot_Button.new()
const _maximize_icon: Texture2D = preload("res://addons/guidot/icons/maximize_icon.png")

func _on_max_pressed():
	pass

@onready var _move_button: Guidot_Button = Guidot_Button.new()
const _move_icon: Texture2D = preload("res://addons/guidot/icons/move_icon.png")

func _on_move_pressed() -> void:
	self._curr_ui_mode = UI_Mode.SELECTED
	self.queue_redraw()

func add_child_into_panel_space(child: Node) -> void:
	self._panel_space.add_child(child)

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

func set_title_name(new_title: String) -> void:
	self._title_label.text = new_title

# Useful for if the nodes that inherit this wishes to disable its header for any reason
func disable_header() -> void:
	self._master_vbox.remove_child(self._header_hbox)

func _ready() -> void:
	self.name = "Guidot_Movable_Panel"
	self.size = self._panel_default_size
	self.z_index = 1
	self.custom_minimum_size = Vector2(200, 200)

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

	_title_label.text = self.name
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.custom_minimum_size = Vector2(120, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_hbox.add_child(_title_label)

	var menu_cont_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	menu_cont_stylebox.bg_color = Guidot_Utils.get_color("menu_panel_cont")
	menu_cont_stylebox.border_color = menu_cont_stylebox.bg_color
	var menu_border_width: int = 2
	menu_cont_stylebox.border_width_left   = menu_border_width
	menu_cont_stylebox.border_width_right  = menu_border_width
	menu_cont_stylebox.border_width_top    = menu_border_width
	menu_cont_stylebox.border_width_bottom = menu_border_width
	self.set_margin_size(menu_cont_stylebox, 5)
	menu_cont_stylebox
	_panel_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_space.add_theme_stylebox_override("panel", menu_cont_stylebox)

	var button_size: Vector2 = Vector2(20, 20)
	self._move_button.init_button(self._header_hbox, self._move_icon, button_size, self._on_move_pressed, "Move panel")
	self._maximize_button.init_button(self._header_hbox, self._maximize_icon, button_size, self._on_max_pressed, "Maximize panel")
	self._close_button.init_button(self._header_hbox, self._close_icon, button_size, self._on_close_pressed, "Close panel")

	self._master_vbox.add_child(self._header_hbox)
	self._master_vbox.add_child(self._panel_space)
	self.add_child(_master_vbox) 

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
		
	if (self._curr_ui_mode == UI_Mode.SELECTED):
		# Draw 4 circle points for user reference where to resize
		self.draw_circle(self.top_left(), resizing_circle_size, Color.RED)
		self.draw_circle(self.top_right(), resizing_circle_size, Color.RED)
		self.draw_circle(self.bottom_left(), resizing_circle_size, Color.RED)
		self.draw_circle(self.bottom_right(), resizing_circle_size, Color.RED)

		# Show active corner the user is hovering above to enable resizing
		self._draw_resizing_hover_circle(resizing_hover_circle_size)

func _process(delta: float) -> void:

	match (self._curr_ui_mode):

		UI_Mode.SELECTED:
			self.set_stylebox_color(self._guidot_stylebox, Guidot_Utils.get_color("red"))

func _input(event: InputEvent) -> void:

	if (event is InputEventKey and event.pressed):
		
		if (event.keycode == KEY_ESCAPE):
			self._curr_ui_mode = UI_Mode.NORMAL
			self.queue_redraw()

		if (event.keycode == KEY_M and event.ctrl_pressed):
			self._on_move_pressed()

	match (self._curr_ui_mode):
		
		UI_Mode.SELECTED:
			self._active_resize_corner = self._get_hovered_resize_corner(10)

			# Possible resizing when user is hovering above the resizing corners but have yet click the left button
			if (self._active_resize_corner != Resize_Corner.NONE and not self._is_holding_left_click):
				self._last_edit_mode = self._curr_edit_mode
				self._curr_edit_mode = Edit_Mode.POSSIBLE_RESIZING
			# User is currently holding the left click to resize the graph display
			elif (self._active_resize_corner != Resize_Corner.NONE and self._is_holding_left_click):
				self._last_edit_mode = self._curr_edit_mode
				self._curr_edit_mode = Edit_Mode.RESIZE
			elif (self._last_edit_mode == Edit_Mode.RESIZE and self._is_holding_left_click):
				self._curr_edit_mode = Edit_Mode.RESIZE
			else:
				self._last_edit_mode = self._curr_edit_mode
				self._curr_edit_mode = Edit_Mode.NONE
			self.queue_redraw()

			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:	
					# Allow the user to be able to start resizing the graph
					if event.is_pressed() and self._active_resize_corner != Resize_Corner.NONE and self._curr_edit_mode == Edit_Mode.POSSIBLE_RESIZING:
						self.log(LOG_DEBUG, ["Graph panel ready to be resize"])
						self._last_edit_mode = self._curr_edit_mode
						self._is_holding_left_click = true
					# Go back to possible resizing if the user releases the left mouse
					elif not event.is_pressed() \
						and (self._last_edit_mode == Edit_Mode.POSSIBLE_RESIZING and self._curr_edit_mode == Edit_Mode.RESIZE):
						self._last_edit_mode = self._curr_edit_mode
						self._is_holding_left_click = false
						self.log(LOG_DEBUG, ["Left click resizing released"])
					elif event.is_pressed() and self._mouse_in:
						_is_dragging = true
						self._curr_edit_mode = Edit_Mode.MOVE
						_drag_offset = get_global_mouse_position() - self.global_position
						self._last_position = self.position
						get_viewport().set_input_as_handled()
					else:
						_is_dragging = false

					if event.is_pressed():
						self.log(LOG_DEBUG, ["I am pressing my left button"])
						self._is_holding_left_click = true
					else:
						self.log(LOG_DEBUG, ["I am releasing my left button"])
						self._is_holding_left_click = false

			if event is InputEventMouseMotion:

				var curr_mouse_pos_global: Vector2 = get_global_mouse_position()
				var curr_mouse_pos_local: Vector2 = get_local_mouse_position()
				var new_size: Vector2
				var new_pos: Vector2
				var mouse_offset: Vector2
				# Only allow the user to drag when the mouse is inside the panel
				if (self._curr_edit_mode == Edit_Mode.RESIZE and self._is_holding_left_click):

					self._last_position = self.global_position
					var old_size: Vector2 = self.size
		
					match (self._active_resize_corner):
						Resize_Corner.TOP_LEFT:
							new_pos = self._last_position + curr_mouse_pos_local
							new_size = self.size - curr_mouse_pos_local
						Resize_Corner.TOP_RIGHT:
							mouse_offset = Vector2(curr_mouse_pos_local.x - self.size.x, curr_mouse_pos_local.y)
							new_pos = Vector2(self._last_position.x, self._last_position.y + mouse_offset.y)
							
							# This helps handle the negative offset when the user is trying to scale down the graph with the top right corner
							if (mouse_offset.y < 0):
								new_size = Vector2(self.size.x + mouse_offset.x, self.size.y + abs(mouse_offset.y))
							else:
								new_size = Vector2(self.size.x + mouse_offset.x, self.size.y - abs(mouse_offset.y))

						Resize_Corner.BOTTOM_LEFT:
							mouse_offset = Vector2(curr_mouse_pos_local.x, curr_mouse_pos_local.y - self.size.y)
							new_pos = Vector2(self._last_position.x + mouse_offset.x, self._last_position.y)

							if (mouse_offset.x < 0):
								new_size.x = self.size.x + abs(mouse_offset.x)
							else:
								new_size.x = self.size.x - abs(mouse_offset.x)

							if (mouse_offset.y < 0):
								new_size.y = self.size.y - abs(mouse_offset.y)
							else:
								new_size.y = self.size.y + abs(mouse_offset.y)

						Resize_Corner.BOTTOM_RIGHT:
							mouse_offset = curr_mouse_pos_local - self.size
							new_size = self.size + mouse_offset
							new_pos = self.global_position
						Resize_Corner.NONE:
							new_size = self.size
							new_pos = self.global_position

					self.log(LOG_DEBUG, [self.size, " ", self.custom_minimum_size])
					# Only update position if size actually changed (wasn't constrained)
					self.size = new_size
					if self.size != old_size:
						self.global_position = new_pos
					self._last_mouse_position = curr_mouse_pos_global

				if self._is_dragging:
					self.set_default_cursor_shape(Control.CURSOR_DRAG)
					get_viewport().set_input_as_handled()
					new_pos = curr_mouse_pos_global - _drag_offset
					self.global_position = new_pos
					self._last_mouse_position = curr_mouse_pos_global
					self._last_position = self.position
				else:
					self.set_default_cursor_shape(Control.CURSOR_ARROW)

		_:
			self.set_stylebox_color(self._guidot_stylebox, Guidot_Utils.get_color("gd_black"))

func log(log_level: Guidot_Log.Log_Level, msg: Array) -> void:
	Guidot_Log.gd_log(log_level, "MASTER_PANEL", msg)
