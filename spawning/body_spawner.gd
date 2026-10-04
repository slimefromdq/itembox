## Turns a BodyDef (pure data) into a live RigidBody3D.
## The data never knows about this file; this file only reads the data.
class_name BodySpawner
extends RefCounted

## Metadata key under which the spawned body keeps its BodyDef, so later
## systems (sticky, cards) can look up which parts it's made of.
const META_BODY_DEF := &"body_def"

const BOUNCY_BOUNCE := 0.85
const DEFAULT_BOUNCE := 0.0
const DEFAULT_FRICTION := 0.8

## One shared material per palette color, so 30 basketballs share one material.
static var _materials: Dictionary = {}
static var _bouncy_material: PhysicsMaterial
static var _default_material: PhysicsMaterial


## Builds the node tree for a body. The caller adds it to the scene and
## sets its position.
##
##   RigidBody3D            mass, center of mass, physics material
##   ├── Collider           ONE sphere around the whole body
##   ├── Part0 (mesh)       one mesh per part, positioned and stretched
##   ├── Part1 (mesh)
##   └── ...
static func spawn(def: BodyDef) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = def.display_name.to_pascal_case()
	body.set_meta(META_BODY_DEF, def)

	body.mass = def.get_total_mass()
	body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	body.center_of_mass = def.get_center_of_mass()
	body.physics_material_override = _physics_material_for(def)
	# Kicked bodies move fast; continuous collision stops them tunneling
	# through thin walls between two physics frames.
	body.continuous_cd = true

	body.add_child(_build_collider(def))
	for i in def.parts.size():
		body.add_child(_build_part_mesh(def.parts[i], i))
	return body


## The player never authors a collider: it's always one sphere, centered on
## the body's origin, big enough to contain every part.
static func _build_collider(def: BodyDef) -> CollisionShape3D:
	var sphere := SphereShape3D.new()
	sphere.radius = def.get_collider_radius()
	var collider := CollisionShape3D.new()
	collider.name = "Collider"
	collider.shape = sphere
	return collider


## Each part is Godot's default mesh for its shape, moved to the part's
## position and scaled by its stretch. That matches exactly the base sizes
## BodyPart uses for its volume and radius math.
static func _build_part_mesh(part: BodyPart, index: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Part%d" % index
	mesh_instance.mesh = _mesh_for(part.shape)
	mesh_instance.position = part.position
	mesh_instance.scale = part.stretch
	mesh_instance.material_override = _material_for(part.color)
	return mesh_instance


static func _mesh_for(shape: BodyPart.Shape) -> Mesh:
	match shape:
		BodyPart.Shape.CUBE:
			return BoxMesh.new()
		BodyPart.Shape.CAPSULE:
			return CapsuleMesh.new()
		BodyPart.Shape.CYLINDER:
			return CylinderMesh.new()
		_:
			return SphereMesh.new()


static func _material_for(color: BodyPart.PaletteColor) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = BodyPart.PALETTE[color]
		_materials[color] = material
	return _materials[color]


## Bounciness is a property of the whole body: if any part is bouncy, the
## body gets the bouncy physics material.
static func _physics_material_for(def: BodyDef) -> PhysicsMaterial:
	if def.has_property(BodyPart.Property.BOUNCY):
		if _bouncy_material == null:
			_bouncy_material = PhysicsMaterial.new()
			_bouncy_material.bounce = BOUNCY_BOUNCE
			_bouncy_material.friction = DEFAULT_FRICTION
		return _bouncy_material
	if _default_material == null:
		_default_material = PhysicsMaterial.new()
		_default_material.bounce = DEFAULT_BOUNCE
		_default_material.friction = DEFAULT_FRICTION
	return _default_material
