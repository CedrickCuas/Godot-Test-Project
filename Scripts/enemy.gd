extends CharacterBody2D

var health: int = 3

func take_damage(amount: int):
	health -= amount
	print("Enemy hit! Health remaining: ", health)
	
	if health <= 0:
		die()

func die():
	# Play death animation or just remove them
	queue_free()
