class_name ItemUI
extends Node2D
## Representación visual de un ItemInstance (icono + barra de usos + indicador EQ).

const CELL_SIZE := 16
const WATER_BAR_OFFSET := Vector2(1, 34)

var item_data: ItemData
var instance: ItemInstance
var grid_origin: Vector2i = Vector2i.ZERO
var rotated: bool = false

var _combine_dimmed: bool = false
var _equipped: bool = false
var _water_bar: TextureProgressBar
var _eq_label: Label


func setup(p_instance: ItemInstance, origin: Vector2i, is_rotated: bool = false) -> void:
	instance = p_instance
	item_data = p_instance.data if p_instance != null else null
	grid_origin = origin
	rotated = is_rotated
	position = grid_to_local(origin)
	_ensure_water_bar()
	_ensure_eq_label()
	_update_water_bar()
	_update_eq_label()
	queue_redraw()


func setup_from_data(data: ItemData, origin: Vector2i, is_rotated: bool = false) -> void:
	setup(ItemInstance.from_data(data), origin, is_rotated)


func get_footprint_size() -> Vector2i:
	if item_data == null:
		return Vector2i.ONE
	return item_data.get_rotated_size() if rotated else item_data.get_size()


func grid_to_local(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)


func set_rotated(is_rotated: bool) -> void:
	rotated = is_rotated
	_update_water_bar()
	_update_eq_label()
	queue_redraw()


func set_preview(valid: bool) -> void:
	_combine_dimmed = false
	modulate = Color(0.35, 1.0, 0.35, 0.8) if valid else Color(1.0, 0.35, 0.35, 0.8)


func clear_preview() -> void:
	if _combine_dimmed:
		modulate = Color(1, 1, 1, 0.35)
	else:
		modulate = Color.WHITE


func set_combine_highlight(compatible: bool) -> void:
	_combine_dimmed = not compatible
	if compatible:
		modulate = Color(1.0, 1.0, 0.55, 1.0)
	else:
		modulate = Color(1, 1, 1, 0.35)


func clear_combine_highlight() -> void:
	_combine_dimmed = false
	modulate = Color.WHITE


func set_equipped_indicator(equipped: bool) -> void:
	_equipped = equipped
	_update_eq_label()


func snap_to_origin() -> void:
	position = grid_to_local(grid_origin)
	clear_preview()
	_update_water_bar()
	_update_eq_label()
	queue_redraw()


func refresh_visual() -> void:
	_update_water_bar()
	_update_eq_label()
	queue_redraw()


func contains_local_point(local_point: Vector2) -> bool:
	var size := get_footprint_size()
	var rect := Rect2(Vector2.ZERO, Vector2(size.x * CELL_SIZE, size.y * CELL_SIZE))
	return rect.has_point(local_point)


func _ensure_eq_label() -> void:
	if _eq_label != null:
		return
	_eq_label = Label.new()
	_eq_label.text = "EQ"
	_eq_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eq_label.add_theme_font_size_override("font_size", 8)
	_eq_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
	_eq_label.visible = false
	add_child(_eq_label)


func _update_eq_label() -> void:
	_ensure_eq_label()
	_eq_label.visible = _equipped
	_eq_label.position = Vector2(1, get_footprint_size().y * CELL_SIZE - 10)


func _ensure_water_bar() -> void:
	if item_data == null or not item_data.shows_use_bar():
		if _water_bar != null:
			_water_bar.visible = false
		return
	if _water_bar != null:
		return
	_water_bar = TextureProgressBar.new()
	_water_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_water_bar.texture_under = load("res://sprites/WaterBar3.png") as Texture2D
	_water_bar.texture_progress = load("res://sprites/WaterBar2.png") as Texture2D
	_water_bar.texture_over = load("res://sprites/WaterBar1.png") as Texture2D
	_water_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	_water_bar.nine_patch_stretch = false
	_water_bar.position = WATER_BAR_OFFSET
	_water_bar.custom_minimum_size = Vector2(14, 3)
	_water_bar.size = Vector2(14, 3)
	add_child(_water_bar)


func _update_water_bar() -> void:
	_ensure_water_bar()
	if _water_bar == null:
		return
	if item_data == null or not item_data.shows_use_bar() or instance == null:
		_water_bar.visible = false
		return
	_water_bar.visible = not rotated
	_water_bar.max_value = item_data.max_uses
	_water_bar.value = instance.uses_remaining
	_water_bar.position = WATER_BAR_OFFSET


func _draw() -> void:
	if item_data == null or item_data.icon == null:
		return

	var tex: Texture2D = item_data.icon
	var footprint := get_footprint_size()
	var dest := Rect2(Vector2.ZERO, Vector2(footprint.x * CELL_SIZE, footprint.y * CELL_SIZE))

	if rotated:
		var base := item_data.get_size()
		var unrotated := Vector2(base.x * CELL_SIZE, base.y * CELL_SIZE)
		draw_set_transform(Vector2(unrotated.y, 0.0), TAU * 0.25, Vector2.ONE)
		draw_texture_rect(tex, Rect2(Vector2.ZERO, unrotated), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect(tex, dest, false)
