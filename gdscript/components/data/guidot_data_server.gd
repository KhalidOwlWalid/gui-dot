# @tool
class_name Guidot_Data_Server
extends Guidot_Data_Core

signal connected
signal disconnected

func _ready() -> void:
    self.add_to_group(self._server_group_name)
    print(self.get_tree().get_nodes_in_group(self._server_group_name))

func hello() -> void:
    print("Hello")

func _physics_process(delta: float) -> void:
    # print("Test")
    pass