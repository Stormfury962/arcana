extends Node2D

@export var line_color: Color = Color(0.95, 0.3, 0.3, 0.9) # Vibrant red targeting line
@export var line_width: float = 6.0
@export var curve_samples: int = 24

var line: Line2D = null
var reticle_sprite: Sprite2D = null
var is_active: bool = false
var start_pos: Vector2 = Vector2.ZERO
var hovered_enemy: Node2D = null

func _ready() -> void:
	visible = false
	setup_line()

func setup_line() -> void:
	if not line:
		line = Line2D.new()
		line.width = line_width
		line.default_color = line_color
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(line)

func start_targeting(origin_pos: Vector2) -> void:
	start_pos = origin_pos
	is_active = true
	visible = true

func stop_targeting() -> void:
	is_active = false
	visible = false
	hovered_enemy = null
	if line:
		line.clear_points()

func _process(_delta: float) -> void:
	if not is_active:
		return
		
	var mouse_pos = get_global_mouse_position()
	var target_pos = mouse_pos
	
	if is_instance_valid(hovered_enemy):
		target_pos = hovered_enemy.global_position
		
	update_curve(start_pos, target_pos)
	queue_redraw()

## Generates a smooth quadratic Bezier curve from origin to target
func update_curve(p0: Vector2, p2: Vector2) -> void:
	if not line:
		return
		
	line.clear_points()
	
	# Control point for Slay the Spire style arc (pull midpoint upward)
	var mid = (p0 + p2) / 2.0
	var control_y = min(p0.y, p2.y) - max(120.0, abs(p0.x - p2.x) * 0.3)
	var control_point = Vector2(mid.x, control_y)
	
	for i in range(curve_samples + 1):
		var t = float(i) / float(curve_samples)
		# Quadratic Bezier formula
		var point = (1.0 - t) * (1.0 - t) * p0 + 2.0 * (1.0 - t) * t * control_point + t * t * p2
		line.add_point(point)

func _draw() -> void:
	if not is_active:
		return
		
	# Draw crosshair reticle at target tip
	var target_pos = get_global_mouse_position()
	if is_instance_valid(hovered_enemy):
		target_pos = hovered_enemy.global_position
		
	var target_local = to_local(target_pos)
	var radius = 18.0 if is_instance_valid(hovered_enemy) else 12.0
	var color = Color(1.0, 0.2, 0.2, 0.95) if is_instance_valid(hovered_enemy) else line_color
	
	# Circle outer ring
	draw_arc(target_local, radius, 0, TAU, 32, color, 3.0)
	
	# Crosshair lines
	draw_line(target_local + Vector2(-radius - 6, 0), target_local + Vector2(-radius + 4, 0), color, 3.0)
	draw_line(target_local + Vector2(radius - 4, 0), target_local + Vector2(radius + 6, 0), color, 3.0)
	draw_line(target_local + Vector2(0, -radius - 6), target_local + Vector2(0, -radius + 4), color, 3.0)
	draw_line(target_local + Vector2(0, radius - 4), target_local + Vector2(0, radius + 6), color, 3.0)
