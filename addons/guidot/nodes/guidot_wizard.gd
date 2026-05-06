@tool
class_name Guidot_Wizard
extends Guidot_Movable_Panel

@onready var _menu_vbox: VBoxContainer = VBoxContainer.new()
@onready var _filter_prop_line_edit: LineEdit = LineEdit.new()
@onready var _menu_tab_cont: PanelContainer = PanelContainer.new()

func _ready() -> void:
	super._ready()
	self.name = "Guidot Wizard"
	self.set_title_name(self.name)
	self.global_position = DisplayServer.screen_get_size()/2 - Vector2i(self.size/2)

	_filter_prop_line_edit.placeholder_text = "Filter Properties"
	self._menu_vbox.add_child(_filter_prop_line_edit)

	self._menu_tab_cont.size_flags_vertical = Control.SIZE_EXPAND_FILL

	self._menu_cont_stylebox.bg_color = Guidot_Utils.get_guidot_base_color()
	self.set_margin_size(self._menu_cont_stylebox, 3)
	self._menu_tab_cont.add_theme_stylebox_override("panel", self._menu_cont_stylebox)
	self._menu_vbox.add_child(_menu_tab_cont)

	_panel_space.add_child(_menu_vbox)

func _process(delta: float) -> void:
	super._process(delta)

func _input(event: InputEvent) -> void:
	super._input(event)
