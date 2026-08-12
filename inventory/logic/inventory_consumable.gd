class_name InventoryConsumable
extends RefCounted
## Consumo genérico: reduce uses_remaining. Sin efectos de gameplay todavía.


func can_use(instance: ItemInstance) -> bool:
	if instance == null or instance.data == null:
		return false
	if instance.data.category != ItemData.Category.CONSUMABLE:
		return false
	if instance.data.max_uses <= 0:
		return false
	return instance.uses_remaining > 0


## Aplica un uso. Devuelve true si se consumió. No elimina del grid.
func use(instance: ItemInstance) -> bool:
	if not can_use(instance):
		return false
	return instance.consume_one_use()


func is_depleted(instance: ItemInstance) -> bool:
	if instance == null or instance.data == null:
		return false
	if instance.data.max_uses <= 0:
		return false
	return instance.uses_remaining <= 0
