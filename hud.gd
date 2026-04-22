extends CanvasLayer

signal start_game
var hi_score = 0
var _joystick_on: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_joystick_on = DisplayServer.is_touchscreen_available()
	_apply_joystick_state()
	_sync_joystick_toggle_visibility()

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
	$JoystickToggle.show()

	update_hi_score(new_score)
	
	
func update_score(score):
	$ScoreLabel.text = str(score)


func set_score_label_clock_fx_active(active: bool) -> void:
	if active:
		$ScoreLabel.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		$ScoreLabel.add_theme_color_override("font_color", Color(0.87058824, 0.87058824, 1))

func update_hi_score(new_score):
	$HiScoreLabel.show()
	
	if new_score > hi_score:
		$HiScoreLabel.add_theme_color_override("font_color", "ff0")
		$HiScoreLabel.text = "NEW HI-SCORE  " + str(new_score)
		hi_score = new_score
		$HiScoreBlinkTimer.start()
	else:
		$HiScoreLabel.add_theme_color_override("font_color", Color(0.87058824, 0.87058824, 1, 1))
		$HiScoreLabel.text = "HI-SCORE   " + str(hi_score)
		


func _on_start_button_pressed() -> void:
	$ButtonClick.play()
	$StartButton.hide()
	$HiScoreLabel.hide()
	$JoystickToggle.hide()
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


func _on_joystick_toggle_pressed() -> void:
	_joystick_on = not _joystick_on
	_apply_joystick_state()


func _apply_joystick_state() -> void:
	$Joystick.visible = _joystick_on
	if not _joystick_on:
		$Joystick._clear_input()  # see note below
	_update_joystick_toggle_text()
	
func _update_joystick_toggle_text() -> void:
	$JoystickToggle.text = "HIDE JOYSTICK" if _joystick_on else "SHOW JOYSTICK"
	
func _sync_joystick_toggle_visibility() -> void:
	# Same moments as Start: visible when Start is visible
	$JoystickToggle.visible = $StartButton.visible
