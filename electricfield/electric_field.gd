extends Node2D

# --- Node References ---
@onready var charge1_node = $"../PositiveCharge1"
@onready var charge2_node = $"../PositiveCharge2"

# --- Inspector Variables for Customization ---
@export_group("Field Visualization")
@export var grid_spacing: int = 40  # The distance between arrows on the grid
@export var arrow_scale: float = 100 # A multiplier to control the arrow length
@export var max_arrow_length: float = 25.0 # The maximum visual length of an arrow
@export var dim_color : Color = Color(0.4, 0.4, 0.2) # Color for weak fields
@export var bright_color : Color = Color.YELLOW       # Color for strong fields
@export var line_width: float = 2.5

@export_group("Charge Properties")
@export var negative_charge_color : Color = Color.BLUE
@export var positive_charge_color : Color = Color.RED

@export_group("Test Charge Properties")
@export var test_charge_scene : PackedScene = preload("res://test_charge.tscn")
@export var q_test : float = 1.0

# --- Charge Values ---
var q1: float = 1.0
var q2: float = 1.0

var test_charges : Array[RigidBody2D] = []

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			spawn_test_charge(get_global_mouse_position())

func spawn_test_charge(spawn_global_position):
	var instance = test_charge_scene.instantiate()
	instance.global_position = spawn_global_position
	add_child(instance)
		
	test_charges.append(instance)

func _physics_process(delta: float) -> void:
	apply_electric_force()
	
func apply_electric_force():
	for charge in test_charges.duplicate():
		if not is_instance_valid(charge):
			test_charges.erase(charge)
			continue
		if not (charge is RigidBody2D):
			continue
		
		var q_test : float = 1.0
		var e_field := calculate_electric_field(charge.global_position)
		var force := e_field * q_test # F = q * E
		
		charge.apply_central_force(force)
	
# Runs every frame
func _process(delta: float) -> void:
	queue_redraw()
	
# The main drawing function, completely replaced with the new grid logic
func _draw() -> void:
	# Update the colors of the charge sprites themselves
	charge1_node.self_modulate = positive_charge_color if q1 > 0 else negative_charge_color
	charge2_node.self_modulate = positive_charge_color if q2 > 0 else negative_charge_color
	
	# Get the visible area of the screen
	var viewport_rect = get_viewport_rect()

	# Loop through every point on our virtual grid
	for x in range(0, int(viewport_rect.size.x), grid_spacing):
		for y in range(0, int(viewport_rect.size.y), grid_spacing):
			var point = Vector2(x, y)
			
			# Calculate the electric field at this grid point
			var field_vector = calculate_electric_field(point)
			
			# Draw an arrow representing this vector
			draw_field_arrow(point, field_vector)

# Helper function to draw a single arrow representing the field vector
func draw_field_arrow(pos: Vector2, vector: Vector2):
	# If the field is zero (e.g., inside a charge), don't draw anything
	if vector.is_zero_approx():
		return

	var magnitude = vector.length()
	var direction = vector.normalized()

	# Determine color based on field strength (magnitude)
	# We use log to better visualize the 1/r^2 falloff
	var strength_ratio = clamp(log(magnitude) / 8.0, 0.0, 1.0)
	var arrow_color = dim_color.lerp(bright_color, strength_ratio)

	# Determine the arrow's length based on magnitude, but cap it
	var arrow_length = min(magnitude * arrow_scale, max_arrow_length)
	
	# Calculate the start and end points of the arrow's main line
	# We center the arrow on the grid point for a cleaner look
	var start_pos = pos - direction * arrow_length / 2.0
	var end_pos = pos + direction * arrow_length / 2.0
	
	# Draw the arrow's body
	draw_line(start_pos, end_pos, arrow_color, line_width)

	# Draw the arrowhead
	var head_length = 10.0
	var head_angle = PI / 6 # 30 degrees
	var head_p1 = end_pos - direction.rotated(head_angle) * head_length
	var head_p2 = end_pos - direction.rotated(-head_angle) * head_length
	draw_line(end_pos, head_p1, arrow_color, line_width)
	draw_line(end_pos, head_p2, arrow_color, line_width)


# This function remains the same, it's the core of the physics simulation
func calculate_electric_field(point: Vector2) -> Vector2:
	var k = 10000.0 # Constant needs to be larger for this type of visualization

	var r1 = point - charge1_node.position
	var r2 = point - charge2_node.position

	var dist_sq1 = r1.length_squared()
	var dist_sq2 = r2.length_squared()

	# Avoid calculation if we are too close to a charge
	if dist_sq1 < 200 or dist_sq2 < 200:
		return Vector2.ZERO

	var e1 = (k * q1 / dist_sq1) * r1.normalized()
	var e2 = (k * q2 / dist_sq2) * r2.normalized()
	
	return e1 + e2

# --- Signal Handlers ---
func _on_h_slider_charge_1_value_changed(value: float) -> void:
	q1 = value

func _on_h_slider_charge_2_value_changed(value: float) -> void:
	q2 = value
