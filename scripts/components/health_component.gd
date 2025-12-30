extends Node
class_name HealthComponent
## Manages health, damage, and death for characters.

signal health_changed(current_health: float, max_health: float)
signal damage_taken(amount: float, attacker: Node, hit_location: String)
signal healed(amount: float)
signal died(killer: Node)

@export_group("Health")
@export var max_health: float = 100.0
@export var current_health: float = 100.0

# State
var is_dead: bool = false
var _last_attacker: Node = null
var _last_damage_location: String = "body"


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Take damage from an attacker
## Returns actual damage dealt after any modifiers
func take_damage(amount: float, attacker: Node = null, hit_location: String = "body") -> float:
	if is_dead:
		return 0.0

	if amount <= 0:
		return 0.0

	_last_attacker = attacker
	_last_damage_location = hit_location

	# Check for armor component on parent
	var armor: ArmorComponent = _get_armor_component()
	var remaining_damage: float = amount

	if armor:
		remaining_damage = armor.absorb_damage(amount)

	# Apply damage to health
	var actual_damage: float = min(remaining_damage, current_health)
	current_health -= actual_damage

	damage_taken.emit(amount, attacker, hit_location)
	health_changed.emit(current_health, max_health)

	# Check for death
	if current_health <= 0:
		_die(attacker)

	return actual_damage


## Heal the character
func heal(amount: float) -> float:
	if is_dead:
		return 0.0

	if amount <= 0:
		return 0.0

	var actual_heal: float = min(amount, max_health - current_health)
	current_health += actual_heal

	if actual_heal > 0:
		healed.emit(actual_heal)
		health_changed.emit(current_health, max_health)

	return actual_heal


## Set health directly (for respawning, etc.)
func set_health(value: float) -> void:
	current_health = clamp(value, 0.0, max_health)
	health_changed.emit(current_health, max_health)

	if current_health <= 0 and not is_dead:
		_die(null)


## Reset health to max (for respawning)
func reset() -> void:
	is_dead = false
	current_health = max_health
	_last_attacker = null
	health_changed.emit(current_health, max_health)


## Get health as a percentage (0-1)
func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


## Check if at full health
func is_full_health() -> bool:
	return current_health >= max_health


## Internal death handling
func _die(killer: Node) -> void:
	if is_dead:
		return

	is_dead = true
	current_health = 0.0
	health_changed.emit(current_health, max_health)
	died.emit(killer)


## Find armor component on parent
func _get_armor_component() -> ArmorComponent:
	var parent: Node = get_parent()
	if parent:
		return parent.get_node_or_null("ArmorComponent") as ArmorComponent
	return null


## Get the last attacker (for kill credit)
func get_last_attacker() -> Node:
	return _last_attacker


## Get the last hit location
func get_last_damage_location() -> String:
	return _last_damage_location
