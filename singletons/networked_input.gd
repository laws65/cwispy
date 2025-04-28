extends Node

const MAX_INPUT_BUFFER_SIZE = 100
var _input_buffers: Dictionary[int, TimedBuffer]
var _target_input_time := -1
var _target_player_id := -1

var _client_unacknowledged_serialised_inputs: Array[PackedByteArray]


var input_implementation: INetworkedInput

var input_names: Dictionary[StringName, int]


#region Implementation details
func _get_inputs(tick: int) -> Dictionary:
	return input_implementation.get_inputs(tick)


func _get_serialised_inputs(inputs: Dictionary) -> PackedByteArray:
	return input_implementation.get_serialised_inputs(inputs)


func _get_deserialised_inputs(bytes: PackedByteArray) -> Dictionary:
	return input_implementation.get_deserialised_inputs(bytes)


func _get_predicted_input(player_id: int, tick: int) -> Dictionary:
	return input_implementation.get_predicted_input(player_id, tick)
#endregion


func _ready() -> void:
	NetworkTime.before_tick.connect(
		func (_delta: float, tick: int):
			if Multiplayer.is_client():
				_broadcast_and_save_inputs(tick)
	)
	Multiplayer.player_left.connect(
		func(player: Player):
			_input_buffers.erase(player.get_id())
	)


## Reads the player input into bytes
## Adds the player input into unacknowledged inputs buffer
## Send all unacknowledged inputs to server
## Add input to own buffer for blobs to use etc.
func _broadcast_and_save_inputs(tick: int) -> void:
	var inputs := _get_inputs(tick)
	var serialised_inputs := _get_serialised_inputs(inputs)
	_client_unacknowledged_serialised_inputs.push_front(serialised_inputs)
	_server_receive_unacknowledged_serialised_inputs.rpc_id(1, _client_unacknowledged_serialised_inputs)
	_add_inputs_to_buffer(inputs, multiplayer.get_unique_id())


## Receive array of inputs from client
## Put these into the input buffer for blobs to use etc.
## Tell client to no longer send the received inputs
@rpc("any_peer", "unreliable")
func _server_receive_unacknowledged_serialised_inputs(unacknowledged_serialised_inputs: Array[PackedByteArray]) -> void:
	# TODO add input sanitation (i.e. don't crash the server)
	var player_id := multiplayer.get_remote_sender_id()
	var acknowledged_input_timestamps: Array[int]
	for serialised_input in unacknowledged_serialised_inputs:
		var input := _get_deserialised_inputs(serialised_input)
		acknowledged_input_timestamps.push_back(input["time"] as int)
		_add_inputs_to_buffer(input, player_id)

	_client_receive_acknowledged_inputs.rpc_id(player_id, acknowledged_input_timestamps)


## Stop sending client inputs that have been received by the server
@rpc("authority", "unreliable")
func _client_receive_acknowledged_inputs(acknowledged_input_timestamps: Array[int]) -> void:
	_client_unacknowledged_serialised_inputs = _client_unacknowledged_serialised_inputs.filter(
		func(serialised_input: PackedByteArray):
			var time := serialised_input.decode_s32(0)
			time not in acknowledged_input_timestamps
	)


func _add_inputs_to_buffer(inputs: Dictionary, player_id: int) -> void:
	if not _input_buffers.has(player_id):
		_input_buffers[player_id] = TimedBuffer.new(MAX_INPUT_BUFFER_SIZE)
		return

	_input_buffers[player_id].insert(inputs)


func get_input(input_name: StringName, null_ret: Variant = null) -> Variant:
	assert(_target_input_time != -1, "Target input time must be selected")
	assert(_target_player_id != -1, "Target player must be selected")


	var player_input := get_inputs_for_player_at_time(_target_player_id, _target_input_time)
	if player_input.is_empty():
		return null_ret

	if not player_input.has(input_name):
		push_warning("Invalid input ", input_name)
		return null_ret

	return player_input[input_name]


func set_target_player_id(target_player_id: int) -> void:
	_target_player_id = target_player_id


func set_target_player(target_player: Player) -> void:
	if Player.is_valid_player(target_player):
		set_target_player_id(target_player.get_id())


func set_time(new_time: int) -> void:
	_target_input_time = new_time


func get_inputs_for_player_at_time(player_id: int, time: int) -> Dictionary:
	if not _input_buffers.has(player_id):
		return {}

	var latest_timestamp := get_latest_input_timestamp(player_id)
	if time == latest_timestamp:
		var player_buffer := _input_buffers[player_id]
		return player_buffer.retrieve(latest_timestamp)
	elif time > latest_timestamp:
		print_stack()
		print("Trying to get input ", time, " when the latest timestamp is ", latest_timestamp)
		#var time_strings = ""
		#var array := _input_buffers[player_id].get_inner_array()
		#for i in array:
			#if i:
				#time_strings += str(i["time"]) + ", "
		#print(time_strings)
		return {}
	else:
		var player_buffer := _input_buffers[player_id]
		player_buffer.store_head()
		# TODO fix this shit implementation

		var iter := 0
		while iter < 150:

			var prev_input := player_buffer.get_previous()
			if not prev_input.is_empty() and prev_input["time"] == time:
				player_buffer.reset_head()
				return prev_input
			iter += 1
		return {}

		# TODO add warnings for when requesting a tick that is too old


func get_latest_input_timestamp(player_id: int) -> int:
	if not _input_buffers.has(player_id):
		return 0

	var player_buffer := _input_buffers[player_id]
	var latest_input := player_buffer.retrieve_latest()
	if latest_input.is_empty():
		return 0

	return latest_input["time"]


func get_latest_inputs_for_player(player_id: int) -> Dictionary:
	if not _input_buffers.has(player_id):
		return {}

	var player_buffer := _input_buffers[player_id]
	var latest_input := player_buffer.retrieve_latest()
	if latest_input.is_empty():
		return {}

	return latest_input


func has_inputs_at_time(player_id: int, tick: int) -> bool:
	var inputs := get_inputs_for_player_at_time(player_id, tick)
	return inputs and inputs["time"] == tick


func get_predicted_input(player_id: int, tick: int) -> Dictionary:
	var predicted := _get_predicted_input(player_id, tick)
	predicted["flag_predicted"] = true
	predicted["time"] = tick
	return predicted


func add_temp_input(player_id: int, input: Dictionary) -> void:
	input["flag_temp"] = true
	_add_inputs_to_buffer(input, player_id)


func register_button(button_name: StringName, button_val: int) -> void:
	input_names[button_name] = button_val


func is_button_pressed(button_name: StringName) -> bool:
	if not input_names.has(button_name):
		push_warning("Please register button ", button_name, "\" before using it")
		return false

	var buttons: int = get_input("buttons", 0)

	return buttons & input_names[button_name] > 0
