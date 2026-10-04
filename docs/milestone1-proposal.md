# Milestone 1 proposal: layout, BodyPart, BodyDef

Nothing here is written as real code yet. Confirm (or change) this and I'll build it.

## 1. Folder layout

**Idea:** each folder is one layer, and a layer only knows about the layers above it.
`bodies/` is pure data and knows nothing about physics nodes. `spawning/` reads bodies
and builds nodes. `behaviors/` (sticky, later heavy/spiky) hooks onto spawned nodes.
That keeps the future card system free to slot in as one more data layer next to `bodies/`.

```
itembox/
├── project.godot
├── bodies/                  # M1: pure data, no nodes
│   ├── body_part.gd         # class_name BodyPart  (Resource)
│   ├── body_def.gd          # class_name BodyDef   (Resource)
│   └── library/             # hand-authored bodies
│       ├── basketball.tres
│       └── yellow_bug.tres
├── debug/
│   └── body_report.tscn/.gd # M1: prints each body's computed values so you can run it
├── spawning/                # M2: body_spawner.gd  (BodyDef -> RigidBody3D)
├── test_range/              # M3: room scene, player, kick/cycle/reset
└── behaviors/               # M4: sticky.gd
```

Later layers (editor, cards/verbs, networking) get their own folders; none of them
needs to change `bodies/`.

## 2. Units and conventions

**Idea:** every shape starts as Godot's own default mesh for that shape, then gets
scaled by `stretch`. That way the data, the mesh, and the math all agree on what
"a cube with stretch (1,1,1)" means, and volume is just
`base_volume(shape) × stretch.x × stretch.y × stretch.z`.

| Shape    | Base (stretch = 1,1,1)          | Base volume        |
|----------|---------------------------------|--------------------|
| SPHERE   | radius 0.5 (1 m wide)           | 4/3·π·0.5³ ≈ 0.524 |
| CUBE     | 1 × 1 × 1                       | 1.0                |
| CAPSULE  | radius 0.5, height 2            | π·0.25·1 + 4/3·π·0.125 ≈ 1.309 |
| CYLINDER | radius 0.5, height 2            | π·0.25·2 ≈ 1.571   |

- Units are meters. Part positions are relative to the body's origin (its pivot).
- Grid step is **0.25 m**; `position` snaps itself whenever it's set.
- `stretch` is clamped to a minimum of 0.1 per axis so nothing has zero volume.
- No per-part rotation yet (not in the spec). Easy to add as another field later.
- Density is 1.0 for every part for now. HEAVY will later just multiply it.

## 3. BodyPart (`bodies/body_part.gd`)

**Idea:** one part is one primitive. It holds only what a player would pick in an
editor: shape, where, how stretched, which color, which property. The palette is a
fixed enum so a part stores a small index (easy to save and send over a network later),
and the actual `Color` is looked up from it.

```gdscript
class_name BodyPart
extends Resource

enum Shape { SPHERE, CUBE, CAPSULE, CYLINDER }
enum Property { NONE, STICKY, HEAVY, BOUNCY, SPIKY }
enum PaletteColor { RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, WHITE, BLACK }

const GRID_STEP := 0.25
const MIN_STRETCH := 0.1
const PALETTE: Array[Color] = [ ...8 colors in enum order... ]

@export var shape: Shape = Shape.SPHERE
@export var position: Vector3 = Vector3.ZERO   # setter snaps to GRID_STEP
@export var stretch: Vector3 = Vector3.ONE     # setter clamps to MIN_STRETCH
@export var color: PaletteColor = PaletteColor.WHITE
@export var property: Property = Property.NONE

func get_color() -> Color          # PALETTE[color]
func get_volume() -> float         # base volume of shape × stretch product
func get_half_extents() -> Vector3 # base half-size × stretch (used for radius)
func get_bounding_radius() -> float # how far the part reaches from its own center
```

## 4. BodyDef (`bodies/body_def.gd`)

**Idea:** a body is just a named list of parts. Everything physical (collider size,
mass, center of mass) is *computed* from the parts, never stored, so it can't drift
out of sync when a part changes. They're cheap functions, called once at spawn time.

```gdscript
class_name BodyDef
extends Resource

const DENSITY := 1.0                 # mass per cubic meter, for every part (for now)
const COM_MAX_FRACTION := 0.25       # center of mass may sit at most 25% of the radius off-origin

@export var display_name: String = "Body"
@export var parts: Array[BodyPart] = []

func get_collider_radius() -> float  # max over parts of |part.position| + part.get_bounding_radius()
func get_total_mass() -> float       # sum of part volumes × DENSITY
func get_center_of_mass() -> Vector3 # mass-weighted average of part positions,
                                     # then clamped to length ≤ COM_MAX_FRACTION × radius
func has_property(p: BodyPart.Property) -> bool  # e.g. "is anything bouncy?" for M2
func get_parts_with(p: BodyPart.Property) -> Array[BodyPart]  # for sticky lookups in M4
```

The collider sphere is centered on the body origin rather than being the mathematically
smallest sphere. That's slightly looser but means the pivot, the collider, and the
mesh positions all share one center, which keeps M2 and M4 simple.

## 5. The two bodies (`bodies/library/*.tres`)

Hand-written `.tres` files, so you can also open and tweak them in the Inspector.

- **Basketball:** one SPHERE, stretch (0.5, 0.5, 0.5), ORANGE, BOUNCY, at the origin.
- **Yellow bug:** a YELLOW SPHERE body at the origin (stretch 1,1,1), two small WHITE
  eye spheres at (±0.25, 0.25, −0.5) with stretch 0.25, and a BLACK CUBE nose at
  (0, 0, −0.5) with stretch 0.25, marked STICKY. (−Z is "forward" in Godot.)

## 6. How you'll run Milestone 1

Open the project, run `debug/body_report.tscn`, and the Output panel prints each body's
part count, collider radius, total mass, and center of mass. No 3D yet; that's M2.
