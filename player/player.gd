extends CharacterBody3D

var sensibilidad := 0.002
var speed := 5.0
var gravity := 9.8
var jump := 4.0

@onready var head: Node3D = $Head
@onready var raycast3D: RayCast3D = $Head/Camera3D/RayCast3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = direccion.x * speed
	velocity.z = direccion.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump
	
	detectar_bloque()
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mover_camara(event)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#romper bloque
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			romper_bloque()

func mover_camara(event: InputEventMouseMotion) -> void:
	rotation.y -= event.relative.x * sensibilidad
	head.rotation.x -= event.relative.y * sensibilidad
	head.rotation.x = clampf(head.rotation.x, -1.5, 1.5)
	
#logica bloques

func detectar_bloque():
	if raycast3D.is_colliding():
		var objeto = raycast3D.get_collider()

		if objeto != null and objeto.is_in_group("voxel"):
			return objeto

	return null

func romper_bloque():
	var bloque = detectar_bloque()
	if bloque!= null:
		bloque.destruir()
