class_name InventoryGrid
extends RefCounted
## Lógica pura del grid de inventario (casillas, no píxeles). Independiente de UI.

## Identidad de una colocación: varias casillas apuntan a la misma instancia.
class _Placement:
	var item: ItemData
	var origin: Vector2i
	var rotated: bool

	func _init(p_item: ItemData, p_origin: Vector2i, p_rotated: bool) -> void:
		item = p_item
		origin = p_origin
		rotated = p_rotated


var columns: int = 0
var rows: int = 0

## Matriz [y][x] → _Placement o null.
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


func can_place(item: ItemData, position: Vector2i, rotated: bool = false) -> bool:
	if item == null:
		return false
	if rotated and not item.can_rotate:
		return false

	var size := _item_size(item, rotated)
	for y in size.y:
		for x in size.x:
			var cell := position + Vector2i(x, y)
			if not is_position_valid(cell):
				return false
			if _cells[cell.y][cell.x] != null:
				return false
	return true


func place_item(item: ItemData, position: Vector2i, rotated: bool = false) -> bool:
	if not can_place(item, position, rotated):
		return false

	var placement := _Placement.new(item, position, rotated)
	var size := _item_size(item, rotated)
	for y in size.y:
		for x in size.x:
			var cell := position + Vector2i(x, y)
			_cells[cell.y][cell.x] = placement
	return true


func get_item_at(position: Vector2i) -> ItemData:
	var placement := _get_placement_at(position)
	if placement == null:
		return null
	return placement.item


func remove_item(position: Vector2i) -> ItemData:
	var placement := _get_placement_at(position)
	if placement == null:
		return null

	var size := _item_size(placement.item, placement.rotated)
	for y in size.y:
		for x in size.x:
			var cell := placement.origin + Vector2i(x, y)
			if is_position_valid(cell) and _cells[cell.y][cell.x] == placement:
				_cells[cell.y][cell.x] = null
	return placement.item


func _get_placement_at(position: Vector2i) -> _Placement:
	if not is_position_valid(position):
		return null
	return _cells[position.y][position.x] as _Placement


func _item_size(item: ItemData, rotated: bool) -> Vector2i:
	if rotated:
		return item.get_rotated_size()
	return item.get_size()
