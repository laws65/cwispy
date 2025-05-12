@tool
extends CharacterBody2D
class_name Blob

signal player_id_changed(old_id: int, new_id: int)
signal rollback_tick(delta: float, tick: int, is_fresh: bool)

@export var client_authority := false:
	set(val):
		client_authority = val
		notify_property_list_changed()


@export var spawn_props: Array[String]
@export var snapshot_props: Array[String]
@export var client_props: Array[String]


func _validate_property(property: Dictionary) -> void:
	if property.name == &"client_props":
		if not client_authority:
			property.usage = PROPERTY_USAGE_NONE


func _internal_rollback_tick(delta: float, tick: int, is_fresh: bool = true) -> void:
	if has_player():
		NetworkedInput.set_time(tick)
		NetworkedInput.set_target_player(get_player())
	_rollback_tick(delta, tick, is_fresh)
	rollback_tick.emit(delta, tick, is_fresh)


func _rollback_tick(delta: float, tick: int, is_fresh: bool = true) -> void:
	pass


func get_id() -> int:
	return int(str(name))


static func get_blobs() -> Array:
	return Multiplayer.get_blobs_parent().get_children() as Array


static func blob_id_exists(blob_id: int) -> bool:
	return blob_id > 0 and Multiplayer.get_blobs_parent().has_node(str(blob_id))


static func get_blob_by_id(blob_id: int) -> Blob:
	if blob_id > 0 and Multiplayer.get_blobs_parent().has_node(str(blob_id)):
		return Multiplayer.get_blobs_parent().get_node(str(blob_id)) as Blob
	return null


static func is_valid_blob(blob: Blob) -> bool:
	return blob and blob.get_id() > 0


func has_player() -> bool:
	return get_player_id() != -1


func is_my_blob() -> bool:
	return get_player_id() == multiplayer.get_unique_id()


func get_player() -> Player:
	return Player.get_player_by_id(get_player_id())


func server_set_player_id(player_id: int) -> void:
	assert(Multiplayer.is_server(), "Must be called on server")
	Multiplayer.set_blob_owner.rpc_id(0, get_id(), player_id)


func server_set_player(player: Player) -> void:
	assert(Multiplayer.is_server(), "Must be called on server")
	server_set_player_id(player.get_id())


func get_player_id() -> int:
	return Multiplayer.get_player_id_for_blob_id(get_id())


func server_kill() -> void:
	assert(Multiplayer.is_server())
	_die.rpc_id(0)


@rpc("call_local", "reliable")
func _die() -> void:
	queue_free()
	Multiplayer.blob_died.emit(self)
	get_parent().remove_child(self)


func load_snapshot(snapshot: Dictionary) -> void:
	CwispyHelpers.set_node_props(self, snapshot)


func get_snapshot() -> Dictionary:
	var snapshot := CwispyHelpers.get_node_props(self, snapshot_props)
	return snapshot


func load_spawn_data(params: Dictionary) -> void:
	name = str(params["id"])
	var params_copy := params.duplicate(true)
	params_copy.erase("id")
	CwispyHelpers.set_node_props(self, params_copy)


func get_spawn_data() -> Dictionary:
	var spawn_data := {
		"path": scene_file_path,
		"id": get_id(),
	}

	var prop_data := CwispyHelpers.get_node_props(self, spawn_props)
	spawn_data.merge(prop_data)

	return spawn_data
