extends Node2D

@onready var player := $ActorsContainer/Player
@onready var camera := $Camera

func _process(_delta: float) -> void:
	camera.position.x = player.position.x

	#if player.position.x > camera.position.x:
		#camera.position.x = player.position.x
