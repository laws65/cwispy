extends Node
class_name Player

signal blob_id_changed(old_id: int, new_id: int)

var _username: String


func _init(data: Array) -> void:
	name = str(data[0])
	_username = data[1]


func serialise() -> Array:
	return [int(str(name)), _username]


func get_id() -> int:
	return int(str(name))


func is_me() -> bool:
	return get_id() == multiplayer.get_unique_id()


func server_set_blob_id(blob_id: int) -> void:
	assert(Multiplayer.is_server())
	Multiplayer.set_blob_owner.rpc_id(0, blob_id, get_id())


func server_set_blob(blob: Blob) -> void:
	assert(Multiplayer.is_server())
	assert(is_instance_valid(blob))
	server_set_blob_id(blob.get_id())

######################
## Helper functions ##
######################
static func get_players() -> Array:
	return Multiplayer.get_players_parent().get_children()


static func get_player_by_id(player_id: int) -> Player:
	return Multiplayer.get_players_parent().get_node_or_null(str(player_id))


static func player_exists(player_id: int) -> bool:
	return Multiplayer.get_players_parent().has_node(str(player_id))


static func is_valid_player(player: Player) -> bool:
	return player and player.get_id() > 0


func has_blob() -> bool:
	return get_blob_id() > 0


func get_rtt_msecs() -> int:
	return Clock.player_rtt.get(get_id(), 0.0) * 1000


func get_blob() -> Blob:
	if not has_blob():
		return null
	return Blob.get_blob_by_id(get_blob_id())


func get_blob_id() -> int:
	return Multiplayer.get_blob_id_for_player_id(get_id())
