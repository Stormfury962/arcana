extends Node2D

@export var targeting_reticle: Node2D

# Reference to the card currently being dragged
var dragged_card: Node2D = null

# Offset from the card's position to the mouse click position
var drag_offset: Vector2 = Vector2.ZERO

# Store original visual properties to restore after dragging
var original_z_index: int = 0
var original_scale: Vector2 = Vector2.ONE
var original_rotation: float = 0.0

# Targeting state variables
var is_targeting: bool = false
var card_anchor_pos: Vector2 = Vector2.ZERO
var current_hovered_enemy: Node2D = null

# Threshold Y position (cards dragged above this Y height trigger play/targeting check)
@export var play_y_threshold: float = 480.0

# Constants for drag visual feedback
const DRAG_SCALE_MULTIPLIER = 1.05
const DRAGGED_Z_INDEX = 100

func _ready() -> void:
	if not targeting_reticle:
		targeting_reticle = get_node_or_null("../Targeting Reticle")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Cancel targeting on Right-Click
			if is_targeting:
				cancel_targeting()
				return
				
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var clicked_card = raycast_check_card()
				if clicked_card:
					dragged_card = clicked_card
					dragged_card.set_meta("is_being_dragged", true)
					
					drag_offset = dragged_card.global_position - get_global_mouse_position()
					original_scale = dragged_card.scale
					original_rotation = dragged_card.rotation
					
					var highest_z = get_highest_sibling_z_index(dragged_card)
					original_z_index = card_home_z_index(dragged_card, highest_z + 1)
					
					dragged_card.z_index = max(DRAGGED_Z_INDEX, original_z_index + 1)
					
					var tween = create_tween().set_parallel(true)
					tween.tween_property(dragged_card, "scale", original_scale * DRAG_SCALE_MULTIPLIER, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					tween.tween_property(dragged_card, "rotation", 0.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				if dragged_card:
					if is_targeting:
						finish_targeting()
					else:
						# Check non-targeted card play
						var mouse_pos = get_global_mouse_position()
						if mouse_pos.y < play_y_threshold:
							try_play_non_targeted_card()
						else:
							return_card_to_hand()

func try_play_non_targeted_card() -> void:
	if not dragged_card:
		return
		
	var card_data = dragged_card.get_meta("card_data") if dragged_card.has_meta("card_data") else {}
	var res_mgr = get_node_or_null("../Resource Manager")
	
	if res_mgr and res_mgr.has_method("can_play_card"):
		if not res_mgr.can_play_card(card_data):
			return_card_to_hand()
			return
			
	var card_to_play = dragged_card
	dragged_card = null # Clear reference before playing to prevent tween frame overlap
	
	var deck_mgr = get_node_or_null("../Deck Manager")
	if deck_mgr and deck_mgr.has_method("play_card"):
		deck_mgr.play_card(card_to_play, null)

func _process(_delta: float) -> void:
	if not dragged_card:
		return
		
	var mouse_pos = get_global_mouse_position()
	var card_data = dragged_card.get_meta("card_data") if dragged_card.has_meta("card_data") else {}
	var target_type = card_data.get("target_type", "none")
	
	# Check resource restrictions before allowing targeting
	var res_mgr = get_node_or_null("../Resource Manager")
	var can_afford = true
	if res_mgr and res_mgr.has_method("can_play_card"):
		can_afford = res_mgr.can_play_card(card_data)
	
	var should_target = (target_type == "enemy" and mouse_pos.y < play_y_threshold and can_afford)
	
	if should_target:
		if not is_targeting:
			start_targeting_mode()
		process_targeting(mouse_pos)
	else:
		if is_targeting:
			cancel_targeting()
		else:
			# Normal card dragging
			var target_pos = mouse_pos + drag_offset
			dragged_card.global_position = get_clamped_position(dragged_card, target_pos, original_scale * DRAG_SCALE_MULTIPLIER, true)

func start_targeting_mode() -> void:
	is_targeting = true
	card_anchor_pos = dragged_card.global_position
	
	if targeting_reticle and targeting_reticle.has_method("start_targeting"):
		targeting_reticle.start_targeting(card_anchor_pos)
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dragged_card, "rotation", 0.0, 0.1)
	tween.tween_property(dragged_card, "scale", original_scale * 0.9, 0.1)

func process_targeting(mouse_pos: Vector2) -> void:
	var enemy = raycast_check_enemy(mouse_pos)
	
	if enemy != current_hovered_enemy:
		if is_instance_valid(current_hovered_enemy) and current_hovered_enemy.has_method("set_highlight"):
			current_hovered_enemy.set_highlight(false)
			
		current_hovered_enemy = enemy
		
		if is_instance_valid(current_hovered_enemy) and current_hovered_enemy.has_method("set_highlight"):
			current_hovered_enemy.set_highlight(true)
			
		if targeting_reticle:
			targeting_reticle.hovered_enemy = current_hovered_enemy

func finish_targeting() -> void:
	if is_instance_valid(current_hovered_enemy):
		var target_enemy = current_hovered_enemy
		if current_hovered_enemy.has_method("set_highlight"):
			current_hovered_enemy.set_highlight(false)
			
		current_hovered_enemy = null
		
		if targeting_reticle and targeting_reticle.has_method("stop_targeting"):
			targeting_reticle.stop_targeting()
			
		is_targeting = false
		
		var card_to_play = dragged_card
		dragged_card = null # Clear reference before playing to prevent tween frame overlap
		
		var deck_mgr = get_node_or_null("../Deck Manager")
		if deck_mgr and deck_mgr.has_method("play_card"):
			deck_mgr.play_card(card_to_play, target_enemy)
	else:
		cancel_targeting()
		return_card_to_hand()

func cancel_targeting() -> void:
	is_targeting = false
	if is_instance_valid(current_hovered_enemy) and current_hovered_enemy.has_method("set_highlight"):
		current_hovered_enemy.set_highlight(false)
	current_hovered_enemy = null
	
	if targeting_reticle and targeting_reticle.has_method("stop_targeting"):
		targeting_reticle.stop_targeting()

func return_card_to_hand() -> void:
	if not dragged_card:
		return
		
	dragged_card.set_meta("is_being_dragged", false)
	dragged_card.z_index = original_z_index
	
	var target_pos = card_home_position(dragged_card)
	var target_rot = card_home_rotation(dragged_card)
	
	if target_pos == Vector2.ZERO:
		target_pos = get_clamped_position(dragged_card, dragged_card.global_position, original_scale, false)
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dragged_card, "scale", original_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(dragged_card, "rotation", target_rot, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if dragged_card.global_position != target_pos:
		tween.tween_property(dragged_card, "global_position", target_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	var hand_mgr = get_node_or_null("../Player Hand")
	if hand_mgr and hand_mgr.has_method("update_hand_positions"):
		hand_mgr.update_hand_positions()
		
	dragged_card = null

func card_home_position(card: Node2D) -> Vector2:
	if card.has_meta("home_position"):
		return card.get_meta("home_position")
	return Vector2.ZERO

func card_home_rotation(card: Node2D) -> float:
	if card.has_meta("home_rotation"):
		return card.get_meta("home_rotation")
	return 0.0

func card_home_z_index(card: Node2D, default_z: int) -> int:
	if card.has_meta("home_z_index"):
		return card.get_meta("home_z_index")
	return default_z

func raycast_check_enemy(pos: Vector2) -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = pos
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = true
	
	var results = space_state.intersect_point(parameters)
	for result in results:
		var collider = result.collider
		if collider is Area2D and collider.is_in_group("enemies"):
			return collider
		elif collider.get_parent() and collider.get_parent().is_in_group("enemies"):
			return collider.get_parent()
	return null

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
			if card is Node2D and (card.is_in_group("cards") or card.has_meta("card_data")):
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

func get_card_local_rect(card: Node2D, custom_scale: Vector2) -> Rect2:
	var art = card.get_node_or_null("Art")
	if art and art is Sprite2D and art.texture:
		var size = art.texture.get_size() * art.scale * custom_scale
		var offset = art.position * custom_scale
		return Rect2(offset - size / 2.0, size)
	return Rect2(-Vector2(100, 150) * custom_scale, Vector2(200, 300) * custom_scale)

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

func get_highest_sibling_z_index(node: Node2D) -> int:
	var highest = 0
	var parent = node.get_parent()
	if parent:
		for child in parent.get_children():
			if child is Node2D:
				highest = max(highest, child.z_index)
	return highest
