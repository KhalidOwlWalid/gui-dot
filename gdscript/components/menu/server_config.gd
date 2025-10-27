class_name Guidot_Server_Config
extends Guidot_Panel2

func _ready() -> void:
	super._ready()

	var vbox: VBoxContainer = VBoxContainer.new()
	self.add_child_to_container(vbox)

	var button = Button.new()
	button.text = "Server Selection 1"
	vbox.add_child(button)

	# All server configuration settings
	var graph_buffer_mode_label = Guidot_Utils.create_label_row("Current mode", "Realtime", Vector2(200, 20))
	var server_selection = Guidot_Utils.create_dropdown_selection_row("Server Node", ["Khalid", "Alia"], Vector2(200, 20))

	vbox.add_child(graph_buffer_mode_label)
	vbox.add_child(server_selection)

	# var subscribe_data_button: Button = Button.new()
	# subscribe_data_margin_container.add_child(subscribe_data_button)
	# subscribe_data_button.text = "+ Subscribe to data"
	# subscribe_data_button.pressed.connect(_on_subscribe_pressed)

	# # TODO (Khalid): Use a scroll container to allow us to go through all of the subscribed data
	# var sub_data_scroll_cont: ScrollContainer = ScrollContainer.new()
	# sub_data_scroll_cont.custom_minimum_size = Vector2(100, 200)
	# var sub_data_vbox: VBoxContainer = VBoxContainer.new()
	# sub_data_scroll_cont.add_child(sub_data_vbox)
