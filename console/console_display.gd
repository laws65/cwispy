extends Control


func _ready() -> void:
	Console.message_received.connect(_on_message_received)


func _on_message_received(message: String, tags: int=0) -> void:
	return
	$"%TextDisplay".text += message + "\n"
