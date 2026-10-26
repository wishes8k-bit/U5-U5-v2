extends Node2D

var client: ControlRoomClient
var player_name := ""  # spilleren rom 1 sendte over


func _ready() -> void:
	client = ControlRoomClient.new("ws://172.31.0.200:7321", 5)
	add_child(client)
	client.add_loading_screen()
#	client.player_incoming.connect(_on_player_incoming)
	client.player_left.connect(_on_player_left)
	client.game_finish_wait.connect(_on_game_finish_wait)
	client.game_finish_ok.connect(_on_game_finish_ok)
	client.run()


#Rom 1 er ferdig: spilleren er på vei hit.
func _on_player_incoming(username: String, _player_data: Variant) -> void:
	player_name = username
	print("Velkommen til rom 5, ", username)




#Kall denne når spilleren er ferdig i rommet.
func player_won() -> void:
	print("Spilleren er ferdig! Sjekker med kontrollrommet...")
	client.finish_game()


func _on_player_left(username: String) -> void:
	print("Spilleren ", username, " gikk og kommer ikke likevel.")


#Rom 3 er opptatt: be spilleren vente.
func _on_game_finish_wait(max_wait: Variant) -> void:
	print("Neste rom er opptatt. Vent til ", max_wait)


#Spilleren kan gå videre til rom 3.
func _on_game_finish_ok() -> void:
	print("Klart! Spilleren kan gå videre til rom 3.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		player_won()
