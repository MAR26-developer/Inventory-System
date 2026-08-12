class_name InventoryCombiner
extends RefCounted
## Resuelve y ejecuta combinaciones de forma atómica sobre un InventoryGrid.

var recipes: Array[CombinationData] = []


func set_recipes(list: Array[CombinationData]) -> void:
	recipes = list


func find_recipe(a: ItemData, b: ItemData) -> CombinationData:
	for recipe in recipes:
		if recipe != null and recipe.matches(a, b):
			return recipe
	return null


func can_participate(item: ItemData) -> bool:
	if item == null:
		return false
	for recipe in recipes:
		if recipe != null and recipe.involves(item):
			return true
	return false


func is_compatible_pair(a: ItemData, b: ItemData) -> bool:
	return find_recipe(a, b) != null


## Valida receta + espacio. No muta el grid.
func can_combine(
	grid: InventoryGrid,
	placement_a,
	placement_b
) -> bool:
	return _resolve_result_cell(grid, placement_a, placement_b) != Vector2i(-1, -1)


## Ejecuta combinación atómica. Devuelve la Placement del resultado o null.
func try_combine(
	grid: InventoryGrid,
	placement_a,
	placement_b
):
	if grid == null or placement_a == null or placement_b == null:
		return null
	if placement_a == placement_b:
		return null

	var recipe := find_recipe(placement_a.item, placement_b.item)
	if recipe == null or recipe.result == null:
		return null

	var cell := _resolve_result_cell(grid, placement_a, placement_b)
	if cell == Vector2i(-1, -1):
		return null

	var origin_a: Vector2i = placement_a.origin
	var origin_b: Vector2i = placement_b.origin
	var result_instance := ItemInstance.from_data(recipe.result)

	grid.remove_instance(origin_a)
	grid.remove_instance(origin_b)
	if not grid.place_instance(result_instance, cell, false):
		push_error("InventoryCombiner: place_instance falló tras validación")
		return null

	return grid.get_placement_at(cell)


func _resolve_result_cell(
	grid: InventoryGrid,
	placement_a,
	placement_b
) -> Vector2i:
	var recipe := find_recipe(placement_a.item, placement_b.item)
	if recipe == null or recipe.result == null:
		return Vector2i(-1, -1)

	var result: ItemData = recipe.result
	if grid.can_place(result, placement_a.origin, false, placement_a, placement_b):
		return placement_a.origin
	if grid.can_place(result, placement_b.origin, false, placement_a, placement_b):
		return placement_b.origin
	return grid.find_first_fit(result, false, placement_a, placement_b)
