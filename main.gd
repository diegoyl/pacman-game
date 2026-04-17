extends Node


@export var mob_scene: PackedScene
var score



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Player.start($StartPosition.position)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over() -> void:
	
	$ScoreTimer.stop()
	$MobTimer.stop()
	
	$HUD.show_game_over(score)
	
	$Music.stop()
	$DeathSound.play()
	
	# wait for death animation to run
	await get_tree().create_timer(2.1).timeout
	$Player/AnimatedSprite2D.animation = "up"
	$Player.start($StartPosition.position)
	get_tree().call_group("mobs", "queue_free")
	
func new_game():
	$HUD/HiScoreBlinkTimer.stop()

	score = 0
	$StartTimer.start()
	$Player.start($StartPosition.position)
	
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")

	$Music.play()

func _on_mob_timer_timeout() -> void:
	# create instance
	var mob = mob_scene.instantiate()
	print(mob)
	
	# choose location on path
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	mob.position = mob_spawn_location.position

	
	# set mob direction away from path
	var direction = mob_spawn_location.rotation + PI/2
	
	# add randomness to direction
	direction += randf_range(-PI/4, PI/4)
	mob.rotation = direction
	
	# choose velocity
	var velocity = Vector2(randf_range(150.0,250.0),0)
	mob.linear_velocity = velocity.rotated(direction)
	
	# spawn the mob by adding to scene
	add_child(mob)
	

func _on_score_timer_timeout() -> void:
	score += 1
	
	$HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()


func _on_hud_start_game() -> void:
	pass # Replace with function body.
