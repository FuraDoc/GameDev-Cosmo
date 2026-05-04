extends Resource
class_name ItemData

# item_id — "id предмета": стабильная строка для инвентаря, квестовых проверок и сохранений.
@export var item_id: String = ""

# title — "название": короткое имя предмета, которое показывается игроку в интерфейсе.
@export var title: String = ""

# is_suit — "является костюмом": включает поведение кнопки "Использовать" в Снаряжении.
@export var is_suit: bool = false

# description — "описание": многострочный текст для всплывающих окон и будущих справок.
@export_multiline var description: String = ""

# equipment_texture — "текстура снаряжения": картинка предмета на фоне раздела Снаряжение.
@export var equipment_texture: Texture2D


func get_title() -> String:
	return Localization.get_item_title(self)


func get_description() -> String:
	return Localization.get_item_description(self)
