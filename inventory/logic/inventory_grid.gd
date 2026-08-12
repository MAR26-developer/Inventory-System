class_name InventoryGrid
extends RefCounted
## Lógica pura del grid de inventario (casillas, no píxeles). Independiente de UI.

## Identidad de una colocación: varias casillas apuntan a la misma instancia runtime.
class Placement:
	var instance: ItemInstance
	var origin: Vector2i
	var rotated: bool

	func _init(p_instance: ItemInstance, p_origin: Vector2i, p_rotated: bool) -> void:
		instance = p_instance
		origin = p_origin
		rotated = p_rotated

	var item: ItemData:
		get:
			return instance.data if instance != null else null


var columns: int = 0
var rows: int = 0

## Matriz [y][x] → Placement o null.
var _cells: Array = []


func _init(p_columns: int = 1, p_rows: int = 1) -> void:
	initialize(p_columns, p_rows)


func initialize(p_columns: int, p_rows: int) -> void:
	assert(p_columns > 0 and p_rows > 0, "InventoryGrid: columns y rows deben ser > 0")
	columns = p_columns
	rows = p_rows
	_cells.clear()
	_cells.resize(rows)
	for y in rows:
		var row: Array = []
		row.resize(columns)
		row.fill(null)
		_cells[y] = row


func is_position_valid(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < columns and position.y < rows


func is_cell_free(position: Vector2i, ignore_a: Placement = null, ignore_b: Placement = null) -> bool:
	if not is_position_valid(position):
		return false
	var current: Placement = _cells[position.y][position.x] as Placement
	if current == null:
		return true
	if ignore_a != null and current == ignore_a:
		return true
	if ignore_b != null and current == ignore_b:
		return true
	return false


func can_place(
	item: ItemData,
	position: Vector2i,
	rotated: bool = false,
	ignore_a: Placement = null,
	ignore_b: Placement = null
) -> bool:
	if item == null:
		return false
	if rotated and not item.can_rotate:
		return false

	var size := _item_size(item, rotated)
	for y in size.y:
		for x in size.x:
			var cell := position + Vector2i(x, y)
			if not is_cell_free(cell, ignore_a, ignore_b):
				return false
	return true


func place_item(item: ItemData, position: Vector2i, rotated: bool = false) -> bool:
	if item == null:
		return false
	return place_instance(ItemInstance.from_data(item), position, rotated)


func place_instance(instance: ItemInstance, position: Vector2i, rotated: bool = false) -> bool:
	if instance == null or instance.data == null:
		return false
	if not can_place(instance.data, position, rotated):
		return false
	var placement := Placement.new(instance, position, rotated)
	_write_placement(placement)
	return true


func get_item_at(position: Vector2i) -> ItemData:
	var placement := get_placement_at(position)
	if placement == null:
		return null
	return placement.item


func get_instance_at(position: Vector2i) -> ItemInstance:
	var placement := get_placement_at(position)
	if placement == null:
		return null
	return placement.instance


func get_placement_at(position: Vector2i) -> Placement:
	if not is_position_valid(position):
		return null
	return _cells[position.y][position.x] as Placement


func remove_item(position: Vector2i) -> ItemData:
	var instance := remove_instance(position)
	return instance.data if instance != null else null


func remove_instance(position: Vector2i) -> ItemInstance:
	var placement := get_placement_at(position)
	if placement == null:
		return null
	var instance: ItemInstance = placement.instance
	_clear_placement(placement)
	return instance


## Mueve una colocación dentro del mismo grid (usa ignore_self).
func move_item(from: Vector2i, to: Vector2i, rotated: bool = false) -> bool:
	var placement := get_placement_at(from)
	if placement == null:
		return false
	if not can_place(placement.item, to, rotated, placement):
		return false
	_clear_placement(placement)
	placement.origin = to
	placement.rotated = rotated
	_write_placement(placement)
	return true


## Rota 90° en su origen. No muta el ItemData resource.
func rotate_item(position: Vector2i) -> bool:
	var placement := get_placement_at(position)
	if placement == null:
		return false
	if not placement.item.can_rotate:
		return false
	var new_rotated := not placement.rotated
	if not can_place(placement.item, placement.origin, new_rotated, placement):
		return false
	_clear_placement(placement)
	placement.rotated = new_rotated
	_write_placement(placement)
	return true


## Primer hueco libre para item, ignorando hasta dos placements (combinación).
func find_first_fit(
	item: ItemData,
	rotated: bool = false,
	ignore_a: Placement = null,
	ignore_b: Placement = null
) -> Vector2i:
	if item == null:
		return Vector2i(-1, -1)
	for y in rows:
		for x in columns:
			var cell := Vector2i(x, y)
			if can_place(item, cell, rotated, ignore_a, ignore_b):
				return cell
	return Vector2i(-1, -1)


func _write_placement(placement: Placement) -> void:
	var size := _item_size(placement.item, placement.rotated)
	for y in size.y:
		for x in size.x:
			var cell := placement.origin + Vector2i(x, y)
			_cells[cell.y][cell.x] = placement


func _clear_placement(placement: Placement) -> void:
	var size := _item_size(placement.item, placement.rotated)
	for y in size.y:
		for x in size.x:
			var cell := placement.origin + Vector2i(x, y)
			if is_position_valid(cell) and _cells[cell.y][cell.x] == placement:
				_cells[cell.y][cell.x] = null


func _item_size(item: ItemData, rotated: bool) -> Vector2i:
	if rotated:
		return item.get_rotated_size()
	return item.get_size()
