class_name Guidot_Panel
extends PanelContainer

@onready var _panel_size: Vector2 = Vector2(100, 100)
@onready var _init_pos: Vector2 = Vector2(100, 100)

@onready var _last_pos: Vector2 = Vector2()

func _ready() -> void:
	self.name = "Test"
	self.visible = false
	self.size = _panel_size
	self.position = self._init_pos

func show_panel() -> void:
	self.visible = true

func hide_panel() -> void:
	self._last_pos = self.position
	self.visible = false

func _process(delta: float) -> void:
	pass
