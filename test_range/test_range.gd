## The test room's own logic: the reset key and the on-screen info.
## The room itself (floor, wall, ramp, dummies) is laid out in test_range.tscn
## so you can move things around in the editor.
extends Node3D

@onready var _player = $Player
@onready var _limiter: SpawnLimiter = $SpawnLimiter
@onready var _info: Label = $HUD/Info

var _selected_name := ""


func _ready() -> void:
	_player.selection_changed.connect(_on_selection_changed)
	_limiter.count_changed.connect(_on_count_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_room"):
		# Reloading the scene puts every dummy back and frees every spawned
		# body in one go, with no bookkeeping to get wrong.
		get_tree().reload_current_scene()


func _on_selection_changed(def: BodyDef) -> void:
	_selected_name = def.display_name if def else "(none)"
	_refresh_info()


func _on_count_changed(_count: int) -> void:
	_refresh_info()


func _refresh_info() -> void:
	_info.text = "Body: %s   Live: %d/%d\nClick/F kick · Q cycle · R reset · Esc free mouse" % [
		_selected_name, _limiter.count(), _limiter.max_bodies,
	]
