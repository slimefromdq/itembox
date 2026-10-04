## A body: a named list of parts. Everything physical about the whole body
## (collider size, mass, center of mass) is computed from the parts on demand,
## so it can never fall out of sync with them.
class_name BodyDef
extends Resource

## Mass per cubic meter, the same for every part for now (HEAVY will scale it later).
## 10 makes the basketball weigh about 0.65 kg, close to a real one.
const DENSITY := 10.0
## The center of mass may sit at most this fraction of the collider radius away
## from the origin, so one heavy part can't make the body spin like a helicopter.
const COM_MAX_FRACTION := 0.25

@export var display_name: String = "Body"
@export var parts: Array[BodyPart] = []


## Radius of one sphere, centered on the body's origin, that contains every part.
## For each part: distance from origin to the part's center, plus how far the
## part reaches from its center. The biggest of those wins.
func get_collider_radius() -> float:
	var radius := 0.0
	for part in parts:
		radius = maxf(radius, part.position.length() + part.get_bounding_radius())
	return radius


func get_total_mass() -> float:
	var mass := 0.0
	for part in parts:
		mass += part.get_volume() * DENSITY
	return mass


## Mass-weighted average of part positions: big parts pull the center toward
## themselves more than small ones. Then clamped to stay near the origin.
func get_center_of_mass() -> Vector3:
	var total_mass := get_total_mass()
	if total_mass <= 0.0:
		return Vector3.ZERO
	var weighted_sum := Vector3.ZERO
	for part in parts:
		weighted_sum += part.position * part.get_volume() * DENSITY
	var com := weighted_sum / total_mass
	return com.limit_length(get_collider_radius() * COM_MAX_FRACTION)


func has_property(property: BodyPart.Property) -> bool:
	for part in parts:
		if part.property == property:
			return true
	return false


func get_parts_with(property: BodyPart.Property) -> Array[BodyPart]:
	var result: Array[BodyPart] = []
	for part in parts:
		if part.property == property:
			result.append(part)
	return result
