extends Area2D

# Export this so you can pick the next level in the Inspector
@export_file("*.tscn") var next_stage_path

@onready var nxt_lvl_sfx = $NxtLvl_SFX # Reference to the audio node

func _on_body_entered(body):
	# Check if the node that entered is the Player
	if body.is_in_group("Player"):
		# Use 'call_deferred' or a simple flag to prevent multiple triggers
		# if the player touches the area multiple times in one frame
		set_deferred("monitoring", false) 
		change_stage()

func change_stage():
	if next_stage_path == "":
		print("No next stage set!")
		return
		
	# 1. Play the transition sound
	if nxt_lvl_sfx:
		nxt_lvl_sfx.play()
	
	# 2. Wait a brief moment so the player hears the sound 
	# (Adjust 0.5 to match the length of your sound effect)
	await get_tree().create_timer(0.5).timeout
	
	# 3. Switch to the next level
	get_tree().change_scene_to_file(next_stage_path)
