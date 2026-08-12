class_name CombinationData
extends Resource
## Receta data-driven: item_a + item_b -> result (orden indiferente en runtime).

@export var item_a: ItemData
@export var item_b: ItemData
@export var result: ItemData


func matches(a: ItemData, b: ItemData) -> bool:
	if a == null or b == null or item_a == null or item_b == null:
		return false
	var id_a := a.item_id
	var id_b := b.item_id
	return (
		(item_a.item_id == id_a and item_b.item_id == id_b)
		or (item_a.item_id == id_b and item_b.item_id == id_a)
	)


func involves(item: ItemData) -> bool:
	if item == null or item_a == null or item_b == null:
		return false
	return item.item_id == item_a.item_id or item.item_id == item_b.item_id
