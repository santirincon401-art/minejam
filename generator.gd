extends Node3D

@export var bloque: PackedScene
@export var player: CharacterBody3D

var ancho = 16

func _ready() -> void:
	generar_mundo()


func generar_mundo() -> void:

	if not bloque or not player:
		print("Falta asignar el bloque o el jugador")
		return

	var posicion_jugador = player.global_position

	var inicio_x = floori(posicion_jugador.x) - ancho / 2
	var inicio_z = floori(posicion_jugador.z) - ancho / 2

	for x in range(ancho):
		for z in range(ancho):

			var voxel = bloque.instantiate()
			add_child(voxel)

			voxel.global_position = Vector3(
				inicio_x + x,
				0,
				inicio_z + z
			)
