@tool
class_name Guidot_Data_Core
extends Node

@onready var frequency: float = 0
@onready var unit: String = ""
@onready var description: String = ""

# WARNING: This should not be changed by the user
@onready var _server_group_name: String = "Guidot_Server"
@onready var _client_group_name: String = "Guidot_Client"

func _ready() -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

func set_unit(unit: String) -> void:
    pass

func get_unit() -> String:
    return String()

func set_description(description: String) -> void:
    pass

func get_description() -> String:
    return String()

func set_frequency(freq: float) -> void:
    pass

func get_freqeuncy() -> float:
    return 0

func generate_unique_name(type: String) -> void:
    self.name = type + "<" + str(self.get_instance_id()) + ">"