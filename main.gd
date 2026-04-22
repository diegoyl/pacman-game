extends Node


@export var mob_scene: PackedScene
@export var bonus_scene: PackedScene
var score

var _default_score_timer_wait: float
var _default_mob_timer_wait: float
var forced_bonus_idx: int = 0

const CLOCK_FAST_DURATION_SEC := 4.0
const CLOCK_FAST_MIN_SCORE_WAIT := 0.05

var _clock_fast_stack: int = 0
## Bumped on full reset so in-flight expiry timers from a previous run are ignored.
var _clock_fast_generation: int = 0

const MOB_FAST_DURATION_SEC := 3.0
const MOB_FAST_SPEED_BONUS_PER_STACK := 170.0
## Floor for mob speed magnitude when applying mob_fast expiry / reset (avoids zero or flip).
const MOB_SPEED_MAG_FLOOR := 80.0

var _mob_fast_stack: int = 0
## Bumped on full reset so in-flight mob_fast timers from a previous run are ignored.
var _mob_fast_generation: int = 0

const MOB_SLOW_DURATION_SEC := 4.0

var _mob_slow_stack: int = 0
## Bumped on full reset or when mob_fast clears slow; in-flight mob_slow timers compare to this.
var _mob_slow_generation: int = 0

var _music_pitch_ramp_tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_default_score_timer_wait = $ScoreTimer.wait_time
	_default_mob_timer_wait = $MobTimer.wait_time
	$Player.player_slow_music_pitch_changed.connect(_on_player_slow_music_pitch_changed)
	$Player.player_slow_music_pitch_ramped.connect(_on_player_slow_music_pitch_ramped)
	$Player.start($StartPosition.position)


func _reset_all_bonus_run_state() -> void:
	_reset_clock_fast_state()
	_reset_mob_fast_state()
	_reset_mob_slow_state()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over() -> void:
	
	$ScoreTimer.stop()
	_reset_all_bonus_run_state()
	$MobTimer.stop()
	
	$HUD.show_game_over(score)
	
	_kill_music_pitch_ramp_tween()
	$Music.stop()
	$Music.pitch_scale = 1.0
	$DeathSound.play()
	
	# wait for death animation to run
	await get_tree().create_timer(2.1).timeout
	$Player.start($StartPosition.position)
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("bonuses", "queue_free")
	
func new_game():
	$HUD/HiScoreBlinkTimer.stop()

	score = 0
	forced_bonus_idx = 0
	_reset_all_bonus_run_state()
	$StartTimer.start()
	$Player.start($StartPosition.position)
	
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")

	_kill_music_pitch_ramp_tween()
	$Music.pitch_scale = 1.0
	$Music.play()

func _on_mob_timer_timeout() -> void:
	create_mob()
	
	if score == 4 and forced_bonus_idx < 1:
		forced_bonus_idx = 1
		create_bonus("clock_fast")
		return
	elif score == 9 and forced_bonus_idx < 2:
		forced_bonus_idx = 2
		create_bonus("mob_slow")
		return
	elif score == 12 and forced_bonus_idx < 3:
		forced_bonus_idx = 3
		create_bonus("player_slow")
		return
	elif score == 16 and forced_bonus_idx < 4:
		forced_bonus_idx = 4
		create_bonus("mob_fast")
		return
	elif score > 5:
		const split := 0.3
		var random := randf()
		if random < split:
			create_bonus()
	
func create_mob():
	var mob = mob_scene.instantiate()

	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position

	var direction = mob_spawn_location.rotation + PI/2
	direction += randf_range(-PI/4, PI/4)
	mob.rotation = direction

	var speed_x := randf_range(150.0, 250.0) + MOB_FAST_SPEED_BONUS_PER_STACK * float(_mob_fast_stack)
	var velocity := Vector2(speed_x, 0.0).rotated(direction)
	if _mob_slow_stack > 0:
		var mag := velocity.length()
		if mag > 0.001:
			var new_mag := maxf(MOB_SPEED_MAG_FLOOR, mag * pow(0.5, float(_mob_slow_stack)))
			velocity = (velocity / mag) * new_mag
	mob.linear_velocity = velocity

	add_child(mob)
	if mob.has_method("set_mob_bonus_visual"):
		mob.set_mob_bonus_visual(_mob_fast_stack > 0, _mob_slow_stack > 0)
	
func create_bonus(forced_bonus_type: String = "") -> void:
	var bonus := bonus_scene.instantiate()
	if not forced_bonus_type.is_empty():
		bonus.set("bonus_type", forced_bonus_type)

	var spawn_location = $BonusPath/BonusSpawnLocation
	spawn_location.progress_ratio = randf()
	bonus.position = spawn_location.position

	var direction = spawn_location.rotation + PI/2
	direction += randf_range(-PI/4, PI/4)

	var velocity = Vector2(randf_range(200.0, 400.0), 0.0)
	bonus.linear_velocity = velocity.rotated(direction)

	add_child(bonus)
	

func _on_score_timer_timeout() -> void:
	score += 1
	
	$HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()


func _on_hud_start_game() -> void:
	pass # Replace with function body.


func _on_player_slow_music_pitch_changed(pitch_scale: float) -> void:
	_kill_music_pitch_ramp_tween()
	$Music.pitch_scale = pitch_scale


func _on_player_slow_music_pitch_ramped(target_pitch: float, duration_sec: float) -> void:
	_kill_music_pitch_ramp_tween()
	var tw := create_tween()
	_music_pitch_ramp_tween = tw
	tw.tween_property($Music, "pitch_scale", target_pitch, duration_sec).from_current()
	tw.finished.connect(_on_music_pitch_ramp_tween_finished)


func _kill_music_pitch_ramp_tween() -> void:
	if _music_pitch_ramp_tween != null and is_instance_valid(_music_pitch_ramp_tween):
		_music_pitch_ramp_tween.kill()
	_music_pitch_ramp_tween = null


func _on_music_pitch_ramp_tween_finished() -> void:
	_music_pitch_ramp_tween = null


func play_bonus_sound() -> void:
	$BonusSound.play()


func trigger_clock_fast() -> void:
	var gen := _clock_fast_generation
	_clock_fast_stack += 1
	_apply_clock_fast_to_score_timer()
	_sync_score_label_clock_fx_color()
	get_tree().create_timer(CLOCK_FAST_DURATION_SEC).timeout.connect(
		_on_clock_fast_timer_expired.bind(gen),
		CONNECT_ONE_SHOT
	)


func _on_clock_fast_timer_expired(expire_gen: int) -> void:
	if expire_gen != _clock_fast_generation:
		return
	_clock_fast_stack = maxi(0, _clock_fast_stack - 1)
	_apply_clock_fast_to_score_timer()
	_sync_score_label_clock_fx_color()


func _reset_clock_fast_state() -> void:
	_clock_fast_generation += 1
	_clock_fast_stack = 0
	_apply_clock_fast_to_score_timer()
	_sync_score_label_clock_fx_color()


func _apply_clock_fast_to_score_timer() -> void:
	var n: int = _clock_fast_stack
	var new_wait: float = maxf(
		CLOCK_FAST_MIN_SCORE_WAIT,
		_default_score_timer_wait * pow(0.5, n)
	)
	var timer := $ScoreTimer
	var was_running: bool = not timer.is_stopped()
	# Always stop before changing wait_time. Godot's Timer can desync time_left vs
	# wait_time if both are tweaked while running; scaling time_left + start(t)
	# could also clamp to tiny values and fire many timeouts in a row.
	timer.stop()
	timer.wait_time = new_wait
	if was_running:
		timer.start()


func _sync_score_label_clock_fx_color() -> void:
	$HUD.set_score_label_clock_fx_active(_clock_fast_stack > 0)


func trigger_mob_slow() -> void:
	_reset_mob_fast_state()
	var gen := _mob_slow_generation
	_mob_slow_stack += 1
	_multiply_all_mobs_linear_velocity(0.5)
	_sync_all_mobs_bonus_visual()
	_apply_mob_spawn_timer_for_bonus()
	get_tree().create_timer(MOB_SLOW_DURATION_SEC).timeout.connect(
		_on_mob_slow_timer_expired.bind(gen),
		CONNECT_ONE_SHOT
	)


func _on_mob_slow_timer_expired(expire_gen: int) -> void:
	if expire_gen != _mob_slow_generation:
		return
	_multiply_all_mobs_linear_velocity(2.0)
	_mob_slow_stack = maxi(0, _mob_slow_stack - 1)
	_sync_all_mobs_bonus_visual()
	_apply_mob_spawn_timer_for_bonus()


func _reset_mob_slow_state() -> void:
	var prev_stack := _mob_slow_stack
	_mob_slow_generation += 1
	_mob_slow_stack = 0
	if prev_stack > 0:
		_multiply_all_mobs_linear_velocity(pow(2.0, float(prev_stack)))
	_sync_all_mobs_bonus_visual()
	_apply_mob_spawn_timer_for_bonus()


func trigger_mob_fast() -> void:
	_reset_mob_slow_state()
	var gen := _mob_fast_generation
	_mob_fast_stack += 1
	_adjust_existing_mobs_speed_mag_delta(MOB_FAST_SPEED_BONUS_PER_STACK)
	_sync_all_mobs_bonus_visual()
	_apply_mob_spawn_timer_for_bonus()
	get_tree().create_timer(MOB_FAST_DURATION_SEC).timeout.connect(
		_on_mob_fast_timer_expired.bind(gen),
		CONNECT_ONE_SHOT
	)


func _on_mob_fast_timer_expired(expire_gen: int) -> void:
	if expire_gen != _mob_fast_generation:
		return
	_adjust_existing_mobs_speed_mag_delta(-MOB_FAST_SPEED_BONUS_PER_STACK)
	_mob_fast_stack = maxi(0, _mob_fast_stack - 1)
	_sync_all_mobs_bonus_visual()
	_apply_mob_spawn_timer_for_bonus()


func _reset_mob_fast_state() -> void:
	var prev_stack := _mob_fast_stack
	_mob_fast_generation += 1
	_mob_fast_stack = 0
	if prev_stack > 0:
		_adjust_existing_mobs_speed_mag_delta(-MOB_FAST_SPEED_BONUS_PER_STACK * float(prev_stack))
	_sync_all_mobs_bonus_visual()
	_apply_mob_spawn_timer_for_bonus()


## mob_fast: half spawn wait. mob_slow: 1.5x spawn wait. Mutually exclusive stacks; same-type stacks handled elsewhere.
func _apply_mob_spawn_timer_for_bonus() -> void:
	var new_wait: float
	if _mob_fast_stack > 0:
		new_wait = _default_mob_timer_wait * 0.5
	elif _mob_slow_stack > 0:
		new_wait = _default_mob_timer_wait * 1.5
	else:
		new_wait = _default_mob_timer_wait
	var timer := $MobTimer
	var was_running: bool = not timer.is_stopped()
	timer.stop()
	timer.wait_time = new_wait
	if was_running:
		timer.start()


func _sync_all_mobs_bonus_visual() -> void:
	var fast_active := _mob_fast_stack > 0
	var slow_active := _mob_slow_stack > 0
	for node in get_tree().get_nodes_in_group("mobs"):
		if not node is RigidBody2D:
			continue
		if node.has_method("set_mob_bonus_visual"):
			node.set_mob_bonus_visual(fast_active, slow_active)


func _multiply_all_mobs_linear_velocity(factor: float) -> void:
	for node in get_tree().get_nodes_in_group("mobs"):
		if not node is RigidBody2D:
			continue
		var rb := node as RigidBody2D
		var v := rb.linear_velocity
		var mag := v.length()
		if mag < 0.001:
			continue
		var new_mag: float = mag * factor
		if factor < 1.0:
			new_mag = maxf(MOB_SPEED_MAG_FLOOR, new_mag)
		rb.linear_velocity = (v / mag) * new_mag


## Shifts each mob's speed along its current direction (matches +bonus per pickup for on-screen mobs).
func _adjust_existing_mobs_speed_mag_delta(delta_mag: float) -> void:
	for node in get_tree().get_nodes_in_group("mobs"):
		if not node is RigidBody2D:
			continue
		var rb := node as RigidBody2D
		var v := rb.linear_velocity
		var mag := v.length()
		if mag < 0.001:
			continue
		var new_mag := maxf(MOB_SPEED_MAG_FLOOR, mag + delta_mag)
		rb.linear_velocity = (v / mag) * new_mag


func trigger_player_slow() -> void:
	$Player.apply_player_slow()
