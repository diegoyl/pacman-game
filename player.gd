extends Area2D

signal hit
## Emitted when player_slow should alter BGM rate (1.0 = normal). Uses AudioStreamPlayer.pitch_scale semantics.
signal player_slow_music_pitch_changed(pitch_scale: float)
## Smooth return to normal pitch over duration_sec (Main tweens $Music).
signal player_slow_music_pitch_ramped(target_pitch: float, duration_sec: float)

const PLAYER_SLOW_DURATION_SEC := 4.0
const PLAYER_SLOW_RECOVERY_RAMP_SEC := 1.0
const PLAYER_SLOW_MUSIC_PITCH_SCALE := 0.6

@export var speed = 400
var screen_size

var _default_speed: float
## Bumped on each new slow (extends timer) and on start(); expiry only clears if it matches latest.
var _player_slow_effect_generation: int = 0
var _player_slow_recovery_tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	_default_speed = speed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# check for input
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		velocity.x += -1
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_up"):
		velocity.y += -1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
		
#	# always play ghost animation	
	$AnimatedSprite2D.play()
	
	# play animations
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		#$AnimatedSprite2D.play()
	#else:
		#$AnimatedSprite2D.stop()
	
	# move player
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	if 	velocity.x != 0:
		$AnimatedSprite2D.animation = "left"
		#$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x > 0
	elif velocity.y != 0:
		if velocity.y < 0:
			$AnimatedSprite2D.animation = "up"
		else: 
			$AnimatedSprite2D.animation = "down"

		
		
		

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("mobs"):
		trigger_mob_death()
	elif body.is_in_group("bonuses"):
		_handle_bonus_pickup(body)
	else:
		pass


func _handle_bonus_pickup(body: Node2D) -> void:
	var main_node := get_parent()
	if main_node == null:
		return

	var bonus_type: Variant = body.get("bonus_type")
	body.queue_free()

	main_node.play_bonus_sound()

	if bonus_type == null:
		return

	match str(bonus_type):
		"clock_fast":
			main_node.trigger_clock_fast()
		"mob_slow":
			main_node.trigger_mob_slow()
		"mob_fast":
			main_node.trigger_mob_fast()
		"player_slow":
			main_node.trigger_player_slow()
		_:
			push_warning("Unknown bonus_type: %s" % bonus_type)


func trigger_mob_death():
	_cancel_player_slow_recovery_tween()
	# when it dies
	hit.emit()

	set_process(false)
	$AnimatedSprite2D.animation = "dead"
	$CollisionShape2D.set_deferred("disabled", true)
	

	
func start(pos):
	position = pos

	_cancel_player_slow_recovery_tween()
	_player_slow_effect_generation += 1
	speed = _default_speed
	var sprite := $AnimatedSprite2D
	sprite.speed_scale = 1.0

	set_process(true)
	$CollisionShape2D.disabled = false

	sprite.animation = "up"
	sprite.flip_h = false
	sprite.play()

	player_slow_music_pitch_changed.emit(1.0)


func apply_player_slow() -> void:
	_cancel_player_slow_recovery_tween()
	_player_slow_effect_generation += 1
	var gen := _player_slow_effect_generation
	speed = _default_speed * 0.35
	var sprite := $AnimatedSprite2D
	sprite.speed_scale = 0.25
	player_slow_music_pitch_changed.emit(PLAYER_SLOW_MUSIC_PITCH_SCALE)
	get_tree().create_timer(PLAYER_SLOW_DURATION_SEC).timeout.connect(
		_on_player_slow_timeout.bind(gen),
		CONNECT_ONE_SHOT
	)


func _on_player_slow_timeout(gen: int) -> void:
	if gen != _player_slow_effect_generation:
		return
	_begin_player_slow_recovery_ramp()


func _cancel_player_slow_recovery_tween() -> void:
	if _player_slow_recovery_tween != null and is_instance_valid(_player_slow_recovery_tween):
		_player_slow_recovery_tween.kill()
	_player_slow_recovery_tween = null


func _begin_player_slow_recovery_ramp() -> void:
	_cancel_player_slow_recovery_tween()
	var tw := create_tween()
	_player_slow_recovery_tween = tw
	tw.set_parallel(true)
	tw.tween_property(self, "speed", _default_speed, PLAYER_SLOW_RECOVERY_RAMP_SEC).from_current()
	tw.tween_property($AnimatedSprite2D, "speed_scale", 1.0, PLAYER_SLOW_RECOVERY_RAMP_SEC).from_current()
	tw.finished.connect(_on_player_slow_recovery_tween_finished)
	player_slow_music_pitch_ramped.emit(1.0, PLAYER_SLOW_RECOVERY_RAMP_SEC)


func _on_player_slow_recovery_tween_finished() -> void:
	_player_slow_recovery_tween = null
