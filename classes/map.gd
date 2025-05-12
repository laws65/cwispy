extends Node
class_name Map


var _inner_data_forwards: Dictionary
var _inner_data_backwards: Dictionary


func get_forwards(key: Variant, null_ret: Variant = null) -> Variant:
	return _inner_data_forwards.get(key, null_ret)


func get_backwards(key: Variant, null_ret: Variant = null) -> Variant:
	return _inner_data_backwards.get(key, null_ret)


func set_forwards(key: Variant, value: Variant) -> void:
	_inner_data_forwards[key] = value
	_inner_data_backwards[value] = key


func set_backwards(key: Variant, value: Variant) -> void:
	_inner_data_backwards[key] = value
	_inner_data_forwards[value] = key


func has_forwards(key: Variant) -> void:
	return _inner_data_forwards.has(key)


func has_backwards(key: Variant) -> void:
	return _inner_data_backwards.has(key)
