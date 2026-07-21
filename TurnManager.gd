class_name TurnManager
extends Node2D

signal turn_ended()
signal turn_started(turn_number: int)

@export var deck_manager: Node2D
@export var hand_manager: Node2D
@export var resource_manager: Node2D
@export var hand_size_per_turn: int = 5

var turn_number: int = 1

func _ready() -> void:
	if not deck_manager:
		deck_manager = get_node_or_null("../Deck Manager")
	if not hand_manager:
		hand_manager = get_node_or_null("../Player Hand")
	if not resource_manager:
		resource_manager = get_node_or_null("../Resource Manager")

func _on_end_turn_button_pressed() -> void:
	end_turn()

func end_turn() -> void:
	print("--- Ending Turn %d ---" % turn_number)
	emit_signal("turn_ended")
	
	# 1. Process end-of-turn tension reductions & Overwhelm state resets FIRST
	if resource_manager and resource_manager.has_method("end_turn"):
		resource_manager.end_turn()
		
	# 2. Execute Enemy Intents SECOND (Enemy attacks after Tension reduction)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("execute_intent"):
			enemy.execute_intent()
		
	# 3. Discard all remaining cards in hand
	if deck_manager and deck_manager.has_method("discard_hand"):
		deck_manager.discard_hand()
		
	turn_number += 1
	
	# 4. Start next turn (refreshes mana to 3, resets block to 0, draws 5 new cards)
	start_new_turn()

func start_new_turn() -> void:
	print("--- Starting Turn %d ---" % turn_number)
	emit_signal("turn_started", turn_number)
	
	# Refresh Mana to 3 & clear block
	if resource_manager and resource_manager.has_method("start_turn"):
		resource_manager.start_turn()
		
	# Draw fresh hand for the new turn
	if deck_manager and deck_manager.has_method("draw_cards"):
		deck_manager.draw_cards(hand_size_per_turn)
