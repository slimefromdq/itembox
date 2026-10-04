## Milestone 1 check: loads every body in the library and prints its
## computed values. No 3D yet; just read the Output panel.
extends Node

const BODIES: Array[BodyDef] = [
	preload("res://bodies/library/basketball.tres"),
	preload("res://bodies/library/yellow_bug.tres"),
]


func _ready() -> void:
	for body in BODIES:
		print_body(body)


func print_body(body: BodyDef) -> void:
	print("== %s ==" % body.display_name)
	for part in body.parts:
		print("  %-8s at %s  stretch %s  %-6s %-6s  volume %.3f" % [
			BodyPart.Shape.keys()[part.shape],
			part.position,
			part.stretch,
			BodyPart.PaletteColor.keys()[part.color],
			BodyPart.Property.keys()[part.property],
			part.get_volume(),
		])
	print("  collider radius: %.3f m" % body.get_collider_radius())
	print("  total mass:      %.3f kg" % body.get_total_mass())
	print("  center of mass:  %s" % body.get_center_of_mass())
	print("  bouncy? %s   sticky parts: %d" % [
		body.has_property(BodyPart.Property.BOUNCY),
		body.get_parts_with(BodyPart.Property.STICKY).size(),
	])
	print("")
