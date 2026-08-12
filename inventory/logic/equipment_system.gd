class_name EquipmentSystem
extends RefCounted
## Slots de equipo. Misma ItemInstance que el InventoryGrid (no saca del inventario).

enum Slot {
	LEFT_HAND,
	RIGHT_HAND,
	HEAD,
	BODY,
	RING,
}

## Slot -> ItemInstance
var _slots: Dictionary = {}


func _init() -> void:
	for slot in Slot.values():
		_slots[slot] = null


func can_equip(instance: ItemInstance) -> bool:
	if instance == null or instance.data == null:
		return false
	return instance.data.is_equipable()


func resolve_slot(instance: ItemInstance) -> int:
	if not can_equip(instance):
		return -1
	var data: ItemData = instance.data
	match data.equip_slot:
		ItemData.EquipSlot.HEAD:
			return Slot.HEAD
		ItemData.EquipSlot.BODY:
			return Slot.BODY
		ItemData.EquipSlot.RING:
			return Slot.RING
		ItemData.EquipSlot.HAND:
			return _resolve_hand_slot(data)
		_:
			return -1


func _resolve_hand_slot(data: ItemData) -> int:
	var preferred: int = Slot.RIGHT_HAND if data.category == ItemData.Category.WEAPON else Slot.LEFT_HAND
	var other: int = Slot.LEFT_HAND if preferred == Slot.RIGHT_HAND else Slot.RIGHT_HAND
	if _slots[preferred] == null:
		return preferred
	if _slots[other] == null:
		return other
	return preferred


## Equipa. Devuelve la instancia desalojada del slot (o null).
func equip(instance: ItemInstance) -> ItemInstance:
	if not can_equip(instance):
		return null
	# Si ya está equipada en algún slot, primero quitarla.
	unequip_instance(instance)
	var slot: int = resolve_slot(instance)
	if slot < 0:
		return null
	var previous: ItemInstance = _slots[slot]
	_slots[slot] = instance
	return previous


func unequip_slot(slot: int) -> ItemInstance:
	if not _slots.has(slot):
		return null
	var previous: ItemInstance = _slots[slot]
	_slots[slot] = null
	return previous


func unequip_instance(instance: ItemInstance) -> bool:
	if instance == null:
		return false
	for slot in _slots.keys():
		if _slots[slot] == instance:
			_slots[slot] = null
			return true
	return false


func get_equipped(slot: int) -> ItemInstance:
	return _slots.get(slot, null)


func is_equipped(instance: ItemInstance) -> bool:
	if instance == null:
		return false
	for slot in _slots.keys():
		if _slots[slot] == instance:
			return true
	return false


func get_slot_of(instance: ItemInstance) -> int:
	if instance == null:
		return -1
	for slot in _slots.keys():
		if _slots[slot] == instance:
			return slot
	return -1
