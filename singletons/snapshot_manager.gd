extends Node
## Broadcasts the world state to the clients
## Saves the history of the world state to a buffer

const SNAPSHOT_BUFFER_SIZE = 150


var _snapshots_buffer := TimedBuffer.new(SNAPSHOT_BUFFER_SIZE)

var _snapshot_implementation: ISnapshotManager = DefaultSnapshotImplementation.new()


func _ready() -> void:
	NetworkTime.after_tick.connect(_after_tick)


func _after_tick(_delta: float, tick: int) -> void:
	if Multiplayer.is_server():
		_save_and_broadcast_snapshots(tick)


func _save_and_broadcast_snapshots(time: int) -> void:
	var target_player_ids := _snapshot_implementation.get_relevant_players()
	var snapshots_to_be_broadcast: Dictionary[int, Dictionary]

	if target_player_ids.has(0):
		var snapshot := create_world_snapshot_for(time, 0)
		_broadcast_snapshot_to(snapshot, 0)
		target_player_ids.remove_at(target_player_ids.find(0))

	if target_player_ids.has(1):
		var snapshot := create_world_snapshot_for(time, 1)
		insert_snapshot_into_buffer(snapshot)
		target_player_ids.remove_at(target_player_ids.find(1))

	for player_id in target_player_ids:
		var snapshot := create_world_snapshot_for(time, player_id)
		_broadcast_snapshot_to(snapshot, player_id)


func create_world_snapshot_for(time: int, for_player_id: int) -> Dictionary:
	return _snapshot_implementation.create_snapshot_for_player(time, for_player_id)


func _broadcast_snapshot_to(snapshot: Dictionary, player_id: int) -> void:
	_receive_server_snapshot.rpc_id(player_id, snapshot)


@rpc("unreliable", "authority")
func _receive_server_snapshot(snapshot: Dictionary) -> void:
	var player_id := multiplayer.get_unique_id()
	var latest_inputs: Dictionary[int, int] = snapshot["latest_inputs"]
	if latest_inputs.has(player_id):
		#print("Client: input ", latest_inputs[player_id], " was consumed on server")
		ServerTicker.latest_consumed_player_inputs[player_id] = latest_inputs[player_id]
	insert_snapshot_into_buffer(snapshot)


func get_snapshots_buffer() -> Array[Dictionary]:
	return _snapshots_buffer.get_inner_array()


func insert_snapshot_into_buffer(snapshot: Dictionary) -> void:
	_snapshots_buffer.insert(snapshot)


func get_snapshot_at_time(time: int) -> Dictionary:
	return _snapshots_buffer.retrieve(time)
