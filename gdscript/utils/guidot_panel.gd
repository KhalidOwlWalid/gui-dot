class_name Guidot_Panel
extends PanelContainer

@onready var _panel_size: Vector2 = Vector2(100, 100)

func _ready() -> void:
	self.name = "Test"
	self.visible = false
	self.size = _panel_size

func show_panel(pos: Vector2) -> void:
	self.position = pos
	self.visible = true

func _process(delta: float) -> void:
	pass
