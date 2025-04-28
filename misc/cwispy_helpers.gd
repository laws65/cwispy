extends Node
class_name CwispyHelpers


static func get_half_player_rtt_ticks(player: Player) -> int:
	var rtt := player.get_rtt_msecs()
	var half_tick_rtt: int = ceil(
		# TODO rewrite this using NetworkTime.ticktime
		rtt*0.5/float((1000/float(Engine.get_physics_ticks_per_second())))
	)
	return half_tick_rtt

static func get_node_props(node: Node, prop_names: Array[String]) -> Dictionary:
	var out: Dictionary
	for prop_name in prop_names:
		var split := prop_name.split(":") as PackedStringArray
		var node_path := "."
		var node_prop := ""
		if split.size() == 1:
			node_prop = split[0]
		else:
			node_path = split[0]
			node_prop = split[1]
		out[prop_name] = node.get_node(node_path).get(node_prop)
	return out


static func set_node_props(node: Node, props: Dictionary) -> void:
	for prop_name in props.keys():
		var split := prop_name.split(":") as PackedStringArray
		var node_path := "."
		var node_prop := ""
		if split.size() == 1:
			node_prop = split[0]
		else:
			node_path = split[0]
			node_prop = split[1]
		node.get_node(node_path).set(node_prop, props[prop_name])
