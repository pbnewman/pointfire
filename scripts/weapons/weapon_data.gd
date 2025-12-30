extends Resource
class_name WeaponData
## Resource containing all data for a weapon.
## Create .tres files for each weapon using this class.

@export_group("Basic Info")
@export var weapon_name: String = "Weapon"
@export var weapon_id: String = "weapon"
@export_enum("primary", "secondary", "melee") var slot: String = "primary"

@export_group("Damage")
@export var damage: float = 30.0
@export var headshot_multiplier: float = 2.5
@export var limb_multiplier: float = 0.75
@export var damage_falloff_start: float = 20.0  # Distance where falloff begins
@export var damage_falloff_end: float = 50.0    # Distance where min damage reached
@export var min_damage_multiplier: float = 0.5  # Minimum damage at max range

@export_group("Fire Rate & Ammo")
@export var fire_rate: float = 0.1  # Seconds between shots
@export var is_automatic: bool = true
@export var magazine_size: int = 30
@export var reserve_ammo: int = 90
@export var reload_time: float = 2.0

@export_group("Accuracy")
@export var hipfire_spread: float = 4.0  # Degrees of spread
@export var ads_spread: float = 0.5
@export var movement_spread_penalty: float = 2.0  # Added spread while moving
@export var crouch_spread_bonus: float = 0.5  # Multiplier (lower = more accurate)

@export_group("Recoil")
@export var recoil_vertical: float = 1.5  # Degrees per shot
@export var recoil_horizontal_range: float = 0.5  # Random horizontal range
@export var recoil_recovery_speed: float = 5.0  # How fast recoil recovers
@export var ads_recoil_multiplier: float = 0.7  # Reduced recoil when ADS

@export_group("Handling")
@export var ads_time: float = 0.25  # Time to fully ADS
@export var ads_fov_multiplier: float = 0.8  # FOV zoom when ADS
@export var weapon_weight: float = 1.0  # Affects movement speed
@export var swap_in_time: float = 0.5  # Time to equip
@export var swap_out_time: float = 0.3  # Time to unequip

@export_group("Audio")
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
@export var empty_sound: AudioStream

@export_group("Visuals")
@export var muzzle_flash_scene: PackedScene
@export var impact_effect_scene: PackedScene
@export var tracer_scene: PackedScene


## Calculate damage at a given distance
func get_damage_at_distance(distance: float) -> float:
	if distance <= damage_falloff_start:
		return damage
	elif distance >= damage_falloff_end:
		return damage * min_damage_multiplier
	else:
		var falloff_range: float = damage_falloff_end - damage_falloff_start
		var falloff_progress: float = (distance - damage_falloff_start) / falloff_range
		var multiplier: float = lerp(1.0, min_damage_multiplier, falloff_progress)
		return damage * multiplier


## Calculate final damage based on hit location and distance
func calculate_damage(distance: float, hit_location: String) -> float:
	var base_damage: float = get_damage_at_distance(distance)

	match hit_location:
		"head":
			return base_damage * headshot_multiplier
		"limb":
			return base_damage * limb_multiplier
		_:  # body
			return base_damage
