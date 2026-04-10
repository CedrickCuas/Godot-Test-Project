extends Area2D

@export var speed: float = 400.0
@export var damage: int = 1

func _physics_process(delta: float):
	position += transform.x * speed * delta

# This is the function Godot is ACTUALLY calling (based on your screenshot)
func _on_body_entered(body: Node2D):
	if body.name == "Player":
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	
	elif body is StaticBody2D or body is TileMapLayer:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
