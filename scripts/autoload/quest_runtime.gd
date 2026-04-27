extends Node

# =========================================================
# QUEST RUNTIME
# =========================================================
# Этот autoload хранит состояние ТЕКУЩЕГО квеста в корабельной сцене.
#
# Важно:
# - состояние квеста не живет внутри окна TextQuest
# - окно можно закрыть и потом открыть снова
# - прогресс останется здесь
#
# Эта версия намеренно простая:
# она хранит состояние только текущего активного квеста,
# что идеально подходит под твою текущую структуру "одна локация = один квест".
# =========================================================

# Сигнал изменения состояния квеста: корабельная сцена может обновить кнопки/индикаторы.
signal state_changed

# ID текущего приключения/локации: используется, чтобы понимать, какой квест активен.
var adventure_id: String = ""

# Путь к текущему JSON-квесту: TextQuest загружает из него структуру узлов и выборов.
var quest_path: String = ""

# Был ли квест уже начат: отделяет новый запуск от продолжения.
var started: bool = false

# Был ли квест завершен полностью: после завершения продолжение уже недоступно.
var completed: bool = false

# ID текущего узла, на котором игрок сейчас находится; отсюда продолжаем после закрытия окна.
var current_node_id: String = ""


# setup_for_adventure — «настроить для приключения»: сбрасывает runtime под новый JSON-квест.
func setup_for_adventure(new_adventure_id: String, new_quest_path: String) -> void:
	adventure_id = new_adventure_id
	quest_path = new_quest_path
	started = false
	completed = false
	current_node_id = ""
	state_changed.emit()


# mark_started — «пометить начатым»: фиксирует стартовый узел и включает состояние прогресса.
func mark_started(start_node_id: String) -> void:
	started = true
	completed = false
	current_node_id = start_node_id
	state_changed.emit()


# update_current_node — «обновить текущий узел»: запоминает, где игрок находится в квесте.
func update_current_node(node_id: String) -> void:
	current_node_id = node_id
	state_changed.emit()


# mark_completed — «пометить завершенным»: фиксирует финальный узел и закрывает квест.
func mark_completed(final_node_id: String) -> void:
	started = true
	completed = true
	current_node_id = final_node_id
	state_changed.emit()


# can_start — «можно стартовать»: разрешает новый запуск только до начала и завершения.
func can_start() -> bool:
	return not started and not completed


# can_continue — «можно продолжить»: проверяет начатый, незавершенный квест с текущим узлом.
func can_continue() -> bool:
	return started and not completed and current_node_id != ""


# is_completed — «завершен»: короткая проверка финального состояния квеста.
func is_completed() -> bool:
	return completed


# is_in_progress — «в процессе»: показывает, что квест начат, но еще не завершен.
func is_in_progress() -> bool:
	return started and not completed
