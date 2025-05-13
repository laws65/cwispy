extends Node

var messages: Array[String]

signal message_received(message: String, tags: int)


var console_display_packed_scene := preload("res://addons/cwispy/console/console_display.tscn")
var console_display
var cl := CanvasLayer.new()
func _ready() -> void:
	cl.layer = 101
	add_child(cl)

	console_display = console_display_packed_scene.instantiate()
	console_display.hide()
	cl.add_child(console_display)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_console"):
		console_display.visible = not console_display.visible


func add_message(message: String, tags: int = 0) -> void:
	messages.push_back(message)
	message_received.emit(message, tags)
