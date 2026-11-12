extends Node3D

const AIRE = 0
const TIERRA = 1
const PIEDRA = 2

var bloques = {}

func _ready():
	bloques[Vector3i(0, 0, 0)] = TIERRA
	bloques[Vector3i(1, 0, 0)] = PIEDRA
	bloques[Vector3i(0, 1, 0)] = TIERRA

	print(obtener_bloque(Vector3i(1, 0, 0)))

	romper_bloque(Vector3i(1, 0, 0))

	print(obtener_bloque(Vector3i(1, 0, 0)))

#reto A
func obtener_bloque(coordenada: Vector3i) -> int:

	var resultado = bloques.get(coordenada, AIRE)

	return resultado
func romper_bloque(coordenada: Vector3i):
	if bloques.has(coordenada):
		bloques.erase(coordenada)
