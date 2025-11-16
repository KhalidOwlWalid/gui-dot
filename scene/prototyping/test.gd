extends OptionButton

@onready var _guidot_stylebox: StyleBoxFlat = StyleBoxFlat.new()

func callback():
	print("Hello")
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = true
	self.item_selected.connect(self.callback)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.visible = true
