extends Node
## Ticks the world blobs, and player blobs if they have inputs

var INPUT_BUFFER_SIZE = 1 # not constant
var server_latest_player_ticks: Dictionary[int, int]

# TODO move latest_consumed_player_inputs() code out of world state maybe? More for SOC
var latest_consumed_player_inputs: Dictionary[int, int]


func _ready() -> void:
	NetworkTime.on_tick.connect(_on_tick)
	Multiplayer.player_joined.connect(_on_player_joined)
	Multiplayer.player_left.connect(_on_player_left)



func _on_tick(_delta: int, tick: int) -> void:
	if Multiplayer.is_server():
		_tick_world(tick)


func _on_player_joined(player: Player):
	if Multiplayer.is_server():
		server_latest_player_ticks[player.get_id()] = NetworkTime.tick


func _on_player_left(player: Player) -> void:
	if Multiplayer.is_server():
		server_latest_player_ticks.erase(player.get_id())
		latest_consumed_player_inputs.erase(player.get_id())


func _tick_world(tick: int) -> void:
	var blobs := Blob.get_blobs()
	for blob: Blob in blobs:
		var player := blob.get_player()
		if not Player.is_valid_player(player):
			blob._internal_rollback_tick(Clock.fixed_delta, tick, true)
		else:
			_tick_player_blob(blob, tick)


func _tick_player_blob(blob: Blob, tick: int) -> void:
	var player := blob.get_player()
	var player_id := player.get_id()

	var half_tick_rtt := CwispyHelpers.get_half_player_rtt_ticks(player)

	var render_tick: int = tick - INPUT_BUFFER_SIZE - half_tick_rtt
	var current_tick := server_latest_player_ticks[player_id] + 1

	while current_tick <= render_tick:
		var latest_input_timestamp := NetworkedInput.get_latest_input_timestamp(player_id)
		latest_consumed_player_inputs[player_id] = latest_input_timestamp

		if current_tick > latest_input_timestamp:
			if Synchroniser._debug_syncing:
				print("Server: missed last player input, predicting input for tick " + str(current_tick))
			# TODO increase buffer width, to account for changes in ping, etc. so that we don't have to predict inputs consistently
			#push_warning("Missing input on tick ", current_tick, " : ", latest_input_timestamp)
			var predicted_input := NetworkedInput.get_predicted_input(player_id, current_tick)
			NetworkedInput.add_temp_input(player_id, predicted_input)

		blob._internal_rollback_tick(Clock.fixed_delta, current_tick, true)
		current_tick += 1

	server_latest_player_ticks[player_id] = render_tick
	latest_consumed_player_inputs[player_id] = render_tick
