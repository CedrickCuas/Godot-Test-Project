extends CharacterBody2D

@export var arrow_scene : PackedScene

const SPEED = 100.0
const JUMP_VELOCITY = -325.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking = false 
var is_dead = false # Keeps track of the death state

@onready var animated_sprite = $AnimatedSprite2D
@onready var melee_hitbox = $MeleeHitbox
@onready var sfx_death = $SFX_Death 
@onready var sfx_sword = $SFX_Sword 
@onready var sfx_bow = $SFX_Bow 

var health = 3

func take_damage(amount):
	if is_dead: # Don't take damage if already dead
		return
		
	health -= amount
	print("Player Health: ", health)
	
	if health <= 0:
		die()

func die():
	is_dead = true # Set death state
	print("Player Died!")
	
	if sfx_death:
		sfx_death.play()
	
	velocity = Vector2.ZERO
	set_physics_process(false) 
	
	animated_sprite.play("Death")
	
	await animated_sprite.animation_finished
	
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# --- HANDLE ATTACK INPUTS ---
	if Input.is_action_just_pressed("Attack") and not is_attacking:
		attack() 
		
	if Input.is_action_just_pressed("Range_Attack") and not is_attacking:
		shoot()

	var direction := Input.get_axis("move_left", "move_right")

	# --- HANDLE FLIPPING ---
	if direction > 0:
		animated_sprite.flip_h = false
		melee_hitbox.scale.x = 1 
		if has_node("Muzzle"):
			$Muzzle.position.x = abs($Muzzle.position.x)
	elif direction < 0:
		animated_sprite.flip_h = true
		melee_hitbox.scale.x = -1 
		if has_node("Muzzle"):
			$Muzzle.position.x = -abs($Muzzle.position.x)

	# --- ANIMATION CONTROLLER ---
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("Idle")
			else:
				animated_sprite.play("Moving")
		else:
			animated_sprite.play("Moving")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

# --- ATTACK FUNCTIONS ---

func attack():
	is_attacking = true
	if sfx_sword:
		sfx_sword.play()
	animated_sprite.play("Attack 1")
	$MeleeTimer.start()

func _on_melee_timer_timeout():
	melee_hitbox.monitoring = false
	melee_hitbox.monitoring = true

func shoot():
	is_attacking = true
	animated_sprite.play("Shooting")
	
	# --- ADDED 0.3 SECOND DELAY FOR SOUND ---
	# We create a one-shot timer so the sound waits for the bow string to snap
	await get_tree().create_timer(0.4).timeout
	
	# Only play if we didn't die or cancel the animation during those 0.3s
	if is_attacking and sfx_bow:
		sfx_bow.play()
		
	$ShotTimer.start()

func _on_shot_timer_timeout():
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		arrow.global_position = $Muzzle.global_position
		arrow.rotation = PI if animated_sprite.flip_h else 0.0

func _on_melee_hitbox_body_entered(body: Node2D):
	if is_attacking and body.has_method("take_damage"):
		body.take_damage(1)
		print("Sword hit!")
		melee_hitbox.set_deferred("monitoring", false)

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation == "Attack 1" or animated_sprite.animation == "Shooting":
		is_attacking = false
		melee_hitbox.monitoring = false
