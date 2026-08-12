extends SceneTree
## Pruebas headless: equipment, consumibles, bloqueos, Water.


func _init() -> void:
	var failed := 0
	failed += _test_uses_init()
	failed += _test_equipment_slots()
	failed += _test_hand_preference()
	failed += _test_replace_keeps_in_grid()
	failed += _test_consumable_deplete()
	failed += _test_water_three_uses()
	failed += _test_block_combine_when_equipped()
	failed += _test_move_equipped_allowed()
	if failed == 0:
		print("EQ_CONS_TESTS_OK")
		quit(0)
	else:
		print("EQ_CONS_TESTS_FAILED count=", failed)
		quit(1)


func _ok(name: String) -> int:
	print("OK ", name)
	return 0


func _fail(name: String, msg: String) -> int:
	push_error("FAIL %s: %s" % [name, msg])
	print("FAIL ", name, ": ", msg)
	return 1


func _test_uses_init() -> int:
	var water := load("res://inventory/data/items/Water.tres") as ItemData
	var bread := load("res://inventory/data/items/Bread.tres") as ItemData
	var sword := load("res://inventory/data/items/Sword.tres") as ItemData
	if water == null or bread == null or sword == null:
		return _fail("uses_init", "no se cargaron items")
	if water.max_uses != 3:
		return _fail("uses_init", "Water.max_uses=%s" % water.max_uses)
	if bread.max_uses != 1:
		return _fail("uses_init", "Bread.max_uses=%s" % bread.max_uses)
	if sword.max_uses != 0:
		return _fail("uses_init", "Sword.max_uses=%s" % sword.max_uses)
	var wi := ItemInstance.from_data(water)
	var bi := ItemInstance.from_data(bread)
	var si := ItemInstance.from_data(sword)
	if wi.uses_remaining != 3 or bi.uses_remaining != 1 or si.uses_remaining != 0:
		return _fail("uses_init", "remaining water=%s bread=%s sword=%s" % [wi.uses_remaining, bi.uses_remaining, si.uses_remaining])
	return _ok("uses_init")


func _test_equipment_slots() -> int:
	var eq := EquipmentSystem.new()
	var helmet := ItemInstance.from_data(load("res://inventory/data/items/Helmet.tres"))
	var armor := ItemInstance.from_data(load("res://inventory/data/items/CoreArmor.tres"))
	var ring := ItemInstance.from_data(load("res://inventory/data/items/Ring.tres"))
	if not eq.can_equip(helmet) or not eq.can_equip(armor) or not eq.can_equip(ring):
		return _fail("equipment_slots", "can_equip falló")
	eq.equip(helmet)
	eq.equip(armor)
	eq.equip(ring)
	if eq.get_equipped(EquipmentSystem.Slot.HEAD) != helmet:
		return _fail("equipment_slots", "HEAD")
	if eq.get_equipped(EquipmentSystem.Slot.BODY) != armor:
		return _fail("equipment_slots", "BODY")
	if eq.get_equipped(EquipmentSystem.Slot.RING) != ring:
		return _fail("equipment_slots", "RING")
	if not eq.is_equipped(helmet):
		return _fail("equipment_slots", "is_equipped")
	eq.unequip_instance(helmet)
	if eq.is_equipped(helmet) or eq.get_equipped(EquipmentSystem.Slot.HEAD) != null:
		return _fail("equipment_slots", "unequip")
	var bread := ItemInstance.from_data(load("res://inventory/data/items/Bread.tres"))
	if eq.can_equip(bread):
		return _fail("equipment_slots", "bread no debe equiparse")
	return _ok("equipment_slots")


func _test_hand_preference() -> int:
	var eq := EquipmentSystem.new()
	var sword := ItemInstance.from_data(load("res://inventory/data/items/Sword.tres"))
	var shield := ItemInstance.from_data(load("res://inventory/data/items/Shield.tres"))
	eq.equip(sword)
	if eq.get_equipped(EquipmentSystem.Slot.RIGHT_HAND) != sword:
		return _fail("hand_preference", "WEAPON -> RIGHT_HAND")
	eq.equip(shield)
	if eq.get_equipped(EquipmentSystem.Slot.LEFT_HAND) != shield:
		return _fail("hand_preference", "EQUIPABLE HAND -> LEFT_HAND")
	# Ambos ocupados: segundo weapon reemplaza RIGHT
	var bow := ItemInstance.from_data(load("res://inventory/data/items/Bow.tres"))
	var prev := eq.equip(bow)
	if prev != sword:
		return _fail("hand_preference", "replace preferred debería ser sword, got %s" % (prev.data.item_id if prev and prev.data else "?"))
	if eq.get_equipped(EquipmentSystem.Slot.RIGHT_HAND) != bow:
		return _fail("hand_preference", "bow en RIGHT")
	if eq.is_equipped(sword):
		return _fail("hand_preference", "sword debería estar desequipada")
	if not eq.is_equipped(shield):
		return _fail("hand_preference", "shield sigue equipado")
	return _ok("hand_preference")


func _test_replace_keeps_in_grid() -> int:
	var grid := InventoryGrid.new(8, 8)
	var eq := EquipmentSystem.new()
	var a := ItemInstance.from_data(load("res://inventory/data/items/Sword.tres"))
	var b := ItemInstance.from_data(load("res://inventory/data/items/PracticeSword.tres"))
	var c := ItemInstance.from_data(load("res://inventory/data/items/Bow.tres"))
	if not grid.place_instance(a, Vector2i(0, 0), false):
		return _fail("replace_grid", "place a")
	if not grid.place_instance(b, Vector2i(2, 0), false):
		return _fail("replace_grid", "place b")
	if not grid.place_instance(c, Vector2i(4, 0), false):
		return _fail("replace_grid", "place c")
	eq.equip(a) # RIGHT
	eq.equip(b) # LEFT libre (preferido ocupado)
	if not eq.is_equipped(a) or not eq.is_equipped(b):
		return _fail("replace_grid", "ambas manos ocupadas con a y b")
	var prev := eq.equip(c) # ambas ocupadas → reemplaza preferido RIGHT (a)
	if prev != a:
		return _fail("replace_grid", "debe desalojar a")
	if grid.get_instance_at(Vector2i(0, 0)) != a:
		return _fail("replace_grid", "a debe seguir en grid")
	if grid.get_instance_at(Vector2i(2, 0)) != b:
		return _fail("replace_grid", "b debe seguir en grid")
	if grid.get_instance_at(Vector2i(4, 0)) != c:
		return _fail("replace_grid", "c debe seguir en grid")
	if eq.is_equipped(a):
		return _fail("replace_grid", "a desequipada tras replace")
	if not eq.is_equipped(b) or not eq.is_equipped(c):
		return _fail("replace_grid", "b y c equipadas")
	return _ok("replace_grid")


func _test_consumable_deplete() -> int:
	var cons := InventoryConsumable.new()
	var bread := ItemInstance.from_data(load("res://inventory/data/items/Bread.tres"))
	if not cons.can_use(bread):
		return _fail("consumable", "can_use bread")
	if not cons.use(bread):
		return _fail("consumable", "use bread")
	if not cons.is_depleted(bread):
		return _fail("consumable", "bread no depleted")
	if cons.can_use(bread):
		return _fail("consumable", "no can_use tras deplete")
	var sword := ItemInstance.from_data(load("res://inventory/data/items/Sword.tres"))
	if cons.can_use(sword):
		return _fail("consumable", "sword no consumible")
	return _ok("consumable")


func _test_water_three_uses() -> int:
	var cons := InventoryConsumable.new()
	var water := ItemInstance.from_data(load("res://inventory/data/items/Water.tres"))
	var data := water.data
	if not data.shows_use_bar():
		return _fail("water", "shows_use_bar")
	var expected := [3, 2, 1, 0]
	for i in range(3):
		if water.uses_remaining != expected[i]:
			return _fail("water", "antes uso %s remaining=%s" % [i, water.uses_remaining])
		if not cons.use(water):
			return _fail("water", "use %s" % i)
	if water.uses_remaining != 0 or not cons.is_depleted(water):
		return _fail("water", "final remaining=%s" % water.uses_remaining)
	# Simular remove del grid
	var grid := InventoryGrid.new(4, 4)
	var w2 := ItemInstance.from_data(data)
	grid.place_instance(w2, Vector2i(0, 0), false)
	for _i in range(3):
		cons.use(w2)
	if cons.is_depleted(w2):
		grid.remove_instance(Vector2i(0, 0))
	if grid.get_instance_at(Vector2i(0, 0)) != null:
		return _fail("water", "debe eliminarse del grid a 0")
	return _ok("water")


func _test_block_combine_when_equipped() -> int:
	var eq := EquipmentSystem.new()
	var combiner := InventoryCombiner.new()
	var jam_bread := load("res://inventory/data/combinations/jam_bread.tres") as CombinationData
	var jam_ring := load("res://inventory/data/combinations/jam_ring.tres") as CombinationData
	combiner.set_recipes([jam_bread, jam_ring] as Array[CombinationData])
	var jam := ItemInstance.from_data(load("res://inventory/data/items/Jam.tres"))
	var sword := ItemInstance.from_data(load("res://inventory/data/items/Sword.tres"))
	eq.equip(sword)
	if not eq.is_equipped(sword):
		return _fail("block_combine", "sword debería estar equipada")
	if not combiner.can_participate(jam.data):
		return _fail("block_combine", "jam debería poder participar")
	var ring := ItemInstance.from_data(load("res://inventory/data/items/Ring.tres"))
	eq.equip(ring)
	var can_combine_ring := combiner.can_participate(ring.data) and not eq.is_equipped(ring)
	if can_combine_ring:
		return _fail("block_combine", "ring equipado no debe combinar")
	eq.unequip_instance(ring)
	can_combine_ring = combiner.can_participate(ring.data) and not eq.is_equipped(ring)
	if not can_combine_ring:
		return _fail("block_combine", "ring desequipado sí puede combinar")
	var transfer_ok := not eq.is_equipped(sword)
	if transfer_ok:
		return _fail("block_combine", "transfer de sword equipada debe bloquearse")
	return _ok("block_combine")

func _test_move_equipped_allowed() -> int:
	var grid := InventoryGrid.new(8, 8)
	var eq := EquipmentSystem.new()
	var sword := ItemInstance.from_data(load("res://inventory/data/items/Sword.tres"))
	grid.place_instance(sword, Vector2i(0, 0), false)
	eq.equip(sword)
	if not grid.move_item(Vector2i(0, 0), Vector2i(3, 0), false):
		return _fail("move_equipped", "move falló")
	if grid.get_instance_at(Vector2i(3, 0)) != sword:
		return _fail("move_equipped", "instancia no en destino")
	if not eq.is_equipped(sword):
		return _fail("move_equipped", "sigue equipada por referencia")
	return _ok("move_equipped")
