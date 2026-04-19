extends CanvasLayer

signal menu_requested
signal next_adventure_requested
signal text_quest_requested
signal continue_quest_requested
signal cargo_bay_requested

@onready var fade_overlay:     ColorRect = $FadeOverlay
@onready var buttons_root:     Control   = $ButtonsRoot
@onready var windows_root:     Control   = $WindowsRoot

@onready var text_quest_button:     Button = $ButtonsRoot/VBoxContainer/TextQuestButton
@onready var continue_quest_button: Button = $ButtonsRoot/VBoxContainer/ContinueQuestButton
@onready var next_adventure_button: Button = $ButtonsRoot/VBoxContainer/NextAdventureButton
@onready var menu_button:           Button = $ButtonsRoot/VBoxContainer/MenuButton
@onready var cargo_bay_button:      Button = $ButtonsRoot/VBoxContainer/CargoBayButton

var text_quest_scene_path := "res://scenes/text_quest/text_quest.tscn"


func _ready() -> void:
	fade_overlay.color.a = 0.0

	menu_button.pressed.connect(func(): menu_requested.emit())
	next_adventure_button.pressed.connect(func(): next_adventure_requested.emit())
	text_quest_button.pressed.connect(func(): text_quest_requested.emit())
	continue_quest_button.pressed.connect(func(): continue_quest_requested.emit())
	cargo_bay_button.pressed.connect(func(): cargo_bay_requested.emit())

	update_quest_buttons()


func update_quest_buttons() -> void:
	var can_start    := QuestRuntime.can_start()
	var can_continue := QuestRuntime.can_continue()

	text_quest_button.disabled    = not can_start
	continue_quest_button.disabled = not can_continue


func set_main_buttons_enabled(enabled: bool) -> void:
	next_adventure_button.disabled = not enabled
	menu_button.disabled           = not enabled
	cargo_bay_button.disabled      = not enabled

	if enabled:
		update_quest_buttons()
	else:
		text_quest_button.disabled    = true
		continue_quest_button.disabled = true


# ── Квест ──────────────────────────────────────────────

func open_text_quest(path: String, continue_from_runtime: bool = false) -> void:
	if windows_root.has_node("TextQuest"):
		return

	var quest_scene = load(text_quest_scene_path)
	if quest_scene == null:
		push_error("Не удалось загрузить сцену текстового квеста: '%s'" % text_quest_scene_path)
		return

	var quest_instance        = quest_scene.instantiate()
	quest_instance.name       = "TextQuest"
	quest_instance.quest_path = path
	quest_instance.continue_from_runtime = continue_from_runtime

	quest_instance.quest_closed.connect(update_quest_buttons)
	quest_instance.quest_completed.connect(update_quest_buttons)

	windows_root.add_child(quest_instance)
	quest_instance.move_to_front()


# ── Диалог подтверждения ───────────────────────────────

func confirm_next_adventure(message: String, on_confirm: Callable) -> void:
	var dialog                      := ConfirmationDialog.new()
	dialog.title                    = "Подтверждение"
	dialog.dialog_text              = message
	dialog.get_ok_button().text     = "Принять"
	dialog.get_cancel_button().text = "Отклонить"

	dialog.confirmed.connect(func():
		if on_confirm.is_valid():
			on_confirm.call()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())

	windows_root.add_child(dialog)
	dialog.popup_centered()


# ── Fade ───────────────────────────────────────────────

func fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", alpha, duration)
	await tween.finished


func play_transition() -> void:
	await fade_to(1.0, 1.0)
	await get_tree().create_timer(1.0).timeout


func play_fade_in() -> void:
	await fade_to(0.0, 1.0)


# ── HUD ────────────────────────────────────────────────

func set_ship_hud_visible(is_visible: bool) -> void:
	buttons_root.visible = is_visible
