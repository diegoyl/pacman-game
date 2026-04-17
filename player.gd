extends Area2D

signal hit


@export var speed = 400
var screen_size 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size


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

		
		
		

func _on_body_entered(_body) -> void:
	# when it dies
	hit.emit()
	
	set_process(false)
	$AnimatedSprite2D.animation = "dead"
	$CollisionShape2D.set_deferred("disabled", true)
	

	
	
func start(pos):
	
	position = pos
	
	# reset ghost
	set_process(true)
	$CollisionShape2D.disabled = false
