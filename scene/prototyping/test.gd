extends Panel

@onready var _guidot_stylebox: StyleBoxFlat = StyleBoxFlat.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = true
	self.add_theme_stylebox_override("normal", self._guidot_stylebox)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.visible = true
