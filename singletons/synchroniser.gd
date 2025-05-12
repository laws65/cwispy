extends Node


signal after_tick

var RENDER_TIME_TICK_DELAY = 1

var client_prediction_enabled := false
var remote_client_prediction_enabled := true

var _debug_syncing := false

var client_sync_exclude: Array[int] # Array of the only blob ids that won't be in _load_snapshot()
var client_sync_include: Array[int] # Array of the only blob ids that will be synced in _load_snapshot()


func _ready() -> void:
	NetworkTime.on_tick.connect(_tick)


func _tick(_delta: float, tick: int) -> void:
	if Multiplayer.is_client():
		_sync_blobs()
		after_tick.emit()


func _sync_blobs() -> void:
	if _debug_syncing:
		print("-----NEW TICK " , NetworkTime.tick ,"-----------")
	# TODO the client side prediction bug is due to: the server uses player input 110 on tick 115,
	# so the player rolls back to tick 110, but this is before the input was applied
	# it instead should roll the player "back" to 115, as if it was tick 110
	# So need to keep track of not only what the latest input was, but on what tick it was used
	# the discrepancy is that the ["tick"] of the snapshot received is different to latest_received_tick
	# will have to be careful to avoid off-by-one errors
	#
	# TODO fix client side prediction code
	# TODO rewatch -> https://www.youtube.com/watch?v=W3aieHjyNvw&t=1529s&ab_channel=GameDevelopersConference

	var half_tick_rtt := CwispyHelpers.get_half_player_rtt_ticks(Multiplayer.get_my_player())
	var render_tick: int = NetworkTime.tick - RENDER_TIME_TICK_DELAY - half_tick_rtt

	var render_snapshot := SnapshotManager.get_snapshot_at_time(render_tick)
	if render_snapshot and render_snapshot["time"] == render_tick:
		_load_snapshot(render_snapshot)
	elif remote_client_prediction_enabled:
		print("predicting tick")
		_predict_tick(render_tick)


func _rollback_to(time: int) -> void:
	_load_snapshot(SnapshotManager.get_snapshot_at_time(time))


func _get_most_recent_snapshot_before_time(snapshots_buffer: Array[Dictionary], render_tick: int) -> Dictionary:
	var recent_snapshot_before_render_tick: Dictionary = {"time":-1}
	for i in snapshots_buffer.size():
		var snapshot: Dictionary = snapshots_buffer[i]
		if (snapshot and snapshot["time"] > recent_snapshot_before_render_tick["time"]
		and snapshot["time"] < render_tick
		and snapshot["authority"]):
			recent_snapshot_before_render_tick = snapshot
	if recent_snapshot_before_render_tick["time"] == -1:
		return {}
	return recent_snapshot_before_render_tick


func _predict_tick(render_tick: int) -> void:
	var snapshots_buffer := SnapshotManager.get_snapshots_buffer()
	if _debug_syncing:
		print("Client: missing state snapshot for tick ", render_tick)

	var recent_snapshot_before_render_tick := _get_most_recent_snapshot_before_time(snapshots_buffer, render_tick)

	if recent_snapshot_before_render_tick.is_empty():
		print("Couldn't even find snapshot, returning")
		return

	var ticks_to_simulate := render_tick - recent_snapshot_before_render_tick["time"] as int
	var player_inputs := recent_snapshot_before_render_tick["inputs"] as Dictionary[int, Dictionary]
	var blobs_to_simulate := recent_snapshot_before_render_tick["blobs"].keys() as Array

	while ticks_to_simulate > 0:
		if _debug_syncing:
			print("simulating")
		var simulated_render_tick: int = render_tick - ticks_to_simulate + 1
		for blob_id in blobs_to_simulate:
			var blob := Blob.get_blob_by_id(blob_id)
			if not Blob.is_valid_blob(blob):
				# BUG figure out why this check is needed
				continue
			blob.load_snapshot(recent_snapshot_before_render_tick["blobs"][blob.get_id()])
			var has_correct_input := false

			if blob.has_player():
				if not (client_prediction_enabled and blob.is_my_blob()):
					var player_id := blob.get_player_id()
					var inputs := player_inputs[player_id]
					#print("here simulating ", simulated_render_tick, " : ", NetworkTime.tick)
					NetworkedInput.add_temp_input(player_id, inputs)
					blob._internal_rollback_tick(NetworkTime.ticktime, simulated_render_tick, false)
			else:
				blob._internal_rollback_tick(NetworkTime.ticktime, simulated_render_tick, false)

		if ticks_to_simulate > 1:
			var snapshot := SnapshotManager.create_world_snapshot_for(simulated_render_tick, 1)
			SnapshotManager.insert_snapshot_into_buffer(snapshot)

		ticks_to_simulate -= 1

	if client_prediction_enabled:
		_client_side_predict_from(render_tick, NetworkTime.tick)


func _load_snapshot(snapshot: Dictionary) -> void:
	assert(client_sync_exclude.is_empty() or client_sync_include.is_empty(), "You fucked up")

	if _debug_syncing:
		print("loading snapshot ", snapshot["time"])
	#print(snapshot["time"])
	for blob_id in snapshot["blobs"].keys():
		if client_sync_include and blob_id not in client_sync_include: continue
		if blob_id in client_sync_exclude: continue

		var blob_snapshot := snapshot["blobs"][blob_id] as Dictionary
		var blob := Blob.get_blob_by_id(blob_id)
		if Blob.is_valid_blob(blob):
			# BUG figure out why this check is needed
			blob.load_snapshot(blob_snapshot)


func _client_side_predict_from(from_tick: int, to_tick: int) -> void:
	if _debug_syncing:
		print("Client: predicting from ", from_tick, " to ", to_tick)
	assert(from_tick <= to_tick)

	if not Multiplayer.is_client(): return
	if not Multiplayer.has_local_blob(): return

	var blob := Multiplayer.get_my_blob()
	var blob_id := blob.get_id()

	# Sync client blob back to server authoritative state
	client_sync_include.push_back(blob_id)
	_rollback_to(from_tick)
	client_sync_include.pop_back()

	client_sync_exclude.push_back(blob_id)
	var current_tick := from_tick + 1
	while current_tick <= to_tick:
		_rollback_to(current_tick)
		blob._internal_rollback_tick(NetworkTime.ticktime, current_tick, false)
		current_tick += 1
	client_sync_exclude.pop_back()
