extends Node2D

# Reference to the card currently being dragged
var dragged_card: Node2D = null

# Offset from the card's position to the mouse click position
var drag_offset: Vector2 = Vector2.ZERO

# Store original visual properties to restore after dragging
var original_z_index: int = 0
var original_scale: Vector2 = Vector2.ONE

# Constants for drag visual feedback
const DRAG_SCALE_MULTIPLIER = 1.05
const DRAGGED_Z_INDEX = 100

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var clicked_card = raycast_check_card()
				if clicked_card:
					dragged_card = clicked_card
					drag_offset = dragged_card.global_position - get_global_mouse_position()
					original_scale = dragged_card.scale
					
					# Permanently elevate the clicked card's Z-index above all siblings
					var highest_z = get_highest_sibling_z_index(dragged_card)
					original_z_index = highest_z + 1
					
					# Bring dragged card to front visually during the drag action
					dragged_card.z_index = max(DRAGGED_Z_INDEX, original_z_index + 1)
					
					# Premium visual effect: scale card up slightly during drag
					var tween = create_tween()
					tween.tween_property(dragged_card, "scale", original_scale * DRAG_SCALE_MULTIPLIER, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				if dragged_card:
					# Restore card's original z-index
					dragged_card.z_index = original_z_index
					
					# Calculate target clamped position at its original scale (no margin allowed on final placement)
					var target_pos = get_clamped_position(dragged_card, dragged_card.global_position, original_scale, false)
					
					# Premium visual effect: scale card back to normal and snap back to screen bounds if out of bounds
					var tween = create_tween().set_parallel(true)
					tween.tween_property(dragged_card, "scale", original_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					
					if dragged_card.global_position != target_pos:
						# Smooth snap back using TRANS_BACK for a playful bounce effect
						tween.tween_property(dragged_card, "global_position", target_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					
					dragged_card = null

func _process(_delta: float) -> void:
	if dragged_card:
		var target_pos = get_global_mouse_position() + drag_offset
		# Clamp position during dragging to prevent dragging too far off-screen (allowing 50% margin)
		dragged_card.global_position = get_clamped_position(dragged_card, target_pos, original_scale * DRAG_SCALE_MULTIPLIER, true)

## Performs a 2D physics point query (raycast check) at the mouse position.
## Returns the Node2D representing the card if found, or null otherwise.
func raycast_check_card() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = false
	
	var results = space_state.intersect_point(parameters)
	if results.is_empty():
		return null
		
	var selected_card: Node2D = null
	for result in results:
		var collider = result.collider
		if collider is Area2D:
			var card = collider.get_parent()
			if card is Node2D:
				# Prioritize the card that is visually on top:
				# 1. Higher Z-index
				# 2. Higher scene tree child index if Z-index is equal
				if selected_card == null:
					selected_card = card
				else:
					if card.z_index > selected_card.z_index:
						selected_card = card
					elif card.z_index == selected_card.z_index:
						if card.get_parent() == selected_card.get_parent():
							if card.get_index() > selected_card.get_index():
								selected_card = card
	return selected_card

## Calculates the card's visual rectangle relative to its parent node using a specific scale.
func get_card_local_rect(card: Node2D, custom_scale: Vector2) -> Rect2:
	var art = card.get_node_or_null("Art")
	if art and art is Sprite2D and art.texture:
		var size = art.texture.get_size() * art.scale * custom_scale
		var offset = art.position * custom_scale
		return Rect2(offset - size / 2.0, size)
	# Fallback bounds if card layout differs
	return Rect2(-Vector2(100, 150) * custom_scale, Vector2(200, 300) * custom_scale)

## Restricts a position to ensure the card stays within viewport boundaries.
## If allow_margin is true, the card is allowed to go up to 50% off-screen.
func get_clamped_position(card: Node2D, pos: Vector2, custom_scale: Vector2, allow_margin: bool) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var local_rect = get_card_local_rect(card, custom_scale)
	
	var margin_x = (local_rect.size.x * 0.5) if allow_margin else 0.0
	var margin_y = (local_rect.size.y * 0.5) if allow_margin else 0.0
	
	var min_x = -local_rect.position.x - margin_x
	var max_x = viewport_size.x - (local_rect.position.x + local_rect.size.x) + margin_x
	var min_y = -local_rect.position.y - margin_y
	var max_y = viewport_size.y - (local_rect.position.y + local_rect.size.y) + margin_y
	
	if min_x > max_x:
		min_x = viewport_size.x / 2.0
		max_x = viewport_size.x / 2.0
	if min_y > max_y:
		min_y = viewport_size.y / 2.0
		max_y = viewport_size.y / 2.0
		
	return Vector2(
		clamp(pos.x, min_x, max_x),
		clamp(pos.y, min_y, max_y)
	)

## Finds the highest Z-index among the siblings of the given node (including itself).
func get_highest_sibling_z_index(node: Node2D) -> int:
	var highest = 0
	var parent = node.get_parent()
	if parent:
		for child in parent.get_children():
			if child is Node2D:
				highest = max(highest, child.z_index)
	return highest
