extends CharacterBody2D

@export var speed =  15
var player_chase = false
var player = null

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	if player_chase and player:
		var dir = (player.position - position).normalized()
		position += (player.position - position) / speed
		play_animation("run", dir)
	else:
		animated_sprite_2d.stop()
		
		

func _on_detection_area_body_entered(body):
	player = body
	player_chase = true	



func _on_detection_area_body_exited(body):
	player = null
	player_chase = false
	
func play_animation(prefix: String, dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_up")
	else:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play(prefix + "_down")

func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneTransition.change_scene("res://scenes/battle.tscn")
