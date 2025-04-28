extends RefCounted
class_name ISnapshotManager
# Extend me and set SnapshotManager.manager_implementation to me

## Create snapshot to be broadcasted to specfic player (0 = all players, 1=server snapshot with all info)
func create_snapshot_for_player(time: int, for_player_id: int) -> Dictionary:
	push_error("Unimplemented!")
	return {}

## Returns a list of players ids for which snapshots should be sent to (0 = all players, 1=server snapshot with all info)
func get_relevant_players() -> PackedInt64Array:
	push_error("Unimplemented!")
	return []
