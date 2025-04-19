extends RefCounted
class_name INetworkedInput
# Extend me and set NetworkedInput.input_implementation to an instance of me

func get_inputs(tick: int) -> Dictionary:
	push_warning("Unimplemented!")
	return {}

func get_serialised_inputs(inputs: Dictionary) -> PackedByteArray:
	push_warning("Unimplemented!")
	return PackedByteArray()

func get_deserialised_inputs(bytes: PackedByteArray) -> Dictionary:
	push_warning("Unimplemented!")
	return {}

func get_predicted_input(player_id: int, tick: int) -> Dictionary:
	push_warning("Unimplemented!")
	return {}
