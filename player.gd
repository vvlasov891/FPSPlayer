extends CharacterBody3D

# === НАСТРОЙКИ ===
@export var WALK_SPEED : float = 10.0
@export var JUMP_POWER : float = 15.0
@export var GRAVITY : float = 50.0

# === НАСТРОЙКИ КАМЕРЫ (добавлено) ===
@export var MOUSE_SENSITIVITY : float = 0.002
@export var CAMERA_MIN_ANGLE : float = -60.0
@export var CAMERA_MAX_ANGLE : float = 60.0

var is_falling : bool = false
var fall_timer : float = 0.0
var camera_rotation : Vector2 = Vector2.ZERO  # Добавлено

func _ready():
	print("=== 🎮 ИГРА ЗАПУЩЕНА ===")
	print("Игрок создан на высоте 8 единиц")
	print("Управление мышью добавлено!")
	
	# Захватываем мышь (добавлено)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# ГАРАНТИРОВАННАЯ высота
	global_position = Vector3(0, 8, 0)
	
	# Усиленные настройки физики
	floor_snap_length = 2.0  # Длинное прилипание
	floor_max_angle = deg_to_rad(90)  # Любой угол
	
	# Создаём RayCast если нет
	if not has_node("FloorDetector"):
		var ray = RayCast3D.new()
		ray.name = "FloorDetector"
		ray.enabled = true
		ray.target_position = Vector3(0, -15, 0)  # 15 единиц вниз!
		ray.collide_with_bodies = true
		add_child(ray)
		print("✅ Детектор пола создан")

func _input(event):
	# === ВРАЩЕНИЕ КАМЕРЫ МЫШЬЮ (добавлено) ===
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Поворачиваем игрока по горизонтали (влево-вправо)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		# Наклоняем камеру по вертикали (вверх-вниз)
		camera_rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		camera_rotation.x = clamp(camera_rotation.x, 
			deg_to_rad(CAMERA_MIN_ANGLE), 
			deg_to_rad(CAMERA_MAX_ANGLE))
		
		# Применяем вращение к камере
		if has_node("Camera3D"):
			$Camera3D.rotation.x = camera_rotation.x
	
	# === ОСВОБОЖДЕНИЕ/ЗАХВАТ МЫШИ (добавлено) ===
	if Input.is_key_pressed(KEY_TAB):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print("📝 Мышь освобождена (нажмите TAB снова для захвата)")
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			print("🎯 Мышь захвачена")
	
	# Перезапуск
	if Input.is_key_pressed(KEY_R):
		print("🔄 ПЕРЕЗАПУСК СЦЕНЫ")
		get_tree().reload_current_scene()
	
	# Выход
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Добавлено
		get_tree().quit()

func _physics_process(delta):
	# === 1. ПРОВЕРЯЕМ, ЕСТЬ ЛИ ПОД НАМИ ПОЛ ===
	var floor_detected = false
	var floor_height = 0.0
	
	# Проверяем RayCast
	if has_node("FloorDetector") and $FloorDetector.is_colliding():
		floor_detected = true
		floor_height = $FloorDetector.get_collision_point().y
	
	# === 2. ЕСЛИ ПОЛ ОБНАРУЖЕН - СТОИМ НА НЁМ ===
	if floor_detected:
		var distance_to_floor = global_position.y - floor_height
		
		if distance_to_floor > 0.5:  # Далеко от пола
			# Падаем к полу
			velocity.y -= GRAVITY * delta
		else:
			# Близко к полу - прижимаем
			velocity.y = -2.0
			global_position.y = floor_height + 0.2  # Чуть выше пола
			is_falling = false
			fall_timer = 0.0
	else:
		# Пол не обнаружен - свободное падение
		velocity.y -= GRAVITY * delta
		is_falling = true
		fall_timer += delta
		
		if fall_timer > 0.5:  # Падаем больше 0.5 секунды
			print("⚠️ Долгое падение! Ищем пол...")
	
	# === 3. ПРЫЖОК (только если пол обнаружен) ===
	if Input.is_action_just_pressed("ui_accept") and floor_detected:
		velocity.y = JUMP_POWER
		print("🦘 ПРЫЖОК! Взлетаем!")
	
	# === 4. ДВИЖЕНИЕ ПО ГОРИЗОНТАЛИ ===
	var move_input = Vector2.ZERO
	
	if Input.is_action_pressed("move_forward"):
		move_input.y -= 1
	if Input.is_action_pressed("move_back"):
		move_input.y += 1
	if Input.is_action_pressed("move_left"):
		move_input.x -= 1
	if Input.is_action_pressed("move_right"):
		move_input.x += 1
	
	move_input = move_input.normalized()
	var direction = Vector3(move_input.x, 0, move_input.y)
	direction = direction.rotated(Vector3.UP, rotation.y)
	
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	
	# === 5. ДВИЖЕНИЕ ===
	move_and_slide()
	
	# === 6. АВАРИЙНАЯ ЗАЩИТА ===
	if global_position.y < -5:
		print("""
		🚨🚨🚨 КРИТИЧЕСКОЕ ПАДЕНИЕ! 🚨🚨🚨
		Причина: пол не обнаружен или слишком низко
		Возвращаем игрока на безопасную высоту
		""")
		
		# Ищем любой пол в сцене
		var ground = get_node_or_null("/root/Main/Ground")
		if ground:
			# Ставим игрока НАД полом
			global_position = Vector3(0, ground.global_position.y + 5, 0)
		else:
			# Если пол не найден - ставим на Y=10
			global_position = Vector3(0, 10, 0)
			print("⚠️ Пол не найден! Игрок на Y=10")
		
		velocity = Vector3.ZERO
		is_falling = false
	
	# === 7. ИНФОРМАЦИЯ ===
	
		
