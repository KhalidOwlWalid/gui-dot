# @tool
extends Control

var debugging_panel: Panel = Panel.new()
var _mouse_in: bool
var _dragging_distance: float
var _dir: Vector2
@onready var _is_dragging: bool = false
@onready var _new_position: Vector2 = Vector2()

func _ready() -> void:
	debugging_panel.set_position(Vector2(100, 100))
	debugging_panel.set_size(Vector2(100, 100))
	debugging_panel.visible = false
	self.add_child(debugging_panel)

	self.focus_entered.connect(self._on_focus_entered)
	debugging_panel.mouse_entered.connect(_on_mouse_entered)
	debugging_panel.mouse_exited.connect(_on_mouse_exited)

func _on_focus_entered() -> void:
	print("Focus entered")

func _on_mouse_entered() -> void:
	_mouse_in = true
	print("Mouse entered")

func _on_mouse_exited() -> void:
	_mouse_in = false
	print("Mouse exited")

func _input(event: InputEvent) -> void:
	if (event is InputEventKey):
		if event.keycode == KEY_SPACE:
			debugging_panel.visible = true
			print("Visible now")

	if (event is InputEventMouseButton):
		
		if (event.is_pressed() and _mouse_in):
			_dragging_distance = self.position.distance_to(self.get_viewport().get_mouse_position())
			_dir = (self.get_viewport().get_mouse_position() - self.position).normalized()
			_is_dragging = true
			_new_position = self.get_viewport().get_mouse_position() - self._dragging_distance * _dir

		else:
			_is_dragging = false

	elif (event is InputEventMouseMotion):
		if _is_dragging:
			_new_position = self.get_viewport().get_mouse_position() - self._dragging_distance * _dir

func _process(delta: float) -> void:
	if _is_dragging:
		print("Dragging")
		self.position = _new_position
