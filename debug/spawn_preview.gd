## Milestone 2 check: drops every library body onto a floor so you can see
## the meshes, the bounce, and (with Debug > Visible Collision Shapes on)
## the one sphere collider per body. Press R to drop them again.
extends Node3D

const BODIES: Array[BodyDef] = [
	preload("res://bodies/library/basketball.tres"),
	preload("res://bodies/library/yellow_bug.tres"),
]
const DROP_HEIGHT := 3.0
const SPACING := 2.0

var _spawned: Array[RigidBody3D] = []


func _ready() -> void:
	_build_stage()
	_drop_all()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_drop_all()


func _drop_all() -> void:
	for body in _spawned:
		body.queue_free()
	_spawned.clear()

	for i in BODIES.size():
		var body := BodySpawner.spawn(BODIES[i])
		add_child(body)
		# Spread the bodies out in a row, centered on x = 0.
		var x := (i - (BODIES.size() - 1) / 2.0) * SPACING
		body.global_position = Vector3(x, DROP_HEIGHT, 0)
		_spawned.append(body)
		print("%s: mass %.2f kg, collider radius %.2f m, bounce %.2f" % [
			body.name, body.mass, BODIES[i].get_collider_radius(), body.physics_material_override.bounce,
		])


## A floor, a light, and a camera. Debug-only scenery, built in code to keep
## the .tscn trivial.
func _build_stage() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 1, 10)
	floor_shape.shape = box
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor_mesh.mesh = plane
	floor_body.add_child(floor_mesh)
	add_child(floor_body)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.shadow_enabled = true
	add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.5, 6)
	add_child(camera)
	camera.look_at(Vector3(0, 0.75, 0))
