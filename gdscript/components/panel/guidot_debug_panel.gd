@tool
class_name Guidot_Debug_Panel
extends Guidot_Panel

@onready var _debugging_text_window: PanelContainer = PanelContainer.new()
@onready var _test_ver_box: VBoxContainer = VBoxContainer.new()
@onready var _test_hor_box: HBoxContainer = HBoxContainer.new()

@onready var _guidot_debug_info = {
	"Type of information": "Some data",
}

func _create_debug_info_row(debug_info_type: RichTextLabel, debug_info_val: RichTextLabel) -> HBoxContainer:
	var hbox_cont: HBoxContainer = HBoxContainer.new()
	# TODO (Khalid): Make this more dynamic
	hbox_cont.custom_minimum_size = Vector2(280, 30)
	# hbox_cont.add_child(debug_info_type)
	# hbox_cont.add_child(debug_info_val)
	return hbox_cont

func _setup_text_label(label_tag: String, text_display: String) -> RichTextLabel:
	var rich_text_label: RichTextLabel = RichTextLabel.new()
	rich_text_label.name = label_tag
	rich_text_label.bbcode_enabled = true
	rich_text_label.fit_content = true
	rich_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich_text_label.add_theme_font_size_override("normal_font_size", self._font_size)
	rich_text_label.add_theme_font_size_override("bold_font_size", self._font_size)
	rich_text_label.text = text_display
	return rich_text_label	

func _ready() -> void:
	self._panel_size = Vector2(300, 100)

	self.name = "Guidot_Debug_Panel"
	self.visible = true
	self.size = _panel_size
	self.position = self._init_pos
	self.margin_val = 10
	self._font_size = 12

	_guidot_panel_stylebox.bg_color = color_dict["gd_black"]
	set_margin_size(self.margin_val)
	add_theme_stylebox_override("panel", self._guidot_panel_stylebox)

	var _guidot_debugging_text_window: StyleBoxFlat = StyleBoxFlat.new()
	_guidot_debugging_text_window.bg_color = color_dict["gd_black"]
	_debugging_text_window.add_theme_stylebox_override("panel", _guidot_debugging_text_window)
	self.add_child(self._debugging_text_window)

	_debugging_text_window.add_child(_test_ver_box)

	for i in range(10):
		var text1 = self._setup_text_label("1", "[b]Data Fetch Mode: [b]")
		var text2 = self._setup_text_label("2", "[color=green]Realtime[/color]")
		var hbox_cont: HBoxContainer = self._create_debug_info_row(text1, text2)
		hbox_cont.add_child(text1)
		hbox_cont.add_child(text2)
		_test_ver_box.add_child(hbox_cont)
