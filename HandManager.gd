class_name HandManager
extends Node2D

@export var card_scene: PackedScene = preload("res://Scenes/BaseCard.tscn")
@export var deck_manager: Node2D
@export var card_manager: Node2D

# Fan Layout configuration parameters
@export var hand_center_offset: Vector2 = Vector2(0, 30)
@export var max_fan_angle_deg: float = 24.0 # Maximum total fan spread angle for a full hand (-12 deg to +12 deg)
@export var angle_per_card_deg: float = 5.0 # Angle step per card in hand (scales angle down for smaller hands)
@export var max_card_spacing: float = 120.0
@export var max_hand_width: float = 650.0
@export var curve_height: float = 35.0 # Vertical drop at hand edges for fan arc

# Array of instantiated card Node2D objects currently in hand
var card_nodes: Array[Node2D] = []

func _ready() -> void:
	if not deck_manager:
		deck_manager = get_node_or_null("../Deck Manager")
	if not card_manager:
		card_manager = get_node_or_null("../Card Manager")
		
	if deck_manager:
		if deck_manager.has_signal("card_drawn"):
			deck_manager.card_drawn.connect(_on_card_drawn)
		if deck_manager.has_signal("hand_updated"):
			deck_manager.hand_updated.connect(_on_hand_updated)
	
	# Listen for window/viewport resize events to dynamically realign the hand
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Initial draw of 5 cards when entering the scene
	call_deferred("draw_initial_hand")

func _on_viewport_size_changed() -> void:
	update_hand_positions(false)

func draw_initial_hand() -> void:
	if deck_manager and deck_manager.has_method("draw_cards"):
		deck_manager.draw_cards(5)

func _process(_delta: float) -> void:
	# Check if player is dragging a card in hand to reorder it
	if card_manager and card_manager.get("dragged_card") != null:
		var dragged = card_manager.get("dragged_card")
		if dragged in card_nodes:
			check_card_reorder(dragged)

## Reorders cards in hand dynamically as a card is dragged horizontally
func check_card_reorder(dragged_card: Node2D) -> void:
	var current_idx = card_nodes.find(dragged_card)
	if current_idx == -1:
		return
		
	var card_x = dragged_card.global_position.x
	
	# Check swap with left neighbor card
	if current_idx > 0:
		var left_card = card_nodes[current_idx - 1]
		if is_instance_valid(left_card):
			var left_home_x = left_card.get_meta("home_position").x if left_card.has_meta("home_position") else left_card.global_position.x
			if card_x < left_home_x:
				# Swap positions in node list
				card_nodes[current_idx] = left_card
				card_nodes[current_idx - 1] = dragged_card
				
				# Also sync hand array order in DeckManager
				if deck_manager and deck_manager.has_method("swap_hand_indices"):
					deck_manager.swap_hand_indices(current_idx, current_idx - 1)
					
				update_hand_positions(true)
				return
				
	# Check swap with right neighbor card
	if current_idx < card_nodes.size() - 1:
		var right_card = card_nodes[current_idx + 1]
		if is_instance_valid(right_card):
			var right_home_x = right_card.get_meta("home_position").x if right_card.has_meta("home_position") else right_card.global_position.x
			if card_x > right_home_x:
				# Swap positions in node list
				card_nodes[current_idx] = right_card
				card_nodes[current_idx + 1] = dragged_card
				
				# Also sync hand array order in DeckManager
				if deck_manager and deck_manager.has_method("swap_hand_indices"):
					deck_manager.swap_hand_indices(current_idx, current_idx + 1)
					
				update_hand_positions(true)
				return

func _input(event: InputEvent) -> void:
	# Press 'D' key to draw a card manually for testing
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_D:
			if deck_manager and deck_manager.has_method("draw_card"):
				deck_manager.draw_card()

func _on_card_drawn(card_data: Dictionary) -> void:
	instantiate_card_object(card_data)

func _on_hand_updated(_hand_list: Array) -> void:
	update_hand_positions()

func instantiate_card_object(card_data: Dictionary) -> Node2D:
	if not card_scene:
		push_error("card_scene is not assigned in HandManager!")
		return null
		
	var new_card: Node2D = card_scene.instantiate() as Node2D
	new_card.add_to_group("cards")
	
	# Store card data dictionary on the node metadata
	new_card.set_meta("card_data", card_data)
	new_card.set_meta("is_being_dragged", false)
	
	if new_card.has_method("setup"):
		new_card.setup(card_data)
	
	add_child(new_card)
	
	# Initial spawn position (deck corner animation start)
	var viewport_size = get_viewport_rect().size
	new_card.global_position = Vector2(80, viewport_size.y - 80)
	new_card.scale = Vector2(0.5, 0.5)
	
	card_nodes.append(new_card)
	update_hand_positions()
	return new_card

## Calculates Slay the Spire style fan positioning for cards in hand
func update_hand_positions(animate: bool = true) -> void:
	var count = card_nodes.size()
	if count == 0:
		return
		
	var viewport_size = get_viewport_rect().size
	var hand_center = Vector2(viewport_size.x / 2.0, viewport_size.y - 120.0) + hand_center_offset
	
	# Calculate total width and card spacing
	var total_width = min(count * max_card_spacing, max_hand_width)
	var spacing = total_width / max(1, count - 1) if count > 1 else 0.0
	var start_x = hand_center.x - (total_width / 2.0) if count > 1 else hand_center.x
	
	# Dynamically calculate fan rotation angle based on card count (gentler tilt for smaller hands)
	var current_fan_angle_deg = min(max_fan_angle_deg, (count - 1) * angle_per_card_deg) if count > 1 else 0.0
	var half_angle_rad = deg_to_rad(current_fan_angle_deg / 2.0)
	var angle_step = (half_angle_rad * 2.0) / (count - 1) if count > 1 else 0.0
	var start_angle = -half_angle_rad if count > 1 else 0.0
	
	# Scale vertical arc curve height proportionally with fan angle spread
	var effective_curve_height = curve_height * (current_fan_angle_deg / max_fan_angle_deg) if max_fan_angle_deg > 0 else 0.0
	
	for i in range(count):
		var card = card_nodes[i]
		if not is_instance_valid(card):
			continue
			
		# Normalized offset from center (-1.0 to 1.0)
		var normalized_offset = ((float(i) / (count - 1)) * 2.0 - 1.0) if count > 1 else 0.0
		
		# Position calculation (Horizontal spread + Parabolic Vertical Arc)
		var pos_x = start_x + (i * spacing) if count > 1 else hand_center.x
		var pos_y = hand_center.y + (normalized_offset * normalized_offset * effective_curve_height)
		var target_pos = Vector2(pos_x, pos_y)
		
		# Fan Rotation
		var target_rot = start_angle + (i * angle_step) if count > 1 else 0.0
		
		# Layer Z-Index (Left-to-right stacking)
		var target_z = 10 + i
		
		# Store target home position & rotation on card metadata
		card.set_meta("home_position", target_pos)
		card.set_meta("home_rotation", target_rot)
		card.set_meta("home_z_index", target_z)
		
		# If the card is currently dragged by player, do not override its position during drag
		if card.has_meta("is_being_dragged") and card.get_meta("is_being_dragged"):
			continue
			
		card.z_index = target_z
		
		if animate:
			var tween = create_tween().set_parallel(true)
			tween.tween_property(card, "global_position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "rotation", target_rot, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			card.global_position = target_pos
			card.rotation = target_rot
			card.scale = Vector2.ONE

func clear_hand_nodes() -> void:
	for card in card_nodes:
		if is_instance_valid(card):
			card.queue_free()
	card_nodes.clear()

func remove_card_node(card: Node2D) -> void:
	if card in card_nodes:
		card_nodes.erase(card)
		update_hand_positions()
