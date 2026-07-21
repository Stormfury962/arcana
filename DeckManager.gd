class_name DeckManager
extends Node2D

signal card_drawn(card_data: Dictionary)
signal hand_updated(hand_cards: Array)
signal deck_updated(deck_count: int, discard_count: int)
signal card_played_signal(card_data: Dictionary, target: Node2D)

@export var default_deck_size: int = 12
@export var resource_manager: Node2D

var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []

func _ready() -> void:
	if not resource_manager:
		resource_manager = get_node_or_null("../Resource Manager")
	initialize_deck()

func initialize_deck() -> void:
	deck.clear()
	hand.clear()
	discard_pile.clear()
	
	# Fetch starter deck from centralized CardDatabase
	deck = CardDatabase.get_starter_deck(default_deck_size)
	deck.shuffle()
	emit_signal("deck_updated", deck.size(), discard_pile.size())

## Reshuffles hand and discard pile back into main deck for a new combat encounter
func reset_deck_for_new_combat() -> void:
	deck.append_array(hand)
	deck.append_array(discard_pile)
	hand.clear()
	discard_pile.clear()
	
	# Clear all active card nodes in HandManager
	var hand_mgr = get_node_or_null("../Player Hand")
	if hand_mgr and hand_mgr.has_method("clear_hand_nodes"):
		hand_mgr.clear_hand_nodes()
		
	deck.shuffle()
	emit_signal("hand_updated", hand)
	emit_signal("deck_updated", deck.size(), discard_pile.size())
	print("Deck reshuffled for new combat. Total deck count: %d" % deck.size())

func draw_card() -> Dictionary:
	if deck.is_empty():
		if discard_pile.is_empty():
			print("Deck and discard pile are both empty!")
			return {}
		reshuffle_discard_into_deck()
		
	var drawn_card = deck.pop_back()
	hand.append(drawn_card)
	
	emit_signal("card_drawn", drawn_card)
	emit_signal("hand_updated", hand)
	emit_signal("deck_updated", deck.size(), discard_pile.size())
	return drawn_card

func draw_cards(amount: int) -> void:
	for i in range(amount):
		draw_card()

func swap_hand_indices(idx_a: int, idx_b: int) -> void:
	if idx_a >= 0 and idx_a < hand.size() and idx_b >= 0 and idx_b < hand.size():
		var temp = hand[idx_a]
		hand[idx_a] = hand[idx_b]
		hand[idx_b] = temp

func play_card(card_node: Node2D, target_enemy: Node2D = null) -> void:
	if not is_instance_valid(card_node) or not card_node.has_meta("card_data"):
		return
		
	var card_data: Dictionary = card_node.get_meta("card_data")
	
	# Verify Resource Requirements (Mana & Overwhelm state)
	if not resource_manager:
		resource_manager = get_node_or_null("../Resource Manager")
		
	if resource_manager and resource_manager.has_method("can_play_card"):
		if not resource_manager.can_play_card(card_data):
			print("Play rejected by Resource Manager!")
			return
			
	# Spend Mana Cost
	var cost = card_data.get("cost", 0)
	if resource_manager and resource_manager.has_method("spend_mana"):
		resource_manager.spend_mana(cost)
		
	# Execute Card Effects in order
	apply_card_effects(card_data, target_enemy)
		
	# Discard card from hand
	discard_card(card_data)
	emit_signal("card_played_signal", card_data, target_enemy)
	
	# Remove node from hand manager & free scene safely
	var hand_mgr = get_node_or_null("../Player Hand")
	if hand_mgr and hand_mgr.has_method("remove_card_node"):
		hand_mgr.remove_card_node(card_node)
		
	if is_instance_valid(card_node):
		card_node.queue_free()

## Processes card effects in strict sequential order
func apply_card_effects(card_data: Dictionary, target_enemy: Node2D) -> void:
	var card_name = card_data.get("name", "Card")
	print("--- Executing Card: %s ---" % card_name)
	
	# Option A: Sequential Array of Effect Steps (Explicit Execution Order)
	if card_data.has("effects_sequence") and card_data["effects_sequence"] is Array:
		for step in card_data["effects_sequence"]:
			execute_effect_step(card_data, step, target_enemy)
		return
		
	# Option B: Fallback Dictionary (Standard Order: Tension -> Damage -> Block -> Statuses)
	var effects = card_data.get("effects", {})
	if effects.has("tension_change"):
		execute_effect_step(card_data, {"type": "tension_change", "value": effects["tension_change"]}, target_enemy)
	if effects.has("damage"):
		execute_effect_step(card_data, {"type": "damage", "value": effects["damage"]}, target_enemy)
	if effects.has("block"):
		execute_effect_step(card_data, {"type": "block", "value": effects["block"]}, target_enemy)
	if effects.has("statuses"):
		for status in effects["statuses"]:
			execute_effect_step(card_data, {"type": "apply_status", "status": status}, target_enemy)

## Executes an individual effect step
func execute_effect_step(card_data: Dictionary, step: Dictionary, target_enemy: Node2D) -> void:
	var card_name = card_data.get("name", "Card")
	var effect_type = step.get("type", "")
	match effect_type:
		"tension_change":
			var amount = float(step.get("value", 0.0))
			if resource_manager and resource_manager.has_method("modify_tension"):
				resource_manager.modify_tension(amount)
				print(" -> [%s] Tension modified by: %+.1f" % [card_name, amount])
				
		"damage":
			var dmg_mult = 1.0
			if resource_manager and resource_manager.has_method("get_outgoing_damage_multiplier"):
				dmg_mult = resource_manager.get_outgoing_damage_multiplier()
				
			var base_damage = step.get("value", 0)
			var final_damage = int(base_damage * dmg_mult)
			
			if target_enemy and target_enemy.has_method("take_damage") and final_damage > 0:
				target_enemy.take_damage(final_damage)
				print(" -> [%s] Dealt %d damage (Mult: %.1fx) to %s" % [card_name, final_damage, dmg_mult, target_enemy.name])
				
		"block":
			var block_amount = step.get("value", 0)
			if resource_manager and resource_manager.has_method("add_block"):
				resource_manager.add_block(block_amount)
				print(" -> [%s] Player gained %d Block!" % [card_name, block_amount])
			
		"apply_status":
			print(" -> [%s] Applied status effect: %s" % [card_name, step.get("status")])

func discard_hand() -> void:
	var cards_to_discard = hand.duplicate()
	for card_data in cards_to_discard:
		var index = hand.find(card_data)
		if index != -1:
			hand.remove_at(index)
			discard_pile.append(card_data)
			
	emit_signal("hand_updated", hand)
	emit_signal("deck_updated", deck.size(), discard_pile.size())
	
	# Clear all instantiated card nodes in HandManager
	var hand_mgr = get_node_or_null("../Player Hand")
	if hand_mgr and hand_mgr.has_method("clear_hand_nodes"):
		hand_mgr.clear_hand_nodes()

func discard_card(card_data: Dictionary) -> void:
	var index = hand.find(card_data)
	if index != -1:
		hand.remove_at(index)
		discard_pile.append(card_data)
		emit_signal("hand_updated", hand)
		emit_signal("deck_updated", deck.size(), discard_pile.size())

func remove_from_hand(card_data: Dictionary) -> void:
	var index = hand.find(card_data)
	if index != -1:
		hand.remove_at(index)
		emit_signal("hand_updated", hand)
		emit_signal("deck_updated", deck.size(), discard_pile.size())

func reshuffle_discard_into_deck() -> void:
	deck.append_array(discard_pile)
	discard_pile.clear()
	deck.shuffle()
	emit_signal("deck_updated", deck.size(), discard_pile.size())

func get_hand() -> Array[Dictionary]:
	return hand

func get_deck_count() -> int:
	return deck.size()

func get_discard_count() -> int:
	return discard_pile.size()
