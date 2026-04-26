extends Node

var _items_by_id: Dictionary = {}


func _ready():
	_load_item("res://data/items/standard_suit.tres")
	_load_item("res://data/items/heavy_rescue_suit.tres")
	_load_item("res://data/items/nova_suit.tres")
	_load_item("res://data/items/ar_visor.tres")
	_load_item("res://data/items/wave_drone.tres")
	_load_item("res://data/items/analytic_resonator.tres")
	_load_item("res://data/items/smart_metal_container.tres")
	_load_item("res://data/items/plasma_cutter.tres")
	_load_item("res://data/items/strange_cube.tres")


func _load_item(path: String) -> void:
	var item = load(path) as ItemData

	if item == null:
		push_error("ItemDatabase: failed to load ItemData: " + path)
		return

	if item.item_id.is_empty():
		push_error("ItemDatabase: empty item_id in: " + path)
		return

	if _items_by_id.has(item.item_id):
		push_error("ItemDatabase: duplicate item_id: " + item.item_id)
		return

	_items_by_id[item.item_id] = item


func get_item(item_id: String) -> ItemData:
	return _items_by_id.get(item_id, null)


func has_item_definition(item_id: String) -> bool:
	return _items_by_id.has(item_id)


func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _items_by_id.values():
		result.append(item)
	return result
