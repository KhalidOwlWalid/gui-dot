class_name Guidot_Data_Sub_Manager
extends Guidot_Panel2

func _on_close_submenu_button_pressed() -> void:
	self.visible = false

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
	var header: Label = Label.new()
	var l_close_btn1: Button = Button.new()
	l_hbox1.add_child(header)	
	l_hbox1.add_child(l_close_btn1)

	var apply_button: Button = Button.new()
	var search_bar: LineEdit = LineEdit.new()
	var l_scr_cont: ScrollContainer = ScrollContainer.new()
	var data_list_vbox: VBoxContainer = VBoxContainer.new()

	var child_array: Array[Node] = [l_hbox1, apply_button, search_bar, l_scr_cont]

	for node in child_array:
		l_vbox1.add_child(node)

	# Setup the header
	# l_hbox1.custom_minimum_size = Vector2(self._data_subscriber_manager.size.x, 20)
	# l_hbox1.size = Vector2(self._data_subscriber_manager.size.x, 20)
	header.text = "Data Subscriber Manager"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_close_btn1.custom_minimum_size = Vector2(30, 20)
	l_close_btn1.text = "X"
	l_close_btn1.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
	l_close_btn1.pressed.connect(self._on_close_submenu_button_pressed)
	l_scr_cont.custom_minimum_size = Vector2(self.size.x, 100)

	# l_scr_cont.add_child(data_list_vbox)
	# data_list_vbox.add_child(self._create_checkbox_with_label("Engine Speed"))
	# data_list_vbox.add_child(self._create_checkbox_with_label("Fd Commands"))
	# data_list_vbox.add_child(self._create_checkbox_with_label("Roll"))
	# data_list_vbox.add_child(self._create_checkbox_with_label("Pitch"))
	# data_list_vbox.add_child(self._create_checkbox_with_label("Yaw"))

	apply_button.text = "Apply changes"
	# apply_button.pressed.connect(self._on_apply_changes_pressed.bind(data_list_vbox))

func _process(delta: float) -> void:
	# self.position = Vector2(500, 500)
	pass
