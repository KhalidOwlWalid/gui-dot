class_name Guidot_Time_Series_Graph_Manager
extends Guidot_Panel2

signal changes_applied
signal y_axis_changes_applied
signal opacity_changed(alpha: float)

var selected_server: String

@onready var _graph_config_tab_cont: TabContainer = TabContainer.new()
@onready var _graph_config_window: PanelContainer = PanelContainer.new()
@onready var _config_window_stylebox: StyleBoxFlat = StyleBoxFlat.new()

# Setting tabs
@onready var _server_config_tab: ScrollContainer
@onready var _apply_changes_btn: Button = Button.new()

@onready var _y_axis_config_tab: ScrollContainer
@onready var _apply_y_axis_changes_btn: Button = Button.new()
@onready var _left_axis_count: OptionButton = OptionButton.new()
@onready var _right_axis_count: OptionButton = OptionButton.new()
@onready var _n_axis: Vector2 = Vector2(1, 0)

@onready var _t_axis_config_tab: ScrollContainer


@onready var _server_config_manager: Array[Guidot_Server_Config] = []

# The graph node that the graph manager is responsible for
var _y_axis_manager_ref: Guidot_Time_Series_Canvas.AxisManager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func scaled_row_size(column_scale: float) -> Vector2:
	return Vector2(column_scale * self._graph_config_window.size.x, 20)

# For each configuration tab, it requires:
#	=> VBox - Host all of the configuration row
func create_configuration_tab(tab_name: String) -> ScrollContainer:
	var config_tab: ScrollContainer = ScrollContainer.new()
	config_tab.name = tab_name
	config_tab.custom_minimum_size = Vector2(300, 400)
	var vbox: VBoxContainer = VBoxContainer.new()
	
	config_tab.add_child(vbox)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	return config_tab

# Takes in the configuration tab and helps populate the internal VBoxContainer
func add_config_rows(config_tab: ScrollContainer, config_rows: Array[Node]) -> void:
	var config_tab_vbox: VBoxContainer  = config_tab.get_children()[0]
	
	for row in config_rows:
		config_tab_vbox.add_child(row)

func create_axis_count_row(label_text: String, option_button: OptionButton, current_count: int, is_rhs: bool = false) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 30)
	row.add_theme_constant_override("separation", 8)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_button.custom_minimum_size = Vector2(0, 24)
	option_button.clear()
	var start_idx: int

	if (is_rhs):
		start_idx = 0
	else:
		start_idx = 1

	for i in range(start_idx, 6):
		option_button.add_item(str(i), i)
	var max_index: int = option_button.get_item_count() - 1
	var selected_index: int = clamp(current_count - start_idx, 0, max_index)
	option_button.selected = selected_index

	row.add_child(label)
	row.add_child(option_button)
	return row

func show_panel_at_pos(new_pos: Vector2) -> void:
	self.set_position(new_pos)
	self.visible = true

func _create_server_selection_row() -> void:
	pass

func _on_data_selected(data_str_array: Array[String]) -> void:
	pass

func _on_close_button_submenu_pressed(panel: Node) -> void:
	panel.visible = false

func _on_close_button_pressed() -> void:
	self.visible = false

func _on_add_server_pressed() -> void:
	var gd_server_conf1 = Guidot_Server_Config.new()
	var gd_sub_manager1 = Guidot_Data_Sub_Manager.new()
	gd_server_conf1.register_data_sub_manager(gd_sub_manager1)
	gd_server_conf1.register_y_axis_manager(self._y_axis_manager_ref)
	self.add_child(gd_sub_manager1)
	self.add_config_rows(self._server_config_tab, [gd_server_conf1])
	self._server_config_manager.append(gd_server_conf1)

func _on_apply_changes_to_graph() -> void:
	changes_applied.emit(self._server_config_manager)
	pass

func _on_apply_y_axis_changes() -> void:
	self.y_axis_changes_applied.emit(self._n_axis)

func _on_left_axis_count_selected(index: int) -> void:
	self._n_axis.x = self._left_axis_count.get_item_id(index)

func _on_right_axis_count_selected(index: int) -> void:
	self._n_axis.y = self._right_axis_count.get_item_id(index)

func register_axis_manager(axis_manager: Guidot_Time_Series_Canvas.AxisManager) -> void:
	self._y_axis_manager_ref = axis_manager

func _ready() -> void:

	super._ready()

	var main_vbox: VBoxContainer = VBoxContainer.new()
	self.add_child_to_container(main_vbox)
	self.set_outline_color(Guidot_Utils.get_color("white"))
	self.set_margin_size(1)
	self.set_container_color(Guidot_Utils.get_color("gd_black"))
	self.set_panel_size(Vector2(500, 300))

	var header_hbox: HBoxContainer = HBoxContainer.new()

	# Setup for header label for the graph manager
	var main_header: Label = Label.new()
	main_header.text = "Settings"
	main_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_header.custom_minimum_size = Vector2(self.size.x * 0.9, 10)
	header_hbox.add_child(main_header)

	# Setup the controls button for the graph manager
	var close_button: Button = Button.new()
	close_button.text = "X"
	close_button.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_RIGHT)
	close_button.custom_minimum_size = Vector2(self.size.x * 0.1, 10)
	close_button.add_theme_color_override("font_color", Color.RED)
	close_button.pressed.connect(_on_close_button_pressed)
	header_hbox.add_child(close_button)

	main_vbox.add_child(header_hbox)

	# Graph configuration tab container setup
	main_vbox.add_child(_graph_config_tab_cont)

	# Setup server manager tab
	self._server_config_tab = self.create_configuration_tab("Server Manager")
	_graph_config_tab_cont.add_child(_server_config_tab)

	var graph_buffer_mode_label = Guidot_Utils.create_label_row("Current mode", "Realtime", Vector2(200, 20))

	var opacity_margin: MarginContainer = MarginContainer.new()
	opacity_margin.add_theme_constant_override("margin_left", 4)
	opacity_margin.add_theme_constant_override("margin_right", 4)
	opacity_margin.add_theme_constant_override("margin_top", 2)
	opacity_margin.add_theme_constant_override("margin_bottom", 2)

	var opacity_hbox: HBoxContainer = HBoxContainer.new()
	opacity_hbox.add_theme_constant_override("separation", 8)

	var opacity_text: Label = Label.new()
	opacity_text.text = "Opacity"
	opacity_text.custom_minimum_size = Vector2(60, 0)
	opacity_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var opacity_slider: HSlider = HSlider.new()
	opacity_slider.min_value = 0.0
	opacity_slider.max_value = 1.0
	opacity_slider.step = 0.01
	opacity_slider.value = 1.0
	opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opacity_slider.custom_minimum_size = Vector2(0, 20)

	var opacity_value_label: Label = Label.new()
	opacity_value_label.text = "100%"
	opacity_value_label.custom_minimum_size = Vector2(36, 0)
	opacity_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	opacity_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	opacity_slider.value_changed.connect(func(v: float) -> void:
		opacity_value_label.text = "%d%%" % int(v * 100)
		opacity_changed.emit(v)
	)

	opacity_hbox.add_child(opacity_text)
	opacity_hbox.add_child(opacity_slider)
	opacity_hbox.add_child(opacity_value_label)
	opacity_margin.add_child(opacity_hbox)

	var add_server_btn: Button = Button.new()
	add_server_btn.text = "+ Add Server"
	add_server_btn.pressed.connect(self._on_add_server_pressed)

	_apply_changes_btn.text = "Apply changes"
	self._apply_changes_btn.pressed.connect(self._on_apply_changes_to_graph)
	
	var server_config_rows: Array[Node] = [graph_buffer_mode_label, opacity_margin, add_server_btn, self._apply_changes_btn]
	self.add_config_rows(self._server_config_tab, server_config_rows)

	# Setup y-axis configurator
	self._y_axis_config_tab = self.create_configuration_tab("Y-Axis")
	self._graph_config_tab_cont.add_child(self._y_axis_config_tab)
	self._apply_y_axis_changes_btn.text = "Apply changes"
	self._apply_y_axis_changes_btn.pressed.connect(self._on_apply_y_axis_changes)

	var left_axis_row: HBoxContainer = self.create_axis_count_row("Left axes", self._left_axis_count, int(self._n_axis.x))
	var right_axis_row: HBoxContainer = self.create_axis_count_row("Right axes", self._right_axis_count, int(self._n_axis.y), true)

	self._left_axis_count.item_selected.connect(self._on_left_axis_count_selected)
	self._right_axis_count.item_selected.connect(self._on_right_axis_count_selected)

	self.add_config_rows(self._y_axis_config_tab, [left_axis_row, right_axis_row, self._apply_y_axis_changes_btn])

	self._t_axis_config_tab = self.create_configuration_tab("T-Axis")
	self._graph_config_tab_cont.add_child(self._t_axis_config_tab)
