extends Area2D

@export var intensity: float = 8.0
@export var duration: float = 0.8 
@export var one_shot: bool = true



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var cam := body.get_node_or_null("ShakeCamera2D")
		
		if cam: 
			cam.screen_shake(intensity, duration)
			
			if body.has_method("freeze"):
				body.freeze(0.8)
			
			if one_shot:
				set_deferred("monitoring", false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
