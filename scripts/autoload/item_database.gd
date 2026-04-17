extends Node

# Эта база данных нужна, чтобы:
# 1. не хардкодить все описания предметов в UI;
# 2. по item_id быстро получать ItemData;
# 3. в будущем спокойно расширять контент.

# Внутренний словарь:
# ключ = item_id
# значение = ItemData
var _items_by_id: Dictionary = {}


func _ready():
	# При старте игры загружаем все 5 предметов.
	# Для текущего масштаба проекта это проще и надежнее,
	# чем делать сложный автоскан папки.
	_load_item("res://data/items/rescue_suit.tres")
	_load_item("res://data/items/ar_visor.tres")
	_load_item("res://data/items/wave_drone.tres")
	_load_item("res://data/items/analytic_resonator.tres")
	_load_item("res://data/items/smart_metal_container.tres")


func _load_item(path: String) -> void:
	var item = load(path) as ItemData
	
	if item == null:
		push_error("ItemDatabase: не удалось загрузить ItemData: " + path)
		return
	
	if item.item_id.is_empty():
		push_error("ItemDatabase: у предмета пустой item_id: " + path)
		return
	
	if _items_by_id.has(item.item_id):
		push_error("ItemDatabase: дублирующийся item_id: " + item.item_id)
		return
	
	_items_by_id[item.item_id] = item


func get_item(item_id: String) -> ItemData:
	# Возвращает ItemData по id.
	# Если id неизвестен — вернет null.
	return _items_by_id.get(item_id, null)


func has_item_definition(item_id: String) -> bool:
	return _items_by_id.has(item_id)


func get_all_items() -> Array[ItemData]:
	# Может пригодиться позже для отладки или админ-панели.
	var result: Array[ItemData] = []
	for item in _items_by_id.values():
		result.append(item)
	return result
