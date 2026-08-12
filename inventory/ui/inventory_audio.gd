class_name InventoryAudio
extends Node
## Reproduce el AudioStream asociado a un ItemData.

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)


func play_item_sound(item: ItemData) -> void:
	if item == null or item.inventory_sound == null or _player == null:
		return
	_player.stream = item.inventory_sound
	_player.play()
