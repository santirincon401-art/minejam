extends CharacterBody3D

var sensibilidad := 0.002
var speed := 5.0
var gravity := 9.8
var jump := 4.0
var volando := false
var velocidad_vuelo := 10.0
var tiempo_doble_toque := 0.3
var ultimo_toque_salto := -1.0

@onready var head: Node3D = $Head
@onready var raycast3D: RayCast3D = $Head/Camera3D/RayCast3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Detectar doble toque de salto (funciona también en el aire)
	if Input.is_action_just_pressed("jump"):
		var ahora := Time.get_ticks_msec() / 1000.0
		if ahora - ultimo_toque_salto <= tiempo_doble_toque:
			volando = not volando
			velocity.y = 0.0
			ultimo_toque_salto = -1.0
		else:
			ultimo_toque_salto = ahora

	if volando:
		velocity.x = direccion.x * velocidad_vuelo
		velocity.z = direccion.z * velocidad_vuelo
		velocity.y = Input.get_axis("crouch", "jump") * velocidad_vuelo

		# Aterrizar al bajar hasta el suelo
		if is_on_floor() and Input.is_action_pressed("crouch"):
			volando = false
	else:
		velocity.x = direccion.x * speed
		velocity.z = direccion.z * speed

		if not is_on_floor():
			velocity.y -= gravity * delta
		elif Input.is_action_just_pressed("jump"):
			velocity.y = jump

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mover_camara(event)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func mover_camara(event: InputEventMouseMotion) -> void:
	rotation.y -= event.relative.x * sensibilidad
	head.rotation.x -= event.relative.y * sensibilidad
	head.rotation.x = clampf(head.rotation.x, -1.5, 1.5)
	
