extends CharacterBody2D

# Movement & AI Constants
const SPEED = 60.0
const JUMP_VELOCITY = -380.0
const AGGRO_RANGE = 250.0 
const ROAM_RADIUS = 100.0
const ATTACK_COOLDOWN_TIME = 1.2

# State Variables
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null
var roam_direction = 1
var can_jump = true
var is_dead = false
var is_aggroed = false
var is_attacking = false
var is_cooldown = false

@onready var home_position_x = global_position.x
@onready var animated_sprite = $AnimatedSprite2D
@onready var eyes = $Eyes 
@onready var attack_area = $Enemy_Attack_Area
@onready var sfx_enemy_death = $Enemy_Death 
@onready var sfx_enemy_attack = $Enemy_Attack 

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# --- SIGHT LOGIC ---
	var distance_to_player = 10000.0
	if player:
		distance_to_player = global_position.distance_to(player.global_position)
		eyes.target_position = to_local(player.global_position)
		
		if eyes.is_colliding() and eyes.get_collider() == player and distance_to_player < AGGRO_RANGE:
			is_aggroed = true
		else:
			is_aggroed = false

	# --- DECISION LOGIC ---
	if is_attacking:
		velocity.x = 0
		if not is_cooldown:
			perform_attack()
	elif is_aggroed:
		var dir = sign(player.global_position.x - global_position.x)
		velocity.x = dir * SPEED
		animated_sprite.play("Walking_Enemy")
		
		if is_on_floor() and can_jump:
			var player_is_above = player.global_position.y < (global_position.y - 45)
			var horizontal_diff = abs(player.global_position.x - global_position.x)
			if is_on_wall() or (player_is_above and horizontal_diff > 35):
				jump()
	else:
		velocity.x = roam_direction * (SPEED * 0.5)
		animated_sprite.play("Walking_Enemy")
		var dist = global_position.x - home_position_x
		if is_on_wall() or abs(dist) > ROAM_RADIUS:
			roam_direction *= -1

	# --- DIRECTION FLIPPING ---
	if velocity.x > 0:
		animated_sprite.flip_h = false
		attack_area.scale.x = 1
	elif velocity.x < 0:
		animated_sprite.flip_h = true
		attack_area.scale.x = -1

	move_and_slide()

func perform_attack():
	is_cooldown = true
	
	# Start the animation first
	animated_sprite.play("Attack_Enemy")
	
	# --- ADDED 0.4 SECOND DELAY FOR SOUND ---
	await get_tree().create_timer(0.4).timeout
	
	# Play sound if the enemy didn't die during the delay
	if not is_dead and sfx_enemy_attack:
		sfx_enemy_attack.play()
	
	# Note: We don't need another timer for the damage because the 0.4s 
	# timer already acts as the 'wind-up' delay.
	if attack_area.overlaps_body(player):
		player.take_damage(1)
		
	await get_tree().create_timer(ATTACK_COOLDOWN_TIME).timeout
	is_cooldown = false

func _on_attack_area_body_entered(body):
	if body == player: is_attacking = true

func _on_attack_area_body_exited(body):
	if body == player: is_attacking = false

func jump():
	velocity.y = JUMP_VELOCITY
	can_jump = false
	await get_tree().create_timer(1.0).timeout
	can_jump = true

func take_damage(amount):
	is_dead = true
	velocity = Vector2.ZERO
	
	if sfx_enemy_death:
		sfx_enemy_death.play()
		
	animated_sprite.play("Death_Enemy")
	await animated_sprite.animation_finished
	queue_free()
