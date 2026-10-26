extends Node

# Register this as an Autoload named "GameState"
# (Project > Project Settings > Globals > Autoload)

var monster_defeated := false
var has_saved_position := false
var player_position := Vector2.ZERO


func reset() -> void:
	monster_defeated = false
	has_saved_position = false
	player_position = Vector2.ZERO
