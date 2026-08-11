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

## Tipo de slot compatible. Left/Right Hand lo resolverá EquipmentSystem más adelante.
enum EquipSlot {
	NONE,
	HAND,
	HEAD,
	BODY,
	RING,
}

@export var item_id: StringName = &""
@export var display_name: String = ""
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


func get_size() -> Vector2i:
	return Vector2i(size_x, size_y)


## Tamaño tras rotar 90°. No modifica size_x ni size_y.
func get_rotated_size() -> Vector2i:
	return Vector2i(size_y, size_x)
