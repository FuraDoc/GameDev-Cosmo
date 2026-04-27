extends Control

# ─────────────────────────────────────────────
# СЛОИ
# ─────────────────────────────────────────────
# Слой космоса: фон приключения, параллакс и перископ работают через него.
@onready var space_layer    = $SpaceLayer

# Слой кокпита: основная текстура корабля, к которой привязаны предметы.
@onready var cockpit_layer  = $CockpitLayer

# Слой оборудования: активные модули корабля поверх кокпита.
@onready var hardware_layer = $HardwareLayer

# Слой интерьера: установленные растения и декор внутри кокпита.
@onready var interior_layer = $InteriorLayer

# Слой питомцев: активный питомец в выбранной зоне корабля.
@onready var pet_layer      = $PetLayer

# Слой передней панели: дефолтная панель или активный module_panel.
@onready var panel_layer    = $PanelLayer

# Оверлей перископа — создаётся динамически в setup_periscope_overlay()
var periscope_overlay: ColorRect

# ─────────────────────────────────────────────
# ВНЕШНИЕ КОНТРОЛЛЕРЫ
# ─────────────────────────────────────────────
const ShipModuleLayerController    = preload("res://scripts/ship/ship_module_layer_controller.gd")
const ShipPetLayerController       = preload("res://scripts/ship/ship_pet_layer_controller.gd")
const ShipDebugPositioningController = preload("res://scripts/ship/ship_debug_positioning_controller.gd")

# Контроллер модулей: создает и позиционирует hardware_layer.
var module_layer_controller := ShipModuleLayerController.new()

# Контроллер питомцев: выбирает зону и позиционирует pet_layer.
var pet_layer_controller    := ShipPetLayerController.new()

# Общий debug-контроллер ручного позиционирования ship-слоев.
var debug_controller        := ShipDebugPositioningController.new()

# ─────────────────────────────────────────────
# ПУТИ К ТЕКСТУРАМ
# ─────────────────────────────────────────────
# Путь к основной текстуре кокпита.
var cockpit_path       := "res://assets/cockpits/cockpit ultrawide clear 1.02.png"

# Путь к дефолтной передней панели, если module_panel не установлен.
var default_panel_path := "res://assets/items/frontpanel/frontpanel01.png"

# ─────────────────────────────────────────────
# ТЕКСТУРЫ
# ─────────────────────────────────────────────
# Загруженная текстура кокпита.
var cockpit_texture: Texture2D

# Загруженная текстура текущей передней панели.
var panel_texture:   Texture2D

# Загруженная текстура космоса текущего приключения.
var space_texture:   Texture2D

# ID активного модуля передней панели (пустая строка = панель по умолчанию)
var active_panel_module_id := ""

# ─────────────────────────────────────────────
# ПАРАЛЛАКС / ВЗГЛЯД
# ─────────────────────────────────────────────

# Насколько сильно слои реагируют на движение мыши (параллакс)
const PARALLAX_SPACE   := 0.65  # космос — самый сильный сдвиг
const PARALLAX_COCKPIT := 0.30  # кокпит — средний
const PARALLAX_PANEL   := 0.08  # панель — почти не двигается

# Текущее смещение взгляда после сглаживания.
var look_offset        := Vector2.ZERO

# Целевое смещение взгляда от позиции мыши.
var target_look_offset := Vector2.ZERO

# Максимальное смещение взгляда в пикселях.
var max_look_offset    := Vector2(140, 85)

# Скорость сглаживания движения камеры и зума.
var motion_smoothness  := 5.0

# ─────────────────────────────────────────────
# ЗУМ
# ─────────────────────────────────────────────

# Шаг зума за одно прокручивание колёсика
const ZOOM_STEP := 0.12

# Коэффициенты влияния зума на каждый слой
const ZOOM_SCALE_SPACE   := 0.1   # небольшое увеличение космоса
const ZOOM_SCALE_COCKPIT := 0.28  # кокпит увеличивается заметно
const ZOOM_SCALE_PANEL   := 0.20  # панель чуть меньше

# Вертикальное смещение космоса (отрицательное = вверх)
const SPACE_VERTICAL_OFFSET := -150.0

# Смещение слоёв по Y при зуме
const ZOOM_SHIFT_SPACE   := -5.0   # космос уходит вверх
const ZOOM_SHIFT_COCKPIT := 40.0   # кокпит опускается
const ZOOM_SHIFT_PANEL   := 200.0  # панель уезжает вниз

# Текущий уровень зума после сглаживания.
var zoom_level        := 0.0

# Целевой уровень зума от колеса мыши.
var target_zoom_level := 0.0

# Минимальный обычный зум.
var min_zoom_level    := 0.0

# Максимальный обычный зум.
var max_zoom_level    := 4.5

# ─────────────────────────────────────────────
# ПЕРИСКОП
# ─────────────────────────────────────────────
# Шаг зума перископа за прокрутку колеса.
const PERISCOPE_ZOOM_STEP      := 0.15

# Минимальный зум перископа.
const PERISCOPE_MIN_ZOOM       := 1.0

# Максимальный зум перископа.
const PERISCOPE_MAX_ZOOM       := 3.0

# Запас cover-масштаба перископа, чтобы не было краев.
const PERISCOPE_SCALE_OVERDRAW := 1.02

# Активен ли режим перископа.
var periscope_active              := false

# Текущий зум перископа после сглаживания.
var periscope_zoom                := 1.0

# Целевой зум перископа.
var target_periscope_zoom         := 1.0

# Текущее смещение панорамирования перископа.
var periscope_pan_offset          := Vector2.ZERO

# Целевое смещение панорамирования перископа.
var target_periscope_pan_offset   := Vector2.ZERO

# ─────────────────────────────────────────────
# ПОВОРОТ КОРАБЛЯ (ПКМ + мышь)
# ─────────────────────────────────────────────
# Включатель поворота корабля ПКМ: сейчас выключен, чтобы не мешать основному режиму.
const SHIP_TURNING_ENABLED := false

# Идет ли сейчас drag-поворот корабля.
var is_turning_ship       := false

# Текущее смещение корабля при повороте.
var ship_offset           := Vector2.ZERO

# Целевое смещение корабля при повороте.
var target_ship_offset    := Vector2.ZERO

# Максимальное смещение корабля при повороте.
var max_ship_offset       := Vector2(700, 420)

# Чувствительность drag-поворота.
var ship_turn_sensitivity := 0.2

# Сглаживание смещения корабля.
var ship_motion_smoothness := 2.0

# Последняя позиция мыши для вычисления delta при ПКМ.
var last_mouse_position   := Vector2.ZERO

# ─────────────────────────────────────────────
# ВИБРАЦИЯ ДВИГАТЕЛЯ
# ─────────────────────────────────────────────

# Базовый масштаб текстур с небольшим запасом (чтобы не было чёрных краёв)
const SCALE_OVERDRAW_SPACE   := 0.9   # запас для космоса
const SCALE_OVERDRAW_COCKPIT := 1.05  # запас для кокпита
const SCALE_OVERDRAW_PANEL   := 1.02  # запас для панели

# Вертикальное смещение панели от нижнего края экрана
const PANEL_BOTTOM_OFFSET := 110.0

# Таймер вибрации двигателя: идет вперед каждый кадр.
var engine_vibration_time        := 0.0

# Базовая сила вибрации передней панели.
var engine_vibration_strength    := 0.02

# Дополнительная вибрация при повороте корабля.
var engine_vibration_turn_bonus  := 0.02  # доп. вибрация при повороте

# Количество предметов интерьера ship-вида.
const INTERIOR_ITEM_COUNT := 40

# Визуальные данные интерьера в кокпите: texture_path, зона, anchor_pos и size_ratio.
var interior_visual_data := {
	"interior_plant_001": {"texture_path": "res://assets/items/interior/plant001.png", "zone": 1, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_002": {"texture_path": "res://assets/items/interior/plant002.png", "zone": 2, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_003": {"texture_path": "res://assets/items/interior/plant003.png", "zone": 3, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_004": {"texture_path": "res://assets/items/interior/plant004.png", "zone": 4, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_005": {"texture_path": "res://assets/items/interior/plant005.png", "zone": 5, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_006": {"texture_path": "res://assets/items/interior/plant006.png", "zone": 6, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_007": {"texture_path": "res://assets/items/interior/plant007.png", "zone": 7, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_008": {"texture_path": "res://assets/items/interior/plant008.png", "zone": 8, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_009": {"texture_path": "res://assets/items/interior/plant009.png", "zone": 1, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_010": {"texture_path": "res://assets/items/interior/plant010.png", "zone": 2, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_011": {"texture_path": "res://assets/items/interior/plant011.png", "zone": 1, "anchor_pos": Vector2(0.31, 0.58), "size_ratio": Vector2(0.04, 0.07)},
	"interior_plant_012": {"texture_path": "res://assets/items/interior/plant012.png", "zone": 4, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_013": {"texture_path": "res://assets/items/interior/plant013.png", "zone": 5, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_014": {"texture_path": "res://assets/items/interior/plant014.png", "zone": 6, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_015": {"texture_path": "res://assets/items/interior/plant015.png", "zone": 7, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.04, 0.07)},
	"interior_plant_016": {"texture_path": "res://assets/items/interior/plant016.png", "zone": 8, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_017": {"texture_path": "res://assets/items/interior/plant017.png", "zone": 1, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_018": {"texture_path": "res://assets/items/interior/plant018.png", "zone": 2, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_019": {"texture_path": "res://assets/items/interior/plant019.png", "zone": 3, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_020": {"texture_path": "res://assets/items/interior/plant020.png", "zone": 4, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_021": {"texture_path": "res://assets/items/interior/plant021.png", "zone": 5, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_022": {"texture_path": "res://assets/items/interior/plant022.png", "zone": 6, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_023": {"texture_path": "res://assets/items/interior/plant023.png", "zone": 7, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_024": {"texture_path": "res://assets/items/interior/plant024.png", "zone": 8, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_025": {"texture_path": "res://assets/items/interior/plant025.png", "zone": 1, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_026": {"texture_path": "res://assets/items/interior/plant026.png", "zone": 2, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_027": {"texture_path": "res://assets/items/interior/plant027.png", "zone": 3, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_028": {"texture_path": "res://assets/items/interior/plant028.png", "zone": 4, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_029": {"texture_path": "res://assets/items/interior/plant029.png", "zone": 5, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_030": {"texture_path": "res://assets/items/interior/plant030.png", "zone": 6, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_031": {"texture_path": "res://assets/items/interior/plant031.png", "zone": 7, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_032": {"texture_path": "res://assets/items/interior/plant032.png", "zone": 8, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_033": {"texture_path": "res://assets/items/interior/plant033.png", "zone": 1, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_034": {"texture_path": "res://assets/items/interior/plant034.png", "zone": 2, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_035": {"texture_path": "res://assets/items/interior/plant035.png", "zone": 3, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_036": {"texture_path": "res://assets/items/interior/plant036.png", "zone": 4, "anchor_pos": Vector2(0.712, 0.354), "size_ratio": Vector2(0.047, 0.084)},
	"interior_plant_037": {"texture_path": "res://assets/items/interior/plant037.png", "zone": 5, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_038": {"texture_path": "res://assets/items/interior/plant038.png", "zone": 6, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_039": {"texture_path": "res://assets/items/interior/plant039.png", "zone": 7, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)},
	"interior_plant_040": {"texture_path": "res://assets/items/interior/plant040.png", "zone": 8, "anchor_pos": Vector2(0.5, 0.5), "size_ratio": Vector2(0.5, 0.5)}
}

# ─────────────────────────────────────────────
# ДАННЫЕ ПАНЕЛЕЙ
# ─────────────────────────────────────────────
# Визуальные данные передних панелей: texture_path, anchor_pos и scale для module_panel.
var panel_visual_data := {
	"module_panel_001": {"texture_path": "res://assets/items/frontpanel/frontpanel01.png", "anchor_pos": Vector2(0.5,   0.824), "scale": 0.45},
	"module_panel_002": {"texture_path": "res://assets/items/frontpanel/frontpanel02.png", "anchor_pos": Vector2(0.52,  0.805), "scale": 0.74},
	"module_panel_003": {"texture_path": "res://assets/items/frontpanel/frontpanel03.png", "anchor_pos": Vector2(0.5,   0.767), "scale": 0.508},
	"module_panel_004": {"texture_path": "res://assets/items/frontpanel/frontpanel04.png", "anchor_pos": Vector2(0.51,  0.795), "scale": 0.53},
	"module_panel_005": {"texture_path": "res://assets/items/frontpanel/frontpanel05.png", "anchor_pos": Vector2(0.51,  0.806), "scale": 0.663},
	"module_panel_006": {"texture_path": "res://assets/items/frontpanel/frontpanel06.png", "anchor_pos": Vector2(0.51,  0.853), "scale": 0.546},
	"module_panel_007": {"texture_path": "res://assets/items/frontpanel/frontpanel07.png", "anchor_pos": Vector2(0.511, 0.798), "scale": 0.53},
	"module_panel_008": {"texture_path": "res://assets/items/frontpanel/frontpanel08.png", "anchor_pos": Vector2(0.502, 0.809), "scale": 0.53},
}


# ─────────────────────────────────────────────
# LIFECYCLE
# ─────────────────────────────────────────────

# _ready — «готово»: загружает слои, создает визуалы и подключает сигналы PlayerState.
func _ready() -> void:
	PlayerState.apply_default_modules(false)
	load_static_layers()
	refresh_panel_texture()
	setup_periscope_overlay()

	# Инициализируем слои через внешние контроллеры
	module_layer_controller.refresh_items(hardware_layer, clear_layer)
	refresh_interior_items()  # внутри уже вызывает update_interior_layer()
	pet_layer_controller.refresh_items(pet_layer, clear_layer)

	# Подписываемся на сигналы PlayerState (если они объявлены)
	if PlayerState.has_signal("modules_changed"):
		PlayerState.modules_changed.connect(_on_player_modules_changed)

	if PlayerState.has_signal("interior_changed"):
		PlayerState.interior_changed.connect(_on_player_interior_changed)

	if PlayerState.has_signal("pets_changed"):
		PlayerState.pets_changed.connect(_on_player_pets_changed)

	# update_layers() не вызываем здесь явно:
	# refresh_interior_items() → update_interior_layer(),
	# а полный update_layers() запустится в первом _process()


# _process — «процесс»: сглаживает движение/зум, обновляет таймер вибрации и все слои.
func _process(delta: float) -> void:
	update_input_target()

	# Плавная интерполяция всех динамических параметров
	look_offset          = look_offset.lerp(target_look_offset, delta * motion_smoothness)
	zoom_level           = lerp(zoom_level, target_zoom_level, delta * motion_smoothness)
	periscope_zoom       = lerp(periscope_zoom, target_periscope_zoom, delta * motion_smoothness)
	periscope_pan_offset = periscope_pan_offset.lerp(target_periscope_pan_offset, delta * motion_smoothness)
	ship_offset          = ship_offset.lerp(target_ship_offset, delta * ship_motion_smoothness)

	engine_vibration_time += delta

	update_layers()


# _input — «ввод»: обрабатывает мышь, движение мыши и debug-клавиши.
func _input(event: InputEvent) -> void:
	# ── Обработка мыши ──
	if event is InputEventMouseButton:
		_handle_mouse_button(event)

	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

	# ── Обработка клавиатуры (только в debug-режиме) ──
	if debug_controller.enabled and event is InputEventKey and event.pressed:
		_handle_debug_key(event)


# _handle_mouse_button — «обработать кнопку мыши»: колесо меняет зум, ПКМ включает поворот.
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		if periscope_active:
			target_periscope_zoom = clamp(
				target_periscope_zoom + PERISCOPE_ZOOM_STEP,
				PERISCOPE_MIN_ZOOM, PERISCOPE_MAX_ZOOM
			)
		else:
			target_zoom_level = clamp(
				target_zoom_level + ZOOM_STEP,
				min_zoom_level, max_zoom_level
			)

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		if periscope_active:
			target_periscope_zoom = clamp(
				target_periscope_zoom - PERISCOPE_ZOOM_STEP,
				PERISCOPE_MIN_ZOOM, PERISCOPE_MAX_ZOOM
			)
		else:
			target_zoom_level = clamp(
				target_zoom_level - ZOOM_STEP,
				min_zoom_level, max_zoom_level
			)

	elif event.button_index == MOUSE_BUTTON_RIGHT and not periscope_active:
		if event.pressed:
			is_turning_ship = SHIP_TURNING_ENABLED
			last_mouse_position = event.position
		else:
			is_turning_ship = false


# _handle_mouse_motion — «обработать движение мыши»: считает смещение корабля при ПКМ.
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not is_turning_ship or periscope_active:
		return

	var delta_move := event.position - last_mouse_position
	last_mouse_position = event.position

	target_ship_offset += delta_move * ship_turn_sensitivity
	target_ship_offset.x = clamp(target_ship_offset.x, -max_ship_offset.x, max_ship_offset.x)
	target_ship_offset.y = clamp(target_ship_offset.y, -max_ship_offset.y, max_ship_offset.y)


# _handle_debug_key — «обработать debug-клавишу»: переключает и двигает выбранный ship-объект.
func _handle_debug_key(event: InputEventKey) -> void:
	if debug_controller.selected_layer == "interior.ship":
		if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			debug_controller.cycle_ship_interior_item(interior_visual_data, -1)
			refresh_interior_items()
			return

		if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS or event.keycode == KEY_KP_ADD:
			debug_controller.cycle_ship_interior_item(interior_visual_data, 1)
			refresh_interior_items()
			return

	if event.keycode == KEY_P:
		debug_controller.print_selected_data(
			module_layer_controller,
			pet_layer_controller,
			interior_visual_data,
			panel_visual_data
		)
		return

	if debug_controller.selected_layer == "pet" and event.keycode == KEY_O:
		pet_layer_controller.cycle_active_zone(debug_controller.selected_item_id)
		pet_layer_controller.refresh_items(pet_layer, clear_layer)
		pet_layer_controller.update_layer(pet_layer, cockpit_layer, cockpit_texture)
		print(
			"Pet zone switched: ",
			debug_controller.selected_item_id,
			" -> ",
			pet_layer_controller.active_pet_zone_indices.get(debug_controller.selected_item_id, 0)
		)
		return

	debug_controller.handle_input(
		event,
		module_layer_controller,
		pet_layer_controller,
		interior_visual_data,
		panel_visual_data,
		hardware_layer,
		pet_layer,
		cockpit_layer,
		cockpit_texture,
		clear_layer,
		refresh_interior_items,
		update_interior_layer,
		update_panel_layer_from_current_view
	)


# ─────────────────────────────────────────────
# ЗАГРУЗКА СЛОЁВ
# ─────────────────────────────────────────────

# load_static_layers — «загрузить статичные слои»: загружает кокпит и дефолтную панель.
func load_static_layers() -> void:
	cockpit_texture = load(cockpit_path)
	panel_texture   = load(default_panel_path)

	if cockpit_texture == null:
		push_error("Не удалось загрузить кокпит: '%s'" % cockpit_path)
	else:
		cockpit_layer.texture = cockpit_texture

	if panel_texture == null:
		push_error("Не удалось загрузить панель: '%s'" % default_panel_path)
	else:
		panel_layer.texture  = panel_texture
		panel_layer.visible  = true


# set_space_background — «задать фон космоса»: загружает фон текущего приключения.
func set_space_background(background_path: String) -> void:
	var texture = load(background_path)

	if texture == null:
		push_error("Не удалось загрузить фон: '%s'" % background_path)
		return

	space_texture       = texture
	space_layer.texture = texture


# refresh_panel_texture — «обновить текстуру панели»: берет active module_panel из PlayerState.
func refresh_panel_texture() -> void:
	active_panel_module_id = PlayerState.get_active_module_for_zone("panel")

	if active_panel_module_id.is_empty():
		panel_texture = load(default_panel_path)
	else:
		var panel_data: Dictionary = panel_visual_data.get(active_panel_module_id, {})
		var custom_path := String(panel_data.get("texture_path", ""))
		panel_texture = load(custom_path)

		if panel_texture == null:
			push_error("Не удалось загрузить текстуру передней панели: '%s'" % custom_path)
			active_panel_module_id = ""
			panel_texture = load(default_panel_path)

	panel_layer.texture = panel_texture
	panel_layer.visible = not periscope_active


# setup_periscope_overlay — «настроить оверлей перископа»: создает прозрачный слой и линии.
func setup_periscope_overlay() -> void:
	periscope_overlay = ColorRect.new()
	periscope_overlay.name        = "PeriscopeOverlay"
	periscope_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	periscope_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	periscope_overlay.color       = Color(0.75, 0.9, 1.0, 0.08)
	periscope_overlay.visible     = false
	add_child(periscope_overlay)

	# Горизонтальная прицельная линия
	var horizontal_line        := ColorRect.new()
	horizontal_line.anchor_left   = 0.0
	horizontal_line.anchor_top    = 0.5
	horizontal_line.anchor_right  = 1.0
	horizontal_line.anchor_bottom = 0.5
	horizontal_line.offset_top    = -1.0
	horizontal_line.offset_bottom = 1.0
	horizontal_line.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	horizontal_line.color         = Color(0.9, 0.97, 1.0, 0.22)
	periscope_overlay.add_child(horizontal_line)

	# Вертикальная прицельная линия
	var vertical_line          := ColorRect.new()
	vertical_line.anchor_left   = 0.5
	vertical_line.anchor_top    = 0.0
	vertical_line.anchor_right  = 0.5
	vertical_line.anchor_bottom = 1.0
	vertical_line.offset_left   = -1.0
	vertical_line.offset_right  = 1.0
	vertical_line.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	vertical_line.color         = Color(0.9, 0.97, 1.0, 0.22)
	periscope_overlay.add_child(vertical_line)


# set_periscope_active — «задать активность перископа»: включает режим и сбрасывает камеру.
func set_periscope_active(active: bool) -> void:
	if periscope_active == active:
		return

	periscope_active = active
	is_turning_ship  = false

	# Сброс всех смещений
	ship_offset                 = Vector2.ZERO
	target_ship_offset          = Vector2.ZERO
	look_offset                 = Vector2.ZERO
	target_look_offset          = Vector2.ZERO
	periscope_pan_offset        = Vector2.ZERO
	target_periscope_pan_offset = Vector2.ZERO
	periscope_zoom              = 1.0
	target_periscope_zoom       = 1.0

	# В режиме перископа скрываем все слои кроме космоса
	cockpit_layer.visible         = not active
	hardware_layer.visible        = not active
	interior_layer.visible        = not active
	pet_layer.visible             = not active
	panel_layer.visible           = not active
	periscope_overlay.visible     = active


# is_periscope_active — «перископ активен»: возвращает текущее состояние режима.
func is_periscope_active() -> bool:
	return periscope_active


# ─────────────────────────────────────────────
# ОБНОВЛЕНИЕ СЛОЁВ
# ─────────────────────────────────────────────

# update_input_target — «обновить цель ввода»: считает look_offset или pan перископа от мыши.
func update_input_target() -> void:
	if periscope_active:
		update_periscope_pan_target()
		return

	if is_turning_ship:
		target_look_offset = Vector2.ZERO
		return

	var viewport_size := get_viewport_rect().size
	var mouse_pos     := get_viewport().get_mouse_position()

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# Нормализуем позицию мыши в диапазон [-1, 1]
	var normalized := Vector2(
		(mouse_pos.x / viewport_size.x) * 2.0 - 1.0,
		(mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	)
	normalized.x = clamp(normalized.x, -1.0, 1.0)
	normalized.y = clamp(normalized.y, -1.0, 1.0)

	target_look_offset = normalized * max_look_offset


# update_periscope_pan_target — «обновить цель панорамирования»: ограничивает сдвиг перископа.
func update_periscope_pan_target() -> void:
	var viewport_size := get_viewport_rect().size
	var mouse_pos     := get_viewport().get_mouse_position()

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or space_texture == null:
		target_periscope_pan_offset = Vector2.ZERO
		return

	# Нормализуем позицию мыши в диапазон [-1, 1]
	var normalized := Vector2(
		(mouse_pos.x / viewport_size.x) * 2.0 - 1.0,
		(mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	)
	normalized.x = clamp(normalized.x, -1.0, 1.0)
	normalized.y = clamp(normalized.y, -1.0, 1.0)

	var pan_limits := get_periscope_pan_limits(viewport_size)
	target_periscope_pan_offset = normalized * pan_limits


# update_layers — «обновить слои»: главный расчет позиций космоса, кокпита, предметов и панели.
func update_layers() -> void:
	var viewport_size := get_viewport_rect().size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var screen_center := viewport_size * 0.5

	update_space_layer(viewport_size, screen_center)
	update_cockpit_layer(viewport_size, screen_center)
	module_layer_controller.update_layer(hardware_layer, cockpit_layer, cockpit_texture)
	update_interior_layer()
	pet_layer_controller.update_layer(pet_layer, cockpit_layer, cockpit_texture)
	update_panel_layer(viewport_size, screen_center)


# update_space_layer — «обновить слой космоса»: применяет cover, параллакс, зум и перископ.
func update_space_layer(viewport_size: Vector2, screen_center: Vector2) -> void:
	if space_texture == null:
		return

	var tex_size := space_texture.get_size()

	if periscope_active:
		# В режиме перископа: масштаб по покрытию + зум + панорамирование
		var periscope_scale := cover_scale(tex_size, viewport_size) * PERISCOPE_SCALE_OVERDRAW
		var periscope_size  := tex_size * periscope_scale * periscope_zoom
		space_layer.size     = periscope_size
		space_layer.position = screen_center - periscope_size * 0.5 - periscope_pan_offset
		return

	# Обычный режим: масштаб + параллакс + зум + сдвиг корабля
	var scale_value := cover_scale(tex_size, viewport_size) * SCALE_OVERDRAW_SPACE
	scale_value     *= (1.0 + zoom_level * ZOOM_SCALE_SPACE)
	var final_size  := tex_size * scale_value

	space_layer.size     = final_size
	space_layer.position = (
		screen_center - final_size * 0.5
		- look_offset * PARALLAX_SPACE
		- ship_offset
		+ Vector2(0.0, ZOOM_SHIFT_SPACE * zoom_level)
		+ Vector2(0.0, SPACE_VERTICAL_OFFSET)
	)


# update_cockpit_layer — «обновить слой кокпита»: масштабирует кокпит и применяет параллакс/зум.
func update_cockpit_layer(viewport_size: Vector2, screen_center: Vector2) -> void:
	if cockpit_texture == null:
		return

	var tex_size    := cockpit_texture.get_size()
	var scale_value := cover_scale(tex_size, viewport_size) * SCALE_OVERDRAW_COCKPIT
	scale_value     *= (1.0 + zoom_level * ZOOM_SCALE_COCKPIT)
	var final_size  := tex_size * scale_value

	cockpit_layer.size     = final_size
	cockpit_layer.position = (
		screen_center - final_size * 0.5
		- look_offset * PARALLAX_COCKPIT
		+ Vector2(0.0, ZOOM_SHIFT_COCKPIT * zoom_level)
	)


# refresh_interior_items — «обновить предметы интерьера»: пересоздает TextureRect из PlayerState.
func refresh_interior_items() -> void:
	clear_layer(interior_layer)
	interior_layer.z_index = 0
	panel_layer.z_index = 20
	pet_layer.z_index = 10

	for item_id in PlayerState.get_installed_interior_items():
		var data = interior_visual_data.get(item_id, null)
		if data == null:
			push_error("Нет interior visual data для item_id: '%s'" % item_id)
			continue

		var texture = load(data["texture_path"])
		if texture == null:
			push_error("Не удалось загрузить интерьерную текстуру: '%s'" % data["texture_path"])
			continue

		var rect := TextureRect.new()
		rect.name         = item_id
		rect.texture      = texture
		rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.visible      = true
		rect.z_index      = int(data.get("zone", 1))
		interior_layer.add_child(rect)

	update_interior_layer()


# update_interior_layer — «обновить слой интерьера»: привязывает предметы к размеру кокпита.
func update_interior_layer() -> void:
	interior_layer.position = cockpit_layer.position
	interior_layer.size     = cockpit_layer.size

	for child in interior_layer.get_children():
		if not child is TextureRect:
			continue

		var data = interior_visual_data.get(child.name, null)
		if data == null or child.texture == null:
			continue

		var anchor_pos: Vector2 = data["anchor_pos"]
		var size_ratio: Vector2 = data["size_ratio"]
		var item_size: Vector2  = _calculate_preserved_item_size(
			child.texture,
			interior_layer.size * size_ratio
		)

		child.size     = item_size
		child.position = Vector2(
			interior_layer.size.x * anchor_pos.x - item_size.x * 0.5,
			interior_layer.size.y * anchor_pos.y - item_size.y * 0.5
		)


# update_panel_layer — «обновить слой панели»: ставит дефолтную или модульную переднюю панель.
func update_panel_layer(viewport_size: Vector2, screen_center: Vector2) -> void:
	if panel_texture == null:
		return

	var tex_size    := panel_texture.get_size()
	var scale_value := fit_width_scale(tex_size, viewport_size) * SCALE_OVERDRAW_PANEL
	scale_value     *= (1.0 + zoom_level * ZOOM_SCALE_PANEL)

	# Якорная точка по умолчанию (для панели без модуля)
	var panel_anchor := Vector2(0.5, 0.755)

	if not active_panel_module_id.is_empty():
		var panel_data: Dictionary = panel_visual_data.get(active_panel_module_id, {})
		panel_anchor  = panel_data.get("anchor_pos", panel_anchor)
		scale_value  *= float(panel_data.get("scale", 1.0))

	var final_size := tex_size * scale_value

	panel_layer.size = final_size

	var base_pos: Vector2

	if active_panel_module_id.is_empty():
		# Панель по умолчанию — прижата к нижнему краю экрана
		base_pos = Vector2(
			screen_center.x - final_size.x * 0.5,
			viewport_size.y - final_size.y + PANEL_BOTTOM_OFFSET
		)
	else:
		# Модульная панель — позиционируется по якорной точке
		var anchor_screen := Vector2(
			viewport_size.x * panel_anchor.x,
			viewport_size.y * panel_anchor.y
		)
		base_pos = anchor_screen - final_size * 0.5

	# Вибрация: sin/cos с разными частотами для органичного движения
	var vibration_strength := engine_vibration_strength
	if is_turning_ship:
		vibration_strength += engine_vibration_turn_bonus

	var vibration := Vector2(
		sin(engine_vibration_time * 1.0) * vibration_strength,
		cos(engine_vibration_time * 2.0) * vibration_strength * 0.7
	)

	panel_layer.position = (
		base_pos
		- look_offset * PARALLAX_PANEL
		+ Vector2(0.0, ZOOM_SHIFT_PANEL * zoom_level)
		+ vibration
	)


# update_panel_layer_from_current_view — «обновить панель из текущего вида»: берет текущий viewport.
func update_panel_layer_from_current_view() -> void:
	var viewport_size := get_viewport_rect().size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	update_panel_layer(viewport_size, viewport_size * 0.5)


# ─────────────────────────────────────────────
# УТИЛИТЫ
# ─────────────────────────────────────────────

# clear_layer — «очистить слой»: удаляет все дочерние узлы Control-слоя.
func clear_layer(layer: Control) -> void:
	for child in layer.get_children():
		child.free()


# cover_scale — «масштаб cover»: текстура заполняет viewport без черных полос.
func cover_scale(texture_size: Vector2, viewport_size: Vector2) -> float:
	return max(
		viewport_size.x / texture_size.x,
		viewport_size.y / texture_size.y
	)


# fit_width_scale — «масштаб по ширине»: растягивает текстуру по ширине viewport.
func fit_width_scale(texture_size: Vector2, viewport_size: Vector2) -> float:
	return viewport_size.x / texture_size.x


# get_periscope_pan_limits — «получить пределы панорамирования»: считает доступный сдвиг.
func get_periscope_pan_limits(viewport_size: Vector2) -> Vector2:
	if space_texture == null:
		return Vector2.ZERO

	var tex_size   := space_texture.get_size()
	var base_scale := cover_scale(tex_size, viewport_size) * PERISCOPE_SCALE_OVERDRAW
	var final_size := tex_size * base_scale * target_periscope_zoom

	return Vector2(
		max((final_size.x - viewport_size.x) * 0.5, 0.0),
		max((final_size.y - viewport_size.y) * 0.5, 0.0)
	)


# _calculate_preserved_item_size — «рассчитать сохраненный размер»: вписывает текстуру без искажения.
func _calculate_preserved_item_size(texture: Texture2D, max_size: Vector2) -> Vector2:
	if texture == null:
		return max_size

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return max_size

	var scale_value: float = min(max_size.x / texture_size.x, max_size.y / texture_size.y)
	return texture_size * scale_value


# ─────────────────────────────────────────────
# ОБРАБОТЧИКИ СИГНАЛОВ
# ─────────────────────────────────────────────

# _on_player_modules_changed — «изменились модули игрока»: обновляет hardware и переднюю панель.
func _on_player_modules_changed() -> void:
	module_layer_controller.refresh_items(hardware_layer, clear_layer)
	module_layer_controller.update_layer(hardware_layer, cockpit_layer, cockpit_texture)
	refresh_panel_texture()
	update_panel_layer_from_current_view()


# _on_player_interior_changed — «изменился интерьер игрока»: пересоздает предметы интерьера.
func _on_player_interior_changed() -> void:
	refresh_interior_items()


# _on_player_pets_changed — «изменились питомцы игрока»: пересоздает активного питомца.
func _on_player_pets_changed() -> void:
	pet_layer_controller.refresh_items(pet_layer, clear_layer)
	pet_layer_controller.update_layer(pet_layer, cockpit_layer, cockpit_texture)
