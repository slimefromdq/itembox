## One primitive in a body: a shape, where it sits, how it's stretched,
## its color, and its physical property. Pure data, no nodes.
class_name BodyPart
extends Resource

enum Shape { SPHERE, CUBE, CAPSULE, CYLINDER }
enum Property { NONE, STICKY, HEAVY, BOUNCY, SPIKY }
enum PaletteColor { RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, WHITE, BLACK }

const GRID_STEP := 0.25
const MIN_STRETCH := 0.1

## Actual colors, in the same order as PaletteColor.
const PALETTE: Array[Color] = [
	Color("e63946"), # RED
	Color("f4842d"), # ORANGE
	Color("ffd23f"), # YELLOW
	Color("4caf50"), # GREEN
	Color("3a86ff"), # BLUE
	Color("8e44ad"), # PURPLE
	Color("f5f5f5"), # WHITE
	Color("222222"), # BLACK
]

## Each shape starts as Godot's default mesh for that shape (before stretch).
## Half-size of that default mesh along each axis:
const BASE_HALF_EXTENTS := {
	Shape.SPHERE: Vector3(0.5, 0.5, 0.5),   # radius 0.5
	Shape.CUBE: Vector3(0.5, 0.5, 0.5),     # 1 x 1 x 1
	Shape.CAPSULE: Vector3(0.5, 1.0, 0.5),  # radius 0.5, height 2
	Shape.CYLINDER: Vector3(0.5, 1.0, 0.5), # radius 0.5, height 2
}

## Volume of that default mesh:
const BASE_VOLUME := {
	Shape.SPHERE: 4.0 / 3.0 * PI * 0.125,             # 4/3·π·r³
	Shape.CUBE: 1.0,
	Shape.CAPSULE: PI * 0.25 * 1.0 + 4.0 / 3.0 * PI * 0.125, # cylinder middle + two half-sphere caps
	Shape.CYLINDER: PI * 0.25 * 2.0,                  # π·r²·h
}

@export var shape: Shape = Shape.SPHERE

## Offset from the body's origin. Always snapped to the grid.
@export var position: Vector3 = Vector3.ZERO:
	set(value):
		position = value.snapped(Vector3.ONE * GRID_STEP)

## Per-axis scale of the base shape. Never smaller than MIN_STRETCH.
@export var stretch: Vector3 = Vector3.ONE:
	set(value):
		stretch = value.max(Vector3.ONE * MIN_STRETCH)

@export var color: PaletteColor = PaletteColor.WHITE
@export var property: Property = Property.NONE


func get_color() -> Color:
	return PALETTE[color]


## Scaling a shape by (x, y, z) scales its volume by x·y·z.
func get_volume() -> float:
	return BASE_VOLUME[shape] * stretch.x * stretch.y * stretch.z


func get_half_extents() -> Vector3:
	return BASE_HALF_EXTENTS[shape] * stretch


## How far this part reaches from its own center, in any direction.
## Spheres reach exactly their largest half-extent; the other shapes are
## measured to their box corner, which is a little generous but always safe.
func get_bounding_radius() -> float:
	var e := get_half_extents()
	if shape == Shape.SPHERE:
		return maxf(e.x, maxf(e.y, e.z))
	return e.length()
