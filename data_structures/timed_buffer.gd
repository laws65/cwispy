extends RefCounted
class_name TimedBuffer


# TODO work on input misses from temp inputs from synchroniser.gd messing up everything
var _size: int
var _buffer: Array[Dictionary]
var _head: int
var _greatest: int = 0

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
	_greatest = max(value[&"time"], _greatest)


func retrieve(timestamp: int) -> Dictionary:
	assert(timestamp > 0)

	var index := timestamp % _size
	if _buffer[index] and _buffer[index]["time"] != timestamp:
		return {}
		#print_stack()
		print(timestamp, " : " ,_buffer[index]["time"])
		#print("WTF SOMETHING WRONG")
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
	return _buffer[_greatest % _size]


func retrieve_at_or_before(timestamp: int) -> Dictionary:
	var index := timestamp % _size
	var direct_element := _buffer[index]

	if direct_element.is_empty():
		# the buffer hasn't been populated yet, therefore the correct element doesn't exist yet
		return {}

	if direct_element["time"] == timestamp:
		return direct_element

	store_head()
	while true:
		var older_state := get_previous()
		if older_state["time"] < timestamp:
			reset_head()
			return older_state

	return _buffer[index]
