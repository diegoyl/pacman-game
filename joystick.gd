extends Control


## Radius inside which input is ignored (pixels).
@export var deadzone_radius: float = 10.0

## joystick textures
@export var stick_textures: Array[Texture2D] = []
@export var knob: TextureRect
var _last_stick_dir: Vector2i = Vector2i(999, 999)  # impossible sentinel

var _active_touch_index: int = -1
var _using_mouse: bool = false


func _ready() -> void:
	_update_knob_visual(Vector2i.ZERO)
	
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_clear_input()
		
		
func _gui_input(event: InputEvent) -> void:
	var center := size * 0.5
	
	# Touch (mobile / web)
	if event is InputEventScreenTouch:
		if event.pressed and _active_touch_index < 0:
			_active_touch_index = event.index
			_apply_from_vector(event.position - center)
			accept_event()
		elif not event.pressed and event.index == _active_touch_index:
			_active_touch_index = -1
			_clear_input()
			accept_event()
		return
		
	if event is InputEventScreenDrag and event.index == _active_touch_index:
		_apply_from_vector(event.position - center)
		accept_event()
		return
		
	# Mouse (desktop editor testing)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_using_mouse = true
			_apply_from_vector(event.position - center)
		else:
			_using_mouse = false
			_clear_input()
		accept_event()
		return
		
	if event is InputEventMouseMotion and _using_mouse:
		_apply_from_vector(event.position - center)
		accept_event()
		
func _apply_from_vector(offset: Vector2) -> void:
	if offset.length() < deadzone_radius:
		_clear_input()
		return
		
	var snapped: Vector2 = _snap_8way(offset.normalized())
	var ix: int = clampi(roundi(snapped.x), -1, 1)
	var iy: int = clampi(roundi(snapped.y), -1, 1)
	_set_move_actions(Vector2i(ix, iy))
	
	# update knob texture
	var dir := Vector2i(ix, iy)
	_update_knob_visual(dir)
	
	
func _update_knob_visual(dir: Vector2i) -> void:
	if dir == _last_stick_dir:
		return
	_last_stick_dir = dir
	if knob == null or stick_textures.is_empty():
		return
	var idx := _dir_to_stick_index(dir)
	if idx < 0 or idx >= stick_textures.size():
		return
	var tex := stick_textures[idx]
	if tex != null:
		knob.texture = tex
	
func _snap_8way(v: Vector2) -> Vector2:
	var a: float = atan2(v.y, v.x)
	var step: float = PI / 4.0
	var snapped_a: float = roundf(a / step) * step
	return Vector2(cos(snapped_a), sin(snapped_a))
	
func _set_move_actions(dir: Vector2i) -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	
	if dir.x < 0:
		Input.action_press(&"move_left")
	elif dir.x > 0:
		Input.action_press(&"move_right")
	if dir.y < 0:
		Input.action_press(&"move_up")
	elif dir.y > 0:
		Input.action_press(&"move_down")
		
func _clear_input() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	
	_last_stick_dir = Vector2i(999, 999)
	_update_knob_visual(Vector2i.ZERO)

	
	
	
# joystick anim
func _dir_to_stick_index(dir: Vector2i) -> int:
	match dir:
		Vector2i(0, 0):
			return 0
		Vector2i(0, -1):
			return 1
		Vector2i(1, -1):
			return 2
		Vector2i(1, 0):
			return 3
		Vector2i(1, 1):
			return 4
		Vector2i(0, 1):
			return 5
		Vector2i(-1, 1):
			return 6
		Vector2i(-1, 0):
			return 7
		Vector2i(-1, -1):
			return 8
		_:
			return 0
