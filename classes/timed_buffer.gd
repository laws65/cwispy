extends RefCounted
class_name TimedBuffer


var _size: int
var _buffer: Array[Dictionary]


func _init(size: int) -> void:
	_size = size
	_buffer.resize(size)
	for i in size:
		_buffer[i] = {}


func insert(value: Dictionary) -> void:
	var index: int = value[&"time"] % _size
	_buffer[index] = value


func retrieve(timestamp: int) -> Dictionary:
	return _buffer[timestamp % _size]


func get_inner_array() -> Array[Dictionary]:
	return _buffer
