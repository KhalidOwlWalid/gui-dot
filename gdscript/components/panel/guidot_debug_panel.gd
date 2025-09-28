@tool
class_name Guidot_Debug_Panel
extends Guidot_Panel

@onready var _debugging_text_window: PanelContainer = PanelContainer.new()
@onready var _test_ver_box: VBoxContainer = VBoxContainer.new()
@onready var _test_hor_box: HBoxContainer = HBoxContainer.new()

@onready var inc: int = 0
@onready var _hor_box_prefix: String = "GuidotDebugHorCont"

@onready var _guidot_debug_info = {
	"Type of information": "Realtime",
	"Number of data processed": str(inc),
	"Number of data pre-processed": str(100.12),
}

func _create_debug_info_row(text_label_row: int, debug_info_type: String, debug_info_val: String) -> HBoxContainer:

	var hbox_cont: HBoxContainer = HBoxContainer.new()
	var left = self._setup_text_label(text_label_row, debug_info_type, true)
	var right = self._setup_text_label(text_label_row, debug_info_val)

	# TODO (Khalid): Make this more dynamic
	hbox_cont.custom_minimum_size = Vector2(280, 30)
	# Simplifies indexing to be able to find the right child node for updating the data in real-time
	hbox_cont.name = self._hor_box_prefix + "_" + str(text_label_row)
	hbox_cont.add_child(left)
	hbox_cont.add_child(right)

	return hbox_cont

func _setup_text_label(text_label_row: int, text_display: String, is_type: bool = false) -> RichTextLabel:
	var rich_text_label: RichTextLabel = RichTextLabel.new()
	rich_text_label.bbcode_enabled = true
	rich_text_label.fit_content = true
	rich_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	rich_text_label.add_theme_font_size_override("normal_font_size", self._font_size)
	rich_text_label.add_theme_font_size_override("bold_font_size", self._font_size)

	if is_type:
		rich_text_label.name = "Type_" + str(text_label_row)
		text_display = "[b]" + text_display + "[/b]"
	else:
		rich_text_label.name = "Val_" + str(text_label_row)

	rich_text_label.text = text_display
	return rich_text_label	

func _update_text_label(debug_info_key: String):
	pass

func _ready() -> void:
	self._panel_size = Vector2(300, 100)

	self.name = "Guidot_Debug_Panel"
	self.visible = true
	self.size = _panel_size
	self.position = self._init_pos
	self.margin_val = 3
	self._font_size = 10

	_guidot_panel_stylebox.bg_color = color_dict["gd_grey"]
	set_margin_size(self.margin_val)
	add_theme_stylebox_override("panel", self._guidot_panel_stylebox)

	var _guidot_debugging_text_window: StyleBoxFlat = StyleBoxFlat.new()
	_guidot_debugging_text_window.bg_color = color_dict["gd_grey_transparent"]
	_debugging_text_window.add_theme_stylebox_override("panel", _guidot_debugging_text_window)
	self.add_child(self._debugging_text_window)

	_debugging_text_window.add_child(_test_ver_box)

	# This helps indexing each horizontal label container which benefits us in trying to find the correct node for updating
	# necessary values in real-time
	var curr_row: int = 0
	for debug_info_type in self._guidot_debug_info:
		var hbox_cont: HBoxContainer = self._create_debug_info_row(curr_row, debug_info_type, self._guidot_debug_info[debug_info_type])
		_test_ver_box.add_child(hbox_cont)
		curr_row += 1

func _process(delta: float) -> void:
	inc += 1

	var curr_hor_box = _test_ver_box.get_child(1)
	var val_text_label  = curr_hor_box.get_child(1)
	val_text_label.text = str(inc)
