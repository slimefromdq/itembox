## A simple third-person player: WASD to move, mouse to look, Space to jump.
## Kick spawns the selected body in front of you and launches it where the
## camera is looking. The player only decides WHAT and WHERE; building the
## body is BodySpawner's job, and the 30-body cap is SpawnLimiter's job.
extends CharacterBody3D

signal selection_changed(def: BodyDef)

const MOVE_SPEED := 6.0
const JUMP_VELOCITY := 5.0
const MOUSE_SENSITIVITY := 0.003
const MIN_PITCH := deg_to_rad(-70)
const MAX_PITCH := deg_to_rad(40)

## Every kicked body leaves at this speed, whatever its mass. A heavy body
## then hits harder because it carries more momentum, not because it flies slower.
const KICK_SPEED := 14.0
## Aim a little above the crosshair so bodies arc instead of skimming the floor.
const KICK_LIFT := 0.15
## Gap between the player's capsule and the spawned body's collider.
const SPAWN_GAP := 0.2
const PLAYER_RADIUS := 0.4
const CHEST_HEIGHT := 1.2

@export var bodies: Array[BodyDef] = []
@export var spawn_limiter: SpawnLimiter
## Spawned bodies are added here (the room), not under the player, so they
## don't move when the player moves.
@export var spawn_parent: Node3D

var selected_index := 0

@onready var _pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Keep the camera arm from colliding with the player's own capsule.
	$CameraPivot/SpringArm3D.add_excluded_object(get_rid())
	selection_changed.emit.call_deferred(selected_body())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		_pivot.rotation.x = clampf(_pivot.rotation.x - event.relative.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# First click after releasing the mouse just recaptures it, no kick.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("kick"):
		kick()
	elif event.is_action_pressed("cycle_body"):
		cycle_body()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED
	move_and_slide()


func selected_body() -> BodyDef:
	return bodies[selected_index] if not bodies.is_empty() else null


func cycle_body() -> void:
	if bodies.is_empty():
		return
	selected_index = (selected_index + 1) % bodies.size()
	selection_changed.emit(selected_body())


func kick() -> void:
	var def := selected_body()
	if def == null:
		return
	var aim := (-_camera.global_basis.z + Vector3.UP * KICK_LIFT).normalized()
	# Start far enough out that the body's collider doesn't overlap the player.
	var distance := PLAYER_RADIUS + def.get_collider_radius() + SPAWN_GAP
	var start := global_position + Vector3.UP * CHEST_HEIGHT + aim * distance

	var body := BodySpawner.spawn(def)
	spawn_parent.add_child(body)
	body.global_position = start
	# Face the body the way it's kicked, so the bug flies nose-first.
	body.look_at(start + aim)
	# The kick impulse, written as the velocity it produces (impulse = mass x
	# velocity change). Setting the velocity directly is more reliable on the
	# body's first frame than apply_central_impulse, which can run before the
	# physics engine has picked up the new mass.
	body.linear_velocity = aim * KICK_SPEED
	spawn_limiter.track(body)
