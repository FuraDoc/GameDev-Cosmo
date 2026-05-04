extends Control

# Сигнал выбора новой игры: сообщает номер слота и введенное имя пилота наружу.
signal new_game_confirmed(slot_id: int, pilot_name: String)

# Сигнал продолжения игры: сообщает наружу, какой слот нужно загрузить.
signal continue_confirmed(slot_id: int)

# Сигнал отмены: нужен главному меню, чтобы закрыть окно и вернуться назад.
signal cancelled

# Заголовок окна выбора слота: меняется между «Новая игра» и «Продолжить».
@onready var title_label = $CenterContainer/RootVBox/TitleLabel

# Контейнер карточек слотов: сюда динамически добавляются три карточки сохранений.
@onready var slots_row = $CenterContainer/RootVBox/SlotsRow

# Кнопка назад: закрывает popup и сообщает вызывающему экрану об отмене.
@onready var back_button = $CenterContainer/RootVBox/BackButton

# Текущий режим окна: "new_game" создает слот, другой режим загружает существующий.
var mode: String = "new_game"

# Сцена одной карточки слота: инстанцируется для каждого сохранения из SaveManager.
var save_slot_card_scene = preload("res://scenes/ui/save_slot_card.tscn")

# Путь к фону монитора: пока хранится здесь как настройка для будущего оформления.
var monitor_texture_path := "res://assets/backgrounds/equip/save_background.png"


# _ready — «готово»: растягивает окно, подключает кнопку и строит карточки слотов.
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_button.pressed.connect(_on_back_button_pressed)
	Localization.language_changed.connect(_on_language_changed)
	setup_mode()
	build_cards()


# setup_mode — «настроить режим»: выставляет заголовок по режиму новой игры/продолжения.
func setup_mode() -> void:
	if mode == "new_game":
		title_label.text = Localization.tr_text("save.new_game")
	else:
		title_label.text = Localization.tr_text("save.continue")
	back_button.text = Localization.tr_text("save.back")


func _on_language_changed(_language_code: String) -> void:
	setup_mode()
	build_cards()


# build_cards — «построить карточки»: очищает контейнер и создает UI для всех слотов.
func build_cards() -> void:
	for child in slots_row.get_children():
		child.queue_free()
	
	var slots = SaveManager.get_all_slots_summary()
	
	for slot_data in slots:
		var card = save_slot_card_scene.instantiate()
		card.setup(mode, slot_data)
		
		card.new_game_requested.connect(_on_card_new_game_requested)
		card.continue_requested.connect(_on_card_continue_requested)
		
		slots_row.add_child(card)


# _on_card_new_game_requested — «карточка запросила новую игру»: пробрасывает сигнал выше.
func _on_card_new_game_requested(slot_id: int, pilot_name: String) -> void:
	new_game_confirmed.emit(slot_id, pilot_name)
	queue_free()


# _on_card_continue_requested — «карточка запросила продолжение»: пробрасывает загрузку выше.
func _on_card_continue_requested(slot_id: int) -> void:
	continue_confirmed.emit(slot_id)
	queue_free()


# _on_back_button_pressed — «нажата кнопка назад»: сообщает отмену и закрывает окно.
func _on_back_button_pressed() -> void:
	cancelled.emit()
	queue_free()


# _unhandled_input — «необработанный ввод»: закрывает окно по Escape/ui_cancel.
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		cancelled.emit()
		queue_free()
		
		 
