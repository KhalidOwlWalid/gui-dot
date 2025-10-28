class_name Guidot_Server_Config
extends Guidot_Panel2

var data_subscriber_manager: Guidot_Data_Sub_Manager

@onready var sub_data_scroll_cont: ScrollContainer = ScrollContainer.new()

func _get_selected_data_display() -> void:
	var vbox = sub_data_scroll_cont.get_children()

func _on_subscribe_pressed() -> void:
	self.data_subscriber_manager.visible = true

func _on_close_submenu_button_pressed(panel: Node) -> void:
	panel.visible = false

func register_data_sub_manager(dsub_node: Guidot_Data_Sub_Manager) -> void:
	self.data_subscriber_manager = dsub_node
	# TODO (Khalid): I do not like the way that this basically gets opened inside the server
	# selection panel itself, but I am struggling in making the data subscriber manager to open separately
	# on its own
	# self.add_child(self.data_subscriber_manager)
	
func _ready() -> void:
	super._ready()

	var vbox: VBoxContainer = VBoxContainer.new()
	self.add_child_to_container(vbox)

	# All server configuration settings
	var server_selection = Guidot_Utils.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))

	var margin_cont1: MarginContainer = MarginContainer.new()
	var subscribe_data_button: Button = Button.new()
	margin_cont1.add_child(subscribe_data_button)
	margin_cont1.add_theme_constant_override("margin_left", 10)
	margin_cont1.add_theme_constant_override("margin_right", 10)
	margin_cont1.add_theme_constant_override("margin_bottom", 10)
	subscribe_data_button.text = "+ Subscribe to data"
	subscribe_data_button.pressed.connect(self._on_subscribe_pressed)

	# TODO (Khalid): Use a scroll container to allow us to go through all of the subscribed data
	sub_data_scroll_cont.custom_minimum_size = Vector2(100, 100)
	var sub_data_vbox: VBoxContainer = VBoxContainer.new()
	sub_data_scroll_cont.add_child(sub_data_vbox)

	var tmp = Label.new()
	tmp.text = "Khalid"
	sub_data_vbox.add_child(tmp)

	vbox.add_child(server_selection)
	vbox.add_child(margin_cont1)
	vbox.add_child(sub_data_scroll_cont)


func _process(delta: float) -> void:
	pass
	# pass
