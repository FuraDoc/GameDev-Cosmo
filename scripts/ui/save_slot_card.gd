extends Control

# Сигнал новой игры: карточка отправляет номер слота и имя пилота родительскому popup.
signal new_game_requested(slot_id: int, pilot_name: String)

# Сигнал продолжения: карточка отправляет номер существующего слота на загрузку.
signal continue_requested(slot_id: int)

# Текстурный фон карточки слота: может получить мониторную рамку/подложку.
@onready var panel_background = $PanelBackground

# Заголовок карточки: показывает «Слот 1», «Слот 2» и так далее.
@onready var slot_title_label = $ContentMargin/VBox/SlotTitleLabel

# Статус слота: пустой, занят или найденное сохранение.
@onready var status_label = $ContentMargin/VBox/StatusLabel

# Имя пилота: показывается в режиме продолжения игры.
@onready var pilot_name_label = $ContentMargin/VBox/PilotNameLabel

# Текущая локация/приключение: берется из данных сохранения.
@onready var location_label = $ContentMargin/VBox/LocationLabel

# Прогресс прохождения: сейчас показывает количество завершенных квестов.
@onready var progress_label = $ContentMargin/VBox/ProgressLabel

# Время игры: выводится в формате часы:минуты.
@onready var time_label = $ContentMargin/VBox/TimeLabel

# Подпись поля имени: используется только при создании новой игры.
@onready var name_prompt_label = $ContentMargin/VBox/NamePromptLabel

# Поле ввода имени пилота: активно только в режиме новой игры.
@onready var name_line_edit = $ContentMargin/VBox/NameLineEdit

# Главная кнопка карточки: подтверждает новую игру или загружает слот.
@onready var action_button = $ContentMargin/VBox/ActionButton

# Текущий режим карточки: "new_game" для создания, иначе режим продолжения.
var mode: String = "new_game"

# Данные слота из SaveManager: содержат exists, pilot_name, прогресс и время.
var slot_data: Dictionary = {}

# Номер слота: сохраняется отдельно, чтобы удобно использовать в сигналах.
var slot_id: int = 0

# Путь к текстуре монитора/карточки: можно заполнить в инспекторе или кодом.
var monitor_texture_path := ""

# _ready — «готово»: подключает кнопку, применяет фон и обновляет состояние карточки.
func _ready():
	action_button.pressed.connect(_on_action_button_pressed)
	apply_monitor_texture()
	refresh()


# setup — «настроить»: принимает режим и данные слота перед первым refresh.
func setup(new_mode: String, new_slot_data: Dictionary) -> void:
	mode = new_mode
	slot_data = new_slot_data
	slot_id = slot_data.get("slot_id", 0)


# apply_monitor_texture — «применить текстуру монитора»: загружает фон карточки, если задан путь.
func apply_monitor_texture() -> void:
	if monitor_texture_path.is_empty():
		return
	
	var texture = load(monitor_texture_path)
	if texture != null:
		panel_background.texture = texture


# refresh — «обновить»: выбирает нужное оформление карточки по режиму и наличию сохранения.
func refresh() -> void:
	var exists = slot_data.get("exists", false)
	
	slot_title_label.text = "Слот %d" % slot_id
	
	if mode == "new_game":
		_setup_new_game_mode(exists)
	else:
		_setup_continue_mode(exists)


# _setup_new_game_mode — «настроить режим новой игры»: показывает ввод имени и кнопку.
func _setup_new_game_mode(exists: bool) -> void:
	status_label.visible = true
	name_prompt_label.visible = true
	name_line_edit.visible = true
	action_button.visible = true
	
	pilot_name_label.visible = false
	location_label.visible = false
	progress_label.visible = false
	time_label.visible = false
	
	if exists:
		var pilot_name = slot_data.get("pilot_name", "Без имени")
		status_label.text = "Занят: %s" % pilot_name
	else:
		status_label.text = "Пустой слот"
	
	name_prompt_label.text = "Введите имя пилота"
	action_button.text = "Подтвердить"
	action_button.disabled = false


# _setup_continue_mode — «настроить режим продолжения»: показывает данные сохранения или пустоту.
func _setup_continue_mode(exists: bool) -> void:
	name_prompt_label.visible = false
	name_line_edit.visible = false
	
	status_label.visible = true
	pilot_name_label.visible = true
	location_label.visible = true
	progress_label.visible = true
	time_label.visible = true
	action_button.visible = true
	
	if not exists:
		status_label.text = "Пустой слот"
		pilot_name_label.text = ""
		location_label.text = ""
		progress_label.text = ""
		time_label.text = ""
		action_button.text = "Загрузить"
		action_button.disabled = true
		return
	
	var pilot_name = slot_data.get("pilot_name", "Без имени")
	var location_name = slot_data.get("current_adventure_id", "Неизвестно")
	var completed = slot_data.get("completed_quests_count", 0)
	var play_time_seconds = slot_data.get("play_time_seconds", 0)
	
	status_label.text = "Сохранение найдено"
	pilot_name_label.text = "Пилот: %s" % pilot_name
	location_label.text = "Локация: %s" % location_name
	progress_label.text = "Квестов пройдено: %d" % completed
	time_label.text = "Время в игре: %s" % _format_play_time(play_time_seconds)
	
	action_button.text = "Загрузить"
	action_button.disabled = false


# _format_play_time — «форматировать игровое время»: переводит секунды в строку ЧЧ:ММ.
func _format_play_time(total_seconds: int) -> String:
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	return "%02d:%02d" % [hours, minutes]


# _on_action_button_pressed — «нажата кнопка действия»: отправляет создание или загрузку слота.
func _on_action_button_pressed() -> void:
	if mode == "new_game":
		var pilot_name = name_line_edit.text.strip_edges()
		if pilot_name.is_empty():
			return
		new_game_requested.emit(slot_id, pilot_name)
	else:
		if not slot_data.get("exists", false):
			return
		continue_requested.emit(slot_id)
