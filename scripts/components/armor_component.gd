extends Node
class_name ArmorComponent
## Manages armor that absorbs damage before health.

signal armor_changed(current_armor: float, max_armor: float)
signal armor_damaged(amount: float)
signal armor_broken()

@export_group("Armor")
@export var max_armor: float = 100.0
@export var current_armor: float = 100.0
@export var damage_reduction: float = 0.5  # Percentage of damage absorbed (0.5 = 50%)

@export_group("Armor Behavior")
@export var protects_head: bool = false  # Does armor protect headshots?
@export var breaks_on_zero: bool = true  # Does armor break when depleted?

# State
var is_broken: bool = false


func _ready() -> void:
	current_armor = max_armor
	armor_changed.emit(current_armor, max_armor)


## Absorb incoming damage
## Returns the remaining damage that passes through to health
func absorb_damage(damage: float, hit_location: String = "body") -> float:
	# Headshots bypass armor unless armor protects head
	if hit_location == "head" and not protects_head:
		return damage

	# Limb shots might have reduced armor effectiveness
	var effective_reduction: float = damage_reduction
	if hit_location == "limb":
		effective_reduction *= 0.5  # Armor is less effective on limbs

	if current_armor <= 0 or is_broken:
		return damage

	# Calculate how much damage armor absorbs
	var absorbed: float = damage * effective_reduction
	var armor_damage: float = absorbed  # Armor takes damage equal to absorbed amount

	# Apply damage to armor
	var actual_armor_damage: float = min(armor_damage, current_armor)
	current_armor -= actual_armor_damage

	armor_damaged.emit(actual_armor_damage)
	armor_changed.emit(current_armor, max_armor)

	# Check if armor is broken
	if current_armor <= 0 and breaks_on_zero:
		_break_armor()

	# Calculate remaining damage that passes through
	# If armor couldn't absorb all the damage it should have, pass extra through
	var absorbed_ratio: float = actual_armor_damage / armor_damage if armor_damage > 0 else 1.0
	var actual_absorbed: float = absorbed * absorbed_ratio
	var remaining: float = damage - actual_absorbed

	return remaining


## Repair armor by a certain amount
func repair(amount: float) -> float:
	if amount <= 0:
		return 0.0

	# Can't repair broken armor without replacing
	if is_broken:
		return 0.0

	var actual_repair: float = min(amount, max_armor - current_armor)
	current_armor += actual_repair

	if actual_repair > 0:
		armor_changed.emit(current_armor, max_armor)

	return actual_repair


## Set armor directly
func set_armor(value: float) -> void:
	current_armor = clamp(value, 0.0, max_armor)
	armor_changed.emit(current_armor, max_armor)

	if current_armor <= 0 and breaks_on_zero and not is_broken:
		_break_armor()


## Reset armor to max (for respawning)
func reset() -> void:
	is_broken = false
	current_armor = max_armor
	armor_changed.emit(current_armor, max_armor)


## Replace broken armor with new armor
func replace_armor(new_max: float, new_reduction: float = 0.5) -> void:
	max_armor = new_max
	current_armor = new_max
	damage_reduction = new_reduction
	is_broken = false
	armor_changed.emit(current_armor, max_armor)


## Get armor as a percentage (0-1)
func get_armor_percent() -> float:
	return current_armor / max_armor if max_armor > 0 else 0.0


## Check if armor is depleted
func is_depleted() -> bool:
	return current_armor <= 0


## Internal armor break handling
func _break_armor() -> void:
	if is_broken:
		return

	is_broken = true
	current_armor = 0.0
	armor_changed.emit(current_armor, max_armor)
	armor_broken.emit()
