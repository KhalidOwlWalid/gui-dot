class_name Guidot_Error_Popup
extends Guidot_Movable_Panel

@onready var _popup_vbox: VBoxContainer = VBoxContainer.new()

func _ready() -> void:
	super._ready()
	self.name = "Guidot_Error_Popup"
	self.set_title_name(self.name)
	self.set_panel_size(Vector2(500, 160))
	self.add_child_into_panel_space(self._popup_vbox)

# When OK is pressed, then clear the error popup panel space, and close the popup
func _on_ok_pressed() -> void:
	for child_node in self._popup_vbox.get_children():
		child_node.queue_free()

	self.hide_popup()

func _create_error_text_line(text: String, center_text: bool = true) -> Label:
	var label1: Label = Label.new()

	label1.text = text
	label1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	if center_text:
		label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label1

func generate_popup(gd_error: Guidot_Error) -> void:
	var error_info: String = gd_error.error_info
	var error_msg: String = gd_error.message
	var error_src_full: String = gd_error.source_full

	for child_node in self._popup_vbox.get_children():
		child_node.queue_free()

	var error_type_label: Label = self._create_error_text_line(error_info, true)
	var error_msg_label: Label = self._create_error_text_line(error_msg, true)
	var error_src_label: Label = self._create_error_text_line(error_src_full, true)

	var ok_button: Button = Button.new()
	ok_button.text = "Ok, my bad!"
	ok_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_button.pressed.connect(self._on_ok_pressed)

	self._popup_vbox.add_child(error_type_label)
	self._popup_vbox.add_child(error_msg_label)
	self._popup_vbox.add_child(error_src_label)
	self._popup_vbox.add_child(ok_button)

	self.queue_redraw()

func hide_popup() -> void:
	self.visible = false

func show_popup() -> void:
	self.visible = true

func _draw() -> void:
	pass
