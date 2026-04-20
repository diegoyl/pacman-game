extends RigidBody2D

const BONUS_TYPES = [
	"mob_slow",
	"mob_fast",
	"clock_fast",
	"player_slow"
]

@export var bonus_type: String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var bonus_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	#bonus_type = BONUS_TYPES.pick_random()
	bonus_type = "mob_slow"

	$AnimatedSprite2D.play(bonus_type) # assuming BonusType names match animation names



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
