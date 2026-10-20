extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

var is_changing := false

func change_scene(path: String) -> void:
	if is_changing:
		return
	is_changing = true
	anim.play("fade_out")
	await anim.animation_finished
	get_tree().change_scene_to_file(path)
	anim.play("fade_in")
	await anim.animation_finished
	is_changing = false
