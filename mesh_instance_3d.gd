class_name chunk
extends StaticBody3D

# --- Nodos hijos: arrastra aquí desde el inspector ---
@export var mesh_instance: MeshInstance3D
@export var collision_shape: CollisionShape3D

@export var coordenada_chunk := Vector2i.ZERO
# Déjalo activado si pones el chunk a mano en la escena; el manager lo desactiva
@export var generar_automatico := true

const TAMAÑO_CHUNK: int = 10
const ALTURA_MAXIMA := 50
const ALTURA_MINIMA := 1

var bloques: Dictionary = {}  # Vector3i -> true

const VERTICES_CUBO: Array[Vector3] = [
	Vector3(-0.5, -0.5,  0.5), Vector3( 0.5, -0.5,  0.5),
	Vector3( 0.5,  0.5,  0.5), Vector3(-0.5,  0.5,  0.5),
	Vector3(-0.5, -0.5, -0.5), Vector3( 0.5, -0.5, -0.5),
	Vector3( 0.5,  0.5, -0.5), Vector3(-0.5,  0.5, -0.5)
]

const CARAS: Array = [
	[0, 1, 2, 3], # +Z
	[5, 4, 7, 6], # -Z
	[1, 5, 6, 2], # +X
	[4, 0, 3, 7], # -X
	[3, 2, 6, 7], # +Y (superior)
	[4, 5, 1, 0], # -Y
]

const DIRECCIONES: Array[Vector3i] = [
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
]

# Una cara es un cuadrado de 4 vértices = 2 triángulos de 3
const TRIANGULOS := [0, 2, 1, 0, 3, 2]

const COLOR_PASTO := Color(0.25, 0.7, 0.25)
const COLOR_TIERRA := Color(0.45, 0.3, 0.15)


func _ready() -> void:
	# Si lo pones en la escena a mano, se genera solo.
	# Si lo crea un manager por código, llama tú a generar() después de asignar los datos.
	if generar_automatico and mesh_instance != null and collision_shape != null:
		generar()


# Si no arrastraste los nodos en el inspector, los busca solos entre los hijos
func _buscar_nodos() -> void:
	for hijo in get_children():
		if mesh_instance == null and hijo is MeshInstance3D:
			mesh_instance = hijo
		elif collision_shape == null and hijo is CollisionShape3D:
			collision_shape = hijo


# Hace todo el proceso: datos -> malla -> colisión
func generar(ruido: FastNoiseLite = null) -> void:
	_buscar_nodos()
	if mesh_instance == null or collision_shape == null:
		push_error("chunk: faltan los nodos MeshInstance3D y/o CollisionShape3D como hijos de la escena.")
		return
	position = Vector3(coordenada_chunk.x * TAMAÑO_CHUNK, 0, coordenada_chunk.y * TAMAÑO_CHUNK)
	generar_data(ruido)
	construir_malla()
	construir_colision()


# SOLO llena el diccionario "bloques" (no dibuja nada).
# Sin ruido: terreno plano de 20 bloques de alto.
# Con ruido (FastNoiseLite): colinas.
func generar_data(ruido: FastNoiseLite = null) -> void:
	bloques.clear()

	for x in range(TAMAÑO_CHUNK):
		for z in range(TAMAÑO_CHUNK):
			var altura := 20
			if ruido != null:
				# Posición en el mundo, para que los chunks vecinos encajen
				var mundo_x := coordenada_chunk.x * TAMAÑO_CHUNK + x
				var mundo_z := coordenada_chunk.y * TAMAÑO_CHUNK + z
				var n := ruido.get_noise_2d(mundo_x, mundo_z)  # entre -1 y 1
				altura = int(remap(n, -1.0, 1.0, ALTURA_MINIMA, ALTURA_MAXIMA))

			for y in range(altura):
				bloques[Vector3i(x, y, z)] = true


func construir_malla() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	st.set_material(material)

	for pos in bloques:
		for i in range(6):
			if bloques.has(pos + DIRECCIONES[i]):
				continue  # cara tapada por un vecino

			# Normal y color valen para todos los vértices que se añadan después
			st.set_normal(Vector3(DIRECCIONES[i]))
			st.set_color(COLOR_PASTO if i == 4 else COLOR_TIERRA)

			for t in TRIANGULOS:
				st.add_vertex(VERTICES_CUBO[CARAS[i][t]] + Vector3(pos))

	# La malla se guarda en el MeshInstance3D (el StaticBody3D no tiene "mesh")
	mesh_instance.mesh = st.commit()


func construir_colision() -> void:
	var m := mesh_instance.mesh
	if m == null or m.get_surface_count() == 0:
		collision_shape.shape = null
		return
	# Crea la forma de colisión a partir de la malla y se la da al CollisionShape3D
	collision_shape.shape = m.create_trimesh_shape()
