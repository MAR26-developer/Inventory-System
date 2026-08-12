class_name InventoryUI
extends Node2D
## Vista de un InventoryGrid: fondo + items. cell_size = 16 px (solo UI).

const CELL_SIZE := 16

@export var columns: int = 8
@export var rows: int = 8
@export var background_texture: Texture2D

var grid: InventoryGrid

var _background: Sprite2D
var _items_root: Node2D
var _item_nodes: Dictionary = {} # Placement -> ItemUI


func _ready() -> void:
	grid = InventoryGrid.new(columns, rows)
	_ensure_nodes()
	_setup_background()


func _ensure_nodes() -> void:
	_background = get_node_or_null("Background") as Sprite2D
	if _background == null:
		_background = Sprite2D.new()
		_background.name = "Background"
		_background.centered = false
		_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_background)
		move_child(_background, 0)

	_items_root = get_node_or_null("Items") as Node2D
	if _items_root == null:
		_items_root = Node2D.new()
		_items_root.name = "Items"
		add_child(_items_root)


func _setup_background() -> void:
	if background_texture != null:
		_background.texture = background_texture
	_background.centered = false
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func get_pixel_size() -> Vector2:
	return Vector2(columns * CELL_SIZE, rows * CELL_SIZE)


func world_to_cell(world_pos: Vector2) -> Vector2i:
	var local := to_local(world_pos)
	return Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))


func cell_to_world(cell: Vector2i) -> Vector2:
	return to_global(Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE))


func contains_world_point(world_pos: Vector2) -> bool:
	var local := to_local(world_pos)
	var size := get_pixel_size()
	return local.x >= 0.0 and local.y >= 0.0 and local.x < size.x and local.y < size.y


func try_place(item: ItemData, cell: Vector2i, rotated: bool = false) -> ItemUI:
	var instance := ItemInstance.from_data(item)
	return try_place_instance(instance, cell, rotated)


func try_place_instance(instance: ItemInstance, cell: Vector2i, rotated: bool = false) -> ItemUI:
	if not grid.place_instance(instance, cell, rotated):
		return null
	var placement := grid.get_placement_at(cell)
	return _create_item_ui(placement)


func get_item_ui_at_world(world_pos: Vector2) -> ItemUI:
	if not contains_world_point(world_pos):
		return null
	var cell := world_to_cell(world_pos)
	var placement := grid.get_placement_at(cell)
	if placement == null:
		return null
	return _item_nodes.get(placement) as ItemUI


func get_all_item_uis() -> Array[ItemUI]:
	var list: Array[ItemUI] = []
	for ui in _item_nodes.values():
		list.append(ui as ItemUI)
	return list


func detach_item_ui(item_ui: ItemUI) -> void:
	for key in _item_nodes.keys():
		if _item_nodes[key] == item_ui:
			_item_nodes.erase(key)
			break


func bind_item_ui(placement, item_ui: ItemUI) -> void:
	_item_nodes[placement] = item_ui
	if item_ui.get_parent() != _items_root:
		if item_ui.get_parent() != null:
			item_ui.get_parent().remove_child(item_ui)
		_items_root.add_child(item_ui)
	item_ui.setup(placement.instance, placement.origin, placement.rotated)


func remove_item_ui_at(placement) -> void:
	if placement == null:
		return
	var ui: ItemUI = _item_nodes.get(placement) as ItemUI
	if ui != null:
		_item_nodes.erase(placement)
		ui.queue_free()


func remove_instance_and_ui(instance: ItemInstance) -> bool:
	if instance == null:
		return false
	for placement in _item_nodes.keys():
		if placement.instance == instance:
			var origin: Vector2i = placement.origin
			remove_item_ui_at(placement)
			grid.remove_instance(origin)
			return true
	return false


func find_ui_for_instance(instance: ItemInstance) -> ItemUI:
	if instance == null:
		return null
	for ui in _item_nodes.values():
		var item_ui := ui as ItemUI
		if item_ui != null and item_ui.instance == instance:
			return item_ui
	return null


func create_item_ui_for_placement(placement) -> ItemUI:
	return _create_item_ui(placement)


func _create_item_ui(placement) -> ItemUI:
	var item_ui := ItemUI.new()
	_items_root.add_child(item_ui)
	item_ui.setup(placement.instance, placement.origin, placement.rotated)
	_item_nodes[placement] = item_ui
	return item_ui
