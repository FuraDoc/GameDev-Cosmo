extends Control

# Ссылка на TextureRect с фоновой картинкой
@onready var background_texture = $BackgroundHolder/BackgroundTexture

# Ссылка на черный слой, который затемняет/открывает сцену
@onready var fade_overlay = $FadeOverlay

# Список фоновых изображений
var backgrounds = [
	"res://assets/backgrounds/space/cosmo 17.jpg",
	"res://assets/backgrounds/space/cosmo 18.jpg",
	"res://assets/backgrounds/space/cosmo 16.jpg",
	"res://assets/backgrounds/space/cosmo 21.jpg",
	"res://assets/backgrounds/space/cosmo 5.jpg",
	"res://assets/backgrounds/space/cosmo 6.jpg",
	"res://assets/backgrounds/space/cosmo 7.jpg",
	"res://assets/backgrounds/space/cosmo 8.jpg",
	"res://assets/backgrounds/space/cosmo 9.jpg",
	"res://assets/backgrounds/space/cosmo 10.jpg"
]

# Индекс текущего фона
var current_background_index = 0

# Массив направлений движения.
# Каждый Vector2 задает направление, в котором будет медленно двигаться фон.
var move_directions = [
	Vector2(1, 0),      # слева направо
	Vector2(-1, 0),     # справа налево
	Vector2(0, 1),      # сверху вниз
	Vector2(0, -1),     # снизу вверх
	Vector2(1, 1),      # по диагонали вниз-вправо
	Vector2(-1, 1),     # по диагонали вниз-влево
	Vector2(1, -1),     # по диагонали вверх-вправо
	Vector2(-1, -1),    # по диагонали вверх-влево
	Vector2(0.7, 0.3),  # слабая диагональ
	Vector2(-0.6, 0.4)  # еще один вариант угла
]

# Длительность движения картинки до следующей смены
var move_duration := 5.0

# Длительность затемнения
var fade_out_duration := 1.0

# Длительность осветления
var fade_in_duration := 1.0


func _ready():
	# При старте делаем экран полностью черным
	fade_overlay.color.a = 1.0
	
	# Загружаем первый фон
	show_background(current_background_index)
	
	# Запускаем начальное открытие сцены
	await fade_from_black(2.0)
	
	# Запускаем бесконечный цикл смены фонов
	start_background_loop()


func start_background_loop():
	while true:
		# Запускаем плавное движение текущей картинки
		var move_tween = animate_background(current_background_index)
		
		# Ждем 5 секунд, пока картинка движется
		await get_tree().create_timer(move_duration).timeout
		
		# Затемняем экран за 1 секунду
		await fade_to_black(fade_out_duration)
		
		# Переключаемся на следующий фон
		current_background_index += 1
		if current_background_index >= backgrounds.size():
			current_background_index = 0
		
		# Показываем новый фон
		show_background(current_background_index)
		
		# Осветляем экран обратно за 1 секунду
		await fade_from_black(fade_in_duration)


func show_background(index: int):
	# Загружаем картинку по пути
	var texture = load(backgrounds[index])
	
	# Если картинка не загрузилась - пишем ошибку
	if texture == null:
		push_error("Не удалось загрузить фон: " + backgrounds[index])
		return
	
	# Назначаем текстуру
	background_texture.texture = texture
	
	# В начале каждого нового фона возвращаем картинку в стартовую позицию
	set_background_start_position(index)


func set_background_start_position(index: int):
	# Получаем направление для текущей картинки
	var direction = move_directions[index % move_directions.size()].normalized()
	
	# Размер экрана
	var viewport_size = get_viewport_rect().size
	
	# Запас смещения.
	# Чем больше число, тем сильнее фон сможет "ездить".
	var offset_amount = Vector2(200, 120)
	
	# Ставим картинку в позицию, противоположную движению,
	# чтобы она ехала через экран в выбранную сторону.
	background_texture.position = Vector2(
		-direction.x * offset_amount.x,
		-direction.y * offset_amount.y
	)
	
	# Делаем фон чуть больше экрана, чтобы при сдвиге не было пустых краев
	background_texture.size = viewport_size + offset_amount * 2


func animate_background(index: int) -> Tween:
	# Получаем направление движения для текущей картинки
	var direction = move_directions[index % move_directions.size()].normalized()
	
	# Насколько далеко картинка сместится за весь цикл
	var total_shift = Vector2(200, 120)
	
	# Конечная позиция - в направлении движения
	var target_position = Vector2(
		direction.x * total_shift.x,
		direction.y * total_shift.y
	)
	
	# Создаем tween для плавного движения
	var tween = create_tween()
	tween.tween_property(background_texture, "position", target_position, move_duration)
	
	return tween


func fade_to_black(duration: float) -> void:
	# Плавно затемняем экран
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, duration)
	await tween.finished


func fade_from_black(duration: float) -> void:
	# Плавно убираем затемнение
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, duration)
	await tween.finished
	
