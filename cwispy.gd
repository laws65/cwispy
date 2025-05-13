@tool
extends EditorPlugin


const AUTOLOADS = [
	{name="Multiplayer", path="res://addons/cwispy/singletons/multiplayer.gd"},
	{name="Clock", path="res://addons/cwispy/singletons/clock.gd"},
	{name="GameManager", path="res://addons/cwispy/singletons/game_manager.gd"},
	{name="ServerTicker", path="res://addons/cwispy/singletons/server_ticker.gd"},
	{name="SnapshotManager", path="res://addons/cwispy/singletons/snapshot_manager.gd"},
	{name="Synchroniser", path="res://addons/cwispy/singletons/synchroniser.gd"},
	{name="NetworkedInput", path="res://addons/cwispy/singletons/networked_input.gd"},
	{name="Console", path="res://addons/cwispy/console/console.gd"}
]


func _enter_tree() -> void:
	for autoload in AUTOLOADS:
		if ProjectSettings.get_setting("autoload/" + autoload.name) != "*" + autoload.path:
			add_autoload_singleton(autoload.name, autoload.path)


func _exit_tree() -> void:
	for autoload in AUTOLOADS:
		remove_autoload_singleton(autoload.name)
