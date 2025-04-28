extends ISnapshotManager
class_name DefaultSnapshotImplementation


func create_snapshot_for_player(time: int, for_player_id: int) -> Dictionary:
	var output = {
		"blobs": {},
		"time": time,
		"authority": Multiplayer.is_server(),
		"latest_inputs": ServerTicker.latest_consumed_player_inputs,
	}

	var blobs := Blob.get_blobs()
	for blob in blobs as Array[Blob]:
		var blob_snapshot := blob.get_snapshot()
		output["blobs"][blob.get_id()] = blob_snapshot

	if Multiplayer.is_server():
		var player_inputs: Dictionary[int, Dictionary]
		var players := Player.get_players()
		for player in players:
			var player_id := player.get_id() as int
			var inputs = NetworkedInput.get_inputs_for_player_at_time(player_id, time)
			player_inputs[player_id] = inputs
		output["inputs"] = player_inputs

	return output


func get_relevant_players() -> PackedInt64Array:
	return [0, 1]
