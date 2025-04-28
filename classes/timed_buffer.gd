extends RefCounted
class_name TimedBuffer


var _size: int
var _buffer: Array[Dictionary]
var _head: int

var _stored_head: int

func _init(size: int) -> void:
	_size = size
	_head = 0
	_stored_head = -1
	_buffer.resize(size)
	for i in size:
		_buffer[i] = {}


func insert(value: Dictionary) -> void:
	var index: int = value[&"time"] % _size
	_buffer[index] = value
	_head = index


func retrieve(timestamp: int) -> Dictionary:
	var index := timestamp % _size
	return _buffer[index]


func get_inner_array() -> Array[Dictionary]:
	return _buffer


func get_current() -> Dictionary:
	return retrieve(_head)


func get_previous() -> Dictionary:
	_head -= 1
	return retrieve(_head)


func get_future() -> Dictionary:
	_head += 1
	return retrieve(_head)


func peek_previous() -> Dictionary:
	return retrieve(_head - 1)


func peek_future() -> Dictionary:
	return retrieve(_head + 1)


func store_head() -> void:
	_stored_head = _head


func reset_head() -> void:
	assert(_stored_head != -1)
	_head = _stored_head
	_stored_head = -1


func retrieve_latest() -> Dictionary:
	var last_inserted := get_current()

	store_head()
	while true:
		var future_value := get_future()
		if not future_value.is_empty() and future_value["time"] > last_inserted["time"]:
			last_inserted = future_value
		else:
			break
	reset_head()

	return last_inserted
