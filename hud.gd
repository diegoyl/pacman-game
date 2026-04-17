extends CanvasLayer

signal start_game
var hi_score = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
	
func show_game_over(new_score):
	show_message("Game Over")
	$Message.add_theme_color_override("font_color", "#f00")
	$MessageBlinkTimer.start()
	
	await $MessageTimer.timeout
	$MessageBlinkTimer.stop()
	
	$Message.add_theme_color_override("font_color", "#ff0")
	
	$Message.text = ""
	$Message.show()
	
	$StartButton.show()
	update_hi_score(new_score)
	
	
func update_score(score):
	$ScoreLabel.text = str(score)

func update_hi_score(new_score):
	$HiScoreLabel.show()
	
	if new_score > hi_score:
		$HiScoreLabel.add_theme_color_override("font_color", "ff0")
		$HiScoreLabel.text = "NEW HI-SCORE  " + str(new_score)
		hi_score = new_score
		$HiScoreBlinkTimer.start()
	else:
		$HiScoreLabel.add_theme_color_override("font_color", "fff")
		$HiScoreLabel.text = "HI-SCORE   " + str(hi_score)
		


func _on_start_button_pressed() -> void:
	$ButtonClick.play()
	$StartButton.hide()
	$HiScoreLabel.hide()
	start_game.emit()


func _on_message_timer_timeout() -> void:
	$Message.hide()


func _on_message_blink_timer_timeout() -> void:
	if $Message.visible:
		$Message.hide() 
	else:
		$Message.show()


func _on_hi_score_blink_timer_timeout() -> void:
	if $HiScoreLabel.visible:
		$HiScoreLabel.hide() 
	else:
		$HiScoreLabel.show()
