extends RigidBody2D

const ANIM_DEFAULT := &"default"
const ANIM_RAINBOW := &"rainbow"
const ANIM_ICE := &"ice"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play()


func set_mob_bonus_visual(fast_active: bool, slow_active: bool) -> void:
	var sprite := $AnimatedSprite2D
	if fast_active:
		sprite.play(ANIM_RAINBOW)
	elif slow_active:
		sprite.play(ANIM_ICE)
	else:
		sprite.play(ANIM_DEFAULT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
