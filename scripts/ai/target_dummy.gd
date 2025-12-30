extends StaticBody3D
class_name TargetDummy
## A simple target for testing weapon damage.

@onready var health: HealthComponent = $HealthComponent
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _original_color: Color = Color(0.6, 0.3, 0.3)
var _hit_color: Color = Color(1.0, 0.5, 0.5)


func _ready() -> void:
	if health:
		health.damage_taken.connect(_on_damage_taken)
		health.died.connect(_on_died)
		health.health_changed.connect(_on_health_changed)


func _on_damage_taken(amount: float, _attacker: Node, hit_location: String) -> void:
	# Flash on hit
	if mesh and mesh.material_override:
		mesh.material_override.albedo_color = _hit_color

		await get_tree().create_timer(0.1).timeout

		if mesh and mesh.material_override and health and not health.is_dead:
			mesh.material_override.albedo_color = _original_color

	print("Target hit! Damage: %.1f, Location: %s, Health: %.1f" % [amount, hit_location, health.current_health])


func _on_died(_killer: Node) -> void:
	print("Target destroyed!")

	# Fall over animation
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation:x", deg_to_rad(90), 0.5)

	# Respawn after delay
	await get_tree().create_timer(3.0).timeout
	_respawn()


func _on_health_changed(current: float, max_health: float) -> void:
	# Update color based on health
	if mesh and mesh.material_override and not health.is_dead:
		var health_ratio: float = current / max_health
		mesh.material_override.albedo_color = _original_color.lerp(Color(0.2, 0.1, 0.1), 1.0 - health_ratio)


func _respawn() -> void:
	rotation.x = 0
	if health:
		health.reset()
	if mesh and mesh.material_override:
		mesh.material_override.albedo_color = _original_color
