class_name Guidot_Axis_Limit_Config
extends PopupPanel

signal limits_applied(min_val: float, max_val: float)

var _min_input: LineEdit
var _max_input: LineEdit

func show_for_axis(axis_min: float, axis_max: float, pos: Vector2) -> void:
	_min_input.text = "%0.4f" % axis_min
	_max_input.text = "%0.4f" % axis_max
	self.popup(Rect2i(Vector2i(pos), Vector2i(220, 130)))
	_min_input.grab_focus()

func _on_apply_pressed() -> void:
	var new_min: float = _min_input.text.to_float()
	var new_max: float = _max_input.text.to_float()
	# Equal values are rejected because a zero-span axis causes division by zero
	# when computing tick intervals.  min > max is intentionally allowed so the
	# user can flip the axis (i.e. render the plot upside-down).
	if new_min == new_max:
		return
	limits_applied.emit(new_min, new_max)
	self.hide()

func _ready() -> void:
	_min_input = LineEdit.new()
	_max_input = LineEdit.new()

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Min row
	var min_hbox: HBoxContainer = HBoxContainer.new()
	var min_label: Label = Label.new()
	min_label.text = "Min:"
	min_label.custom_minimum_size = Vector2(40, 0)
	min_hbox.add_child(min_label)
	_min_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_min_input.text_submitted.connect(func(_s): _on_apply_pressed())
	min_hbox.add_child(_min_input)
	vbox.add_child(min_hbox)

	# Max row
	var max_hbox: HBoxContainer = HBoxContainer.new()
	var max_label: Label = Label.new()
	max_label.text = "Max:"
	max_label.custom_minimum_size = Vector2(40, 0)
	max_hbox.add_child(max_label)
	_max_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_max_input.text_submitted.connect(func(_s): _on_apply_pressed())
	max_hbox.add_child(_max_input)
	vbox.add_child(max_hbox)

	# Apply button
	var apply_btn: Button = Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(_on_apply_pressed)
	vbox.add_child(apply_btn)
