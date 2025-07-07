extends Sprite2D

@export var click_radius: float = 50.0

var is_dragging = false

func _process(delta: float) -> void:
	if Input.is_action_pressed("click"):
		if get_global_mouse_position().distance_to(self.global_position) < click_radius:
			is_dragging = true
		else:
			is_dragging = false
			
		if is_dragging:
			self.global_position = get_global_mouse_position()
