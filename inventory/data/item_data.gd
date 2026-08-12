class_name ItemData
extends Resource
## Datos estáticos de un objeto del inventario (capa de datos, sin lógica de grid/UI/equipo).
## El tamaño se expresa en casillas del grid (p. ej. 1×3), nunca en píxeles.

enum Category {
	CONSUMABLE,
	WEAPON,
	ARMOR,
	EQUIPABLE,
}

## Tipo de slot compatible. HAND se resuelve a LEFT_HAND/RIGHT_HAND en EquipmentSystem.
enum EquipSlot {
	NONE,
	HAND,
	HEAD,
	BODY,
	RING,
}

@export var item_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(1, 64, 1) var size_x: int = 1:
	set(value):
		size_x = maxi(1, value)
@export_range(1, 64, 1) var size_y: int = 1:
	set(value):
		size_y = maxi(1, value)
@export var icon: Texture2D
@export var can_rotate: bool = true
@export var category: Category = Category.CONSUMABLE
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var inventory_sound: AudioStream
## Usos máximos estáticos (consumibles). 0 = no consumible por usos. El remaining vive en ItemInstance.
@export var max_uses: int = 0


func get_size() -> Vector2i:
	return Vector2i(size_x, size_y)


## Tamaño tras rotar 90°. No modifica size_x ni size_y.
func get_rotated_size() -> Vector2i:
	return Vector2i(size_y, size_x)


func is_consumable() -> bool:
	return category == Category.CONSUMABLE and max_uses > 0


func is_equipable() -> bool:
	return equip_slot != EquipSlot.NONE


## Water (u objetos con barra de usos): max_uses > 1 suele mostrar barra.
func shows_use_bar() -> bool:
	return item_id == &"water" and max_uses > 0
