extends Node3D
# Crea y borra chunks alrededor del jugador.

@export var escena_chunk: PackedScene      # arrastra aquí tu escena chunk.tscn
@export var jugador: Node3D                # arrastra aquí tu jugador
@export var distancia_render := 4          # cuántos chunks se ven en cada dirección
@export var chunks_por_frame := 1          # cuántos chunks se crean por frame

var ruido := FastNoiseLite.new()
var chunks := {}                           # Vector2i -> chunk
var pendientes: Array[Vector2i] = []       # chunks por crear
var ultimo_chunk_jugador := Vector2i(999999, 999999)


func _ready() -> void:
	ruido.seed = randi()
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.frequency = 0.02                 # más bajo = colinas más anchas


func _process(_delta: float) -> void:
	if jugador == null or escena_chunk == null:
		return

	var actual := _mundo_a_chunk(jugador.global_position)

	# Solo recalculamos cuando el jugador cambia de chunk
	if actual != ultimo_chunk_jugador:
		ultimo_chunk_jugador = actual
		_actualizar_chunks(actual)

	# Creamos pocos chunks por frame para que no se congele
	for i in chunks_por_frame:
		if pendientes.is_empty():
			break
		_crear_chunk(pendientes.pop_front())


func _mundo_a_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / chunk.TAMAÑO_CHUNK), floori(pos.z / chunk.TAMAÑO_CHUNK))


func _actualizar_chunks(centro: Vector2i) -> void:
	# 1) Qué chunks faltan
	pendientes.clear()
	for x in range(centro.x - distancia_render, centro.x + distancia_render + 1):
		for z in range(centro.y - distancia_render, centro.y + distancia_render + 1):
			var p := Vector2i(x, z)
			if not chunks.has(p):
				pendientes.append(p)

	# Los más cercanos al jugador primero
	pendientes.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(centro) < b.distance_squared_to(centro))

	# 2) Borrar los que quedaron muy lejos
	for p in chunks.keys():
		if absi(p.x - centro.x) > distancia_render + 1 or absi(p.y - centro.y) > distancia_render + 1:
			chunks[p].queue_free()
			chunks.erase(p)


func _crear_chunk(p: Vector2i) -> void:
	if chunks.has(p):
		return
	var c: chunk = escena_chunk.instantiate()
	c.coordenada_chunk = p
	c.generar_automatico = false           # el manager lo genera, no el propio chunk
	add_child(c)
	c.generar(ruido)
	chunks[p] = c
