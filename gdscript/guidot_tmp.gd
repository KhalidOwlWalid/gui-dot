@tool
class_name Guidot_Temp
extends PopupMenu

var test_popup: PopupMenu

func _process(delta: float) -> void:
	test_popup = PopupMenu.new()
	add_child(test_popup)
	test_popup.add_check_item("test")
	test_popup.hide_on_item_selection = true
	test_popup.unresizable = true

func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_RIGHT:
			var curr_mouse_pos : Vector2 = self.get_viewport().get_mouse_position()
			test_popup.show()
			print("popup created")
