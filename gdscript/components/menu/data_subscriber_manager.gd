class_name Guidot_Data_Sub_Manager
extends Guidot_Panel2

signal data_selected

@onready var available_data: Dictionary = {
}

@onready var header: Label = Label.new()
@onready var apply_button: Button = Button.new()
@onready var search_bar: LineEdit = LineEdit.new()
@onready var scroll_container: ScrollContainer = ScrollContainer.new()
@onready var data_list_vbox: VBoxContainer = VBoxContainer.new()
@onready var close_button: Button = Button.new()

func set_available_data(client_nodes: Array[int]) -> void:
	self.available_data.clear()

	for node in client_nodes:
		available_data[instance_from_id(node).name] = false

	self.populate_data_selection_vbox()

func populate_data_selection_vbox() -> void:
	for key in available_data.keys():
		data_list_vbox.add_child(Guidot_Utils._create_checkbox_with_label(key, available_data[key]))

func _on_close_submenu_button_pressed() -> void:
	self.visible = false

func _on_apply_changes_pressed(selected_data: VBoxContainer) -> void:
	var selected_data_str: Array[String] = []
	for hbox in selected_data.get_children():
		var cbox: CheckBox = hbox.get_child(0)

		if cbox.button_pressed:
			selected_data_str.append(cbox.text)

	self.data_selected.emit(selected_data_str)
	self.log(LOG_INFO, [selected_data_str])

func set_container_size(new_size: Vector2) -> void:
	self.scroll_container.custom_minimum_size = new_size

func _ready() -> void:
	super._ready()

	self.visible = true
	self.hide_panel()

	self.custom_minimum_size = Vector2(300, 300)
	self.set_outline_color(Guidot_Utils.get_color("white"))

	var l_vbox1: VBoxContainer = VBoxContainer.new()
	self.add_child_to_container(l_vbox1)
	self.set_container_color(Guidot_Utils.get_color("gd_black"))

	# Header for data subscriber
	var l_hbox1: HBoxContainer = HBoxContainer.new()
	l_hbox1.add_child(header)	
	l_hbox1.add_child(close_button)

	var child_array: Array[Node] = [l_hbox1, apply_button, search_bar, scroll_container]

	for node in child_array:
		l_vbox1.add_child(node)

	# Setup the header
	# l_hbox1.custom_minimum_size = Vector2(self._data_subscriber_manager.size.x, 20)
	# l_hbox1.size = Vector2(self._data_subscriber_manager.size.x, 20)
	header.text = "Data Subscriber Manager"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_button.custom_minimum_size = Vector2(30, 20)
	close_button.text = "X"
	close_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
	close_button.pressed.connect(self._on_close_submenu_button_pressed)
	scroll_container.custom_minimum_size = Vector2(self.size.x, 300)

	scroll_container.add_child(data_list_vbox)

	for key in available_data.keys():
		data_list_vbox.add_child(Guidot_Utils._create_checkbox_with_label(key, available_data[key]))

	apply_button.text = "Apply changes"
	apply_button.pressed.connect(self._on_apply_changes_pressed.bind(data_list_vbox))

func _process(delta: float) -> void:
	# self.position = Vector2(500, 500)
	pass
