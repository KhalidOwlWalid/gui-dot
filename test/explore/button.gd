extends Button

@export var icon_texture: Texture2D
@export var icon_size: Vector2 = Vector2(30, 30)
@onready var _setting_icon: Texture2D = load("res://addons/guidot/icons/gear_icon.png")

func _ready() -> void:
	var resized_image = self._setting_icon.get_image()
	resized_image.resize(int(icon_size.x), int(icon_size.y))
	set_button_icon(ImageTexture.create_from_image(resized_image))
	
	size = icon_size
	# flat = true
	
	var empty = StyleBoxEmpty.new()
	for state in ["normal", "disabled"]:
		add_theme_stylebox_override(state, empty)
	
	set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT)

func _process(delta: float) -> void:
	pass
