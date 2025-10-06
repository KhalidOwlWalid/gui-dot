# @tool
class_name Guidot_Debug_Panel
extends Guidot_Panel

@onready var _debugging_text_window: PanelContainer = PanelContainer.new()
@onready var _debug_panel_vbox_cont: VBoxContainer = VBoxContainer.new()
@onready var _test_hor_box: HBoxContainer = HBoxContainer.new()

@onready var inc: int = 0
@onready var _hor_box_prefix: String = "GuidotDebugHorCont"

signal new_data_received

@onready var _guidot_debug_info = {
}

func attach_data_to_debug_panel(debug_type: String, debug_val: String) -> void:
	self._guidot_debug_info[debug_type] = debug_val

func override_guidot_debug_info(new_dict: Dictionary) -> void:
	self._guidot_debug_info = new_dict

	if (_guidot_debug_info.size() != 0):
		
		if (_debug_panel_vbox_cont.get_child_count() != null):
			var child_array: Array[Node] = _debug_panel_vbox_cont.get_children()
			print(child_array)
			for curr_child in child_array:
				self.log(LOG_DEBUG, ["Removing node:", curr_child])
				_debug_panel_vbox_cont.remove_child(curr_child)
		else:
			pass

		var i: int = 0
		for debug_type in self._guidot_debug_info:
			var hbox_cont: HBoxContainer = self._create_debug_info_row(i, debug_type, str(self._guidot_debug_info[debug_type]))
			_debug_panel_vbox_cont.add_child(hbox_cont)

func update_data_on_debug_panel(key: String, value: String) -> void:
	pass

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
	self.visible = false
	self.size = _panel_size
	self.position = self._init_pos
	self.margin_val = 3
	self._font_size = 10
	self._component_tag = "DEBUG_PANEL"
	self.top_level = true

	_guidot_panel_stylebox.bg_color = color_dict["gd_grey"]
	set_margin_size(self.margin_val)
	add_theme_stylebox_override("panel", self._guidot_panel_stylebox)

	var _guidot_debugging_text_window: StyleBoxFlat = StyleBoxFlat.new()
	_guidot_debugging_text_window.bg_color = color_dict["gd_grey_transparent"]
	_debugging_text_window.add_theme_stylebox_override("panel", _guidot_debugging_text_window)
	self.add_child(self._debugging_text_window)

	_debugging_text_window.add_child(_debug_panel_vbox_cont)

	# This helps indexing each horizontal label container which benefits us in trying to find the correct node for updating
	# necessary values in real-time
	var curr_row: int = 0
	var hbox_cont: HBoxContainer = HBoxContainer.new()
	if (self._guidot_debug_info.size() == 0):
		self.log(LOG_INFO, ["Guidot Debug Info is currently empty"])
		# Just add the empty HBox Container
		# _debug_panel_vbox_cont.add_child(hbox_cont)
	else:
		for debug_info_type in self._guidot_debug_info:
			hbox_cont = self._create_debug_info_row(curr_row, debug_info_type, str(self._guidot_debug_info[debug_info_type]))
			_debug_panel_vbox_cont.add_child(hbox_cont)
			curr_row += 1

func _process(delta: float) -> void:
	self.log(LOG_DEBUG, [self._guidot_debug_info])

	var hbox_array: Array[Node] = self._debug_panel_vbox_cont.get_children()

	# TODO (Khalid): Make sure we do a lot of checks to ensure we are updating the correct key with its respective value
	if (hbox_array.size() == self._guidot_debug_info.size()):
		for i in range(self._guidot_debug_info.size()):
			var key: String = self._guidot_debug_info.keys()[i]
			var updated_val: String = str(self._guidot_debug_info[key])
			var val_text_label: RichTextLabel = hbox_array[i].get_child(1)
			val_text_label.text = updated_val
	else:
		# As of now, the implementation actually relies on the HBoxContainer and the debug info to match in terms of its size
		# I simply use index to be able to update the value accordingly. Obviously, this implementation is not the best and may
		# introduce bug in the future, but I am happy with this implementation for now
		self.log(LOG_WARNING, ["The size of the HBoxContainer and the Debug Info dictionary does not match. Aborting update for the debug panel."])
		self.log(LOG_WARNING, ["HBoxContainer Size:", hbox_array.size(), " | Debug Info Dictionary Size: ", self._guidot_debug_info.size()])
