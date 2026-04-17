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

signal state_changed

# ID текущего приключения / локации
var adventure_id: String = ""

# Путь к текущему JSON-квесту
var quest_path: String = ""

# Был ли квест уже начат
var started: bool = false

# Был ли квест завершён полностью
var completed: bool = false

# ID текущего узла, на котором игрок сейчас находится
# Если окно закрыли на середине, именно отсюда потом продолжаем.
var current_node_id: String = ""


func setup_for_adventure(new_adventure_id: String, new_quest_path: String) -> void:
	# =========================================================
	# ПОДГОТОВКА СОСТОЯНИЯ ПОД НОВОЕ ПРИКЛЮЧЕНИЕ
	# =========================================================
	#
	# Когда игрок прыгает в новую локацию,
	# у нее должен быть свой новый квест.
	#
	# Значит, старый прогресс полностью сбрасываем
	# и начинаем "чистое" состояние.
	adventure_id = new_adventure_id
	quest_path = new_quest_path
	started = false
	completed = false
	current_node_id = ""
	state_changed.emit()


func mark_started(start_node_id: String) -> void:
	# Помечаем, что квест был запущен.
	started = true
	completed = false
	current_node_id = start_node_id
	state_changed.emit()


func update_current_node(node_id: String) -> void:
	# Сохраняем текущий узел.
	# Это нужно, чтобы потом можно было продолжить.
	current_node_id = node_id
	state_changed.emit()


func mark_completed(final_node_id: String) -> void:
	# Помечаем квест как завершённый.
	started = true
	completed = true
	current_node_id = final_node_id
	state_changed.emit()


func can_start() -> bool:
	# Новый запуск квеста разрешён только если он ещё не стартовал.
	return not started and not completed


func can_continue() -> bool:
	# Продолжать можно только если:
	# - квест уже стартовал
	# - но ещё не завершён
	# - и есть текущий узел
	return started and not completed and current_node_id != ""


func is_completed() -> bool:
	return completed


func is_in_progress() -> bool:
	return started and not completed
