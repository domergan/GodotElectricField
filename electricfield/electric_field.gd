extends Node2D

@onready var charge1 = $"../PositiveCharge1"
@onready var charge2 = $"../PositiveCharge2"

@export var line_color = Color(1, 1, 0) 
@export var line_width = 2.0
@export var num_lines_per_charge = 16
@export var max_line_length = 500
@export var step_size = 5.0
	
func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_field_lines_for_charge(charge1.position, num_lines_per_charge, max_line_length, step_size, line_color, line_width)
	draw_field_lines_for_charge(charge2.position, num_lines_per_charge, max_line_length, step_size, line_color, line_width)

func draw_field_lines_for_charge(charge_pos, num_lines, max_length, step, color, width):
	for i in range(num_lines):
		var angle = 2 * PI * i / num_lines
		var current_pos = charge_pos + Vector2(cos(angle), sin(angle)) * 20

		for _j in range(int(max_length / step)):
			var electric_field = calculate_electric_field(current_pos)
			var direction = electric_field.normalized()
			var next_pos = current_pos + direction * step

			# Draw a small segment of the line
			draw_line(current_pos, next_pos, color, width)

			current_pos = next_pos

func calculate_electric_field(point):
	var k = 1.0

	# Positions of the charges
	var pos1 = charge1.position
	var pos2 = charge2.position

	var q1 = 5.0
	var q2 = 1.0

	var r1 = point - pos1
	var r2 = point - pos2

	var dist_sq1 = r1.length_squared()
	var dist_sq2 = r2.length_squared()

	# Avoid dividing by zero
	if dist_sq1 == 0 or dist_sq2 == 0:
		return Vector2.ZERO

	var e1 = (k * q1 / dist_sq1) * r1.normalized()
	var e2 = (k * q2 / dist_sq2) * r2.normalized()

	return e1 + e2
	
