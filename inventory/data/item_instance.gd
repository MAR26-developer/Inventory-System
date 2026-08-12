class_name ItemInstance
extends RefCounted
## Estado runtime de un objeto colocado. Nunca se guarda en el .tres de ItemData.

var data: ItemData
## Usos restantes. Solo relevante si data.max_uses > 0.
var uses_remaining: int = 0


static func from_data(item_data: ItemData) -> ItemInstance:
	var instance := ItemInstance.new()
	instance.data = item_data
	if item_data != null and item_data.max_uses > 0:
		instance.uses_remaining = item_data.max_uses
	return instance


func get_size() -> Vector2i:
	if data == null:
		return Vector2i.ONE
	return data.get_size()


func get_rotated_size() -> Vector2i:
	if data == null:
		return Vector2i.ONE
	return data.get_rotated_size()


func set_uses_remaining(value: int) -> void:
	if data == null or data.max_uses <= 0:
		uses_remaining = 0
		return
	uses_remaining = clampi(value, 0, data.max_uses)


func consume_one_use() -> bool:
	if data == null or data.max_uses <= 0 or uses_remaining <= 0:
		return false
	uses_remaining -= 1
	return true
