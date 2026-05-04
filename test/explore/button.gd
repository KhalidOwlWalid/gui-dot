extends Button

var expanded := false

func _ready() -> void:
	pressed.connect(_toggle)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	get_parent().get_node("hotkeys").visible = false

func _toggle() -> void:
	expanded = !expanded
	get_parent().get_node("hotkeys").visible = expanded
	
	if (expanded):
		self.text = "⇓ Preferences"
	else:
		self.text = "⇒ Preferences"
