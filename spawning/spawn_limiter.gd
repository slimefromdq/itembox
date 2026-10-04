## Keeps track of live spawned bodies and caps how many exist at once.
## When a new body pushes the count over the limit, the oldest one pops.
## Lives in spawning/ because it only manages nodes; it knows nothing about
## kicking or players.
class_name SpawnLimiter
extends Node

signal count_changed(count: int)

@export var max_bodies := 30

## Oldest first.
var _live: Array[RigidBody3D] = []


## Call after adding a freshly spawned body to the scene.
func track(body: RigidBody3D) -> void:
	_live.append(body)
	# However the body leaves (popped here, freed by a later behavior, or the
	# room resetting), drop it from the list so we never hold a dead node.
	body.tree_exiting.connect(_forget.bind(body), CONNECT_ONE_SHOT)
	while _live.size() > max_bodies:
		pop_oldest()
	count_changed.emit(_live.size())


func pop_oldest() -> void:
	if _live.is_empty():
		return
	var oldest: RigidBody3D = _live[0]
	_forget(oldest)
	oldest.queue_free()


func count() -> int:
	return _live.size()


func _forget(body: RigidBody3D) -> void:
	var index := _live.find(body)
	if index != -1:
		_live.remove_at(index)
		count_changed.emit(_live.size())
