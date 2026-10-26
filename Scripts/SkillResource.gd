extends Resource
class_name SkillResource
 
@export var name: String
@export var damage_min: int = 0
@export var damage_max: int = 0
@export var heal: int = 0
@export var sound: AudioStream
 
 
func roll_damage() -> int:
	return randi_range(damage_min, maxi(damage_min, damage_max))
