extends Node2D

enum State { BUSY, PLAYER_TURN, ENDED }

const COMMAND_BUTTON := preload("res://scenes/CommandButton.tscn")
const MAIN_SCENE := "res://scenes/main.tscn"

# Assign these in the Inspector on the Battle root node
@export var attack_skill: SkillResource
@export var player_skills: Array[SkillResource] = []
@export var player_max_hp := 40
@export var monster_max_hp := 100
@export var monster_skills: Array[SkillResource] = []
@export_range(0.0, 1.0) var run_chance := 0.5

@onready var player_sprite: AnimatedSprite2D = $battle_player
@onready var monster_sprite: AnimatedSprite2D = $battle_monster
@onready var main_commands: VBoxContainer = $CanvasLayer/Commandmenu/MarginContainer/MainCommands
@onready var attack_button: Button = $CanvasLayer/Commandmenu/MarginContainer/MainCommands/AttackButton
@onready var skills_button: Button = $CanvasLayer/Commandmenu/MarginContainer/MainCommands/Skills
@onready var guard_button: Button = $CanvasLayer/Commandmenu/MarginContainer/MainCommands/Guard
@onready var run_button: Button = $CanvasLayer/Commandmenu/MarginContainer/MainCommands/Run
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var hp_label: Label = $CanvasLayer/HPLabel

var state := State.BUSY
var player_hp := 0
var monster_hp := 0
var guarding := false
var skill_menu: VBoxContainer
var monster_hp_bar: ProgressBar


func _ready() -> void:
	player_hp = player_max_hp
	monster_hp = monster_max_hp
	monster_sprite.stop()
	monster_sprite.frame = 0

	_build_skill_menu()
	_build_monster_hp_bar()
	attack_button.pressed.connect(_on_attack_pressed)
	skills_button.pressed.connect(_on_skills_pressed)
	guard_button.pressed.connect(_on_guard_pressed)
	run_button.pressed.connect(_on_run_pressed)

	_update_hp()
	_hide_menus()
	await _say("Noe blokkerer veien din")
	_start_player_turn()


# ---------- Turn flow ----------

func _start_player_turn() -> void:
	guarding = false
	state = State.PLAYER_TURN
	message_label.text = "Din tur"
	skill_menu.hide()
	main_commands.show()


# Called after every player action. Checks for a win, runs the enemy turn,
# checks for a loss, then hands control back to the player.
func _end_player_action() -> void:
	if monster_hp <= 0:
		await _win()
		return
	await _enemy_turn()
	if player_hp <= 0:
		await _lose()
		return
	_start_player_turn()


func _enemy_turn() -> void:
	var skill: SkillResource = attack_skill
	if not monster_skills.is_empty():
		skill = monster_skills.pick_random()
	await _say("Monstret bruker %s!" % skill.name, 0.8)
	_play_sound(skill.sound)
	if skill.damage_max > 0:
		await _play_monster_attack()
		var dmg: int = skill.roll_damage()
		if guarding:
			dmg = ceili(dmg / 2.0)
		player_hp = maxi(player_hp - dmg, 0)
		_update_hp()
		await _shake(player_sprite)
		await _say("Du tok %d Skade." % dmg)
	if skill.heal > 0:
		monster_hp = mini(monster_hp + skill.heal, monster_max_hp)
		_update_monster_hp()
		await _say("Monstret helbreder %d HP." % skill.heal)


# ---------- Player actions ----------

func _on_attack_pressed() -> void:
	_use_skill(attack_skill)


func _on_skills_pressed() -> void:
	main_commands.hide()
	skill_menu.show()


func _on_back_pressed() -> void:
	skill_menu.hide()
	main_commands.show()


func _use_skill(skill: SkillResource) -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.BUSY
	_hide_menus()
	await _say("Du bruker %s." % skill.name, 0.7)
	_play_sound(skill.sound)
	if skill.damage_max > 0:
		var dealt: int = skill.roll_damage()
		await _hit_monster(dealt)
		await _say("Monstret tar %d Skade." % dealt)
	if skill.heal > 0:
		player_hp = mini(player_hp + skill.heal, player_max_hp)
		_update_hp()
		await _say("Du helbreder %d HP." % skill.heal)
	await _end_player_action()


func _on_guard_pressed() -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.BUSY
	_hide_menus()
	guarding = true
	await _say("Du Forbreder deg på et angrep")
	await _end_player_action()


func _on_run_pressed() -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.BUSY
	_hide_menus()
	await _say("Du prøver å løpe..", 0.8)
	if randf() < run_chance:
		await _say("Du kom deg unna")
		_leave_battle()
	else:
		await _say("Du kom deg ikke unna!")
		await _end_player_action()


# ---------- Ending the fight ----------

func _win() -> void:
	state = State.ENDED
	await _say("Monstret tar sitt siste pust", 1.5)
	GameState.monster_defeated = true
	_leave_battle()


func _lose() -> void:
	state = State.ENDED
	await _say("Alt blir svart", 1.5)
	GameState.reset()
	_leave_battle()


func _leave_battle() -> void:
	SceneTransition.change_scene(MAIN_SCENE)


# ---------- Helpers ----------

func _build_skill_menu() -> void:
	skill_menu = VBoxContainer.new()
	# Same parent as MainCommands, so it appears in the same spot when swapped in
	main_commands.get_parent().add_child(skill_menu)
	for skill in player_skills:
		var button: Button = COMMAND_BUTTON.instantiate()
		button.text = skill.name
		button.pressed.connect(_use_skill.bind(skill))
		skill_menu.add_child(button)
	var back: Button = COMMAND_BUTTON.instantiate()
	back.text = "Tilbake"
	back.pressed.connect(_on_back_pressed)
	skill_menu.add_child(back)
	skill_menu.hide()


func _hide_menus() -> void:
	main_commands.hide()
	skill_menu.hide()


func _say(text: String, wait := 1.0) -> void:
	message_label.text = text
	await get_tree().create_timer(wait).timeout


func _update_hp() -> void:
	hp_label.text = "HP %d / %d" % [player_hp, player_max_hp]


func _hit_monster(amount: int) -> void:
	monster_hp = maxi(monster_hp - amount, 0)
	_update_monster_hp()
	await _shake(monster_sprite)


func _play_monster_attack() -> void:
	# Wait using a timer, so it works even if the animation is set to loop
	# in the SpriteFrames editor.
	var frames := monster_sprite.sprite_frames
	var length: float = frames.get_frame_count("monster_hit") / frames.get_animation_speed("monster_hit")
	monster_sprite.play("monster_hit")
	await get_tree().create_timer(length).timeout
	monster_sprite.stop()
	monster_sprite.frame = 0


func _shake(node: Node2D) -> void:
	var start := node.position
	var tween := create_tween()
	for i in 5:
		var offset := Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
		tween.tween_property(node, "position", start + offset, 0.04)
	tween.tween_property(node, "position", start, 0.04)
	await tween.finished


func _build_monster_hp_bar() -> void:
	monster_hp_bar = ProgressBar.new()
	monster_hp_bar.max_value = monster_max_hp
	monster_hp_bar.value = monster_hp
	monster_hp_bar.show_percentage = false
	monster_hp_bar.custom_minimum_size = Vector2(400, 24)
	monster_hp_bar.position = Vector2(376, 30)
	monster_hp_bar.size = Vector2(400, 24)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.47, 0.0, 0.08)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	monster_hp_bar.add_theme_stylebox_override("fill", fill)
	monster_hp_bar.add_theme_stylebox_override("background", back)
	$CanvasLayer.add_child(monster_hp_bar)


func _update_monster_hp() -> void:
	var tween := create_tween()
	tween.tween_property(monster_hp_bar, "value", monster_hp, 0.3)


func _play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	# One-shot player per sound, so effects can overlap and clean up after themselves
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
