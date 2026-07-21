class_name ResourceManager
extends Node2D

signal mana_changed(current_mana: int, max_mana: int)
signal tension_changed(current_tension: float, is_overwhelm: bool)
signal health_changed(current_hp: int, max_hp: int, block: int)
signal overwhelm_entered()
signal overwhelm_exited()

@export var max_mana: int = 3
var current_mana: int = 3

@export var max_tension: float = 100.0
var tension: float = 50.0 # Starts at 50 each combat
var is_overwhelm: bool = false

@export var max_health: int = 50
var current_health: int = 50
var block: int = 0

func _ready() -> void:
	# Full HP at game start
	current_health = max_health
	reset_combat()

## Resets encounter state for a new combat (HP persists across combats!)
func reset_combat() -> void:
	current_mana = max_mana
	tension = 50.0
	is_overwhelm = false
	block = 0
	
	# Note: current_health is NOT reset here so HP carries over between encounters
	emit_signal("mana_changed", current_mana, max_mana)
	emit_signal("tension_changed", tension, is_overwhelm)
	emit_signal("health_changed", current_health, max_health, block)

## Refreshes mana and clears block at the start of player turn (Slay the Spire style)
func start_turn() -> void:
	current_mana = max_mana
	block = 0 # Block expires at start of turn
	emit_signal("mana_changed", current_mana, max_mana)
	emit_signal("health_changed", current_health, max_health, block)

## Processes end-of-turn tension changes
func end_turn() -> void:
	if is_overwhelm:
		# At the end of turn in Overwhelm state, tension is reduced to 0
		is_overwhelm = false
		tension = 0.0
		emit_signal("overwhelm_exited")
		emit_signal("tension_changed", tension, is_overwhelm)
	else:
		# At end of normal turn, tension decreases by 15
		modify_tension(-15.0)

## Adds block/shield to player
func add_block(amount: int) -> void:
	if amount <= 0:
		return
	block += amount
	print("Player gained %d Block! Total Block: %d" % [amount, block])
	emit_signal("health_changed", current_health, max_health, block)

## Deals damage to player, absorbing with Block first and adding Tension for unblocked HP damage
func take_player_damage(damage: int) -> void:
	if damage <= 0:
		return
		
	var unblocked_damage = damage
	if block > 0:
		if block >= unblocked_damage:
			block -= unblocked_damage
			unblocked_damage = 0
		else:
			unblocked_damage -= block
			block = 0
			
	if unblocked_damage > 0:
		current_health = max(0, current_health - unblocked_damage)
		on_player_take_damage(unblocked_damage)
		
	emit_signal("health_changed", current_health, max_health, block)

## Checks if a card can be played based on Mana cost and Overwhelm state
func can_play_card(card_data: Dictionary) -> bool:
	var cost = card_data.get("cost", 0)
	if current_mana < cost:
		print("Cannot play card: Insufficient Mana (%d/%d required)" % [current_mana, cost])
		return false
		
	if is_overwhelm:
		var effects = card_data.get("effects", {})
		var is_overwhelm_card = card_data.get("overwhelm", false) or effects.get("overwhelm", false) or ("overwhelm" in card_data.get("tags", []))
		if not is_overwhelm_card:
			print("Cannot play card: In Overwhelm state! Only Overwhelm-tagged cards can be played.")
			return false
			
	return true

## Deducts mana cost when playing a card
func spend_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		emit_signal("mana_changed", current_mana, max_mana)
		return true
	return false

## Modifies tension. Prevents reduction during Overwhelm turn until turn end.
func modify_tension(amount: float) -> void:
	if is_overwhelm and amount < 0:
		print("Tension reduction ignored: Locked during Overwhelm turn!")
		return
		
	tension = clamp(tension + amount, 0.0, max_tension)
	
	if tension >= max_tension and not is_overwhelm:
		is_overwhelm = true
		tension = max_tension
		emit_signal("overwhelm_entered")
		print("!!! ENTERED OVERWHELM STATE !!! Outgoing attack damage doubled!")
		
	emit_signal("tension_changed", tension, is_overwhelm)

## Called when player takes unblocked damage (Tension +50% of damage rounded up)
func on_player_take_damage(unblocked_damage: int) -> void:
	if unblocked_damage <= 0:
		return
	var tension_gain = ceil(float(unblocked_damage) * 0.5)
	print("Player took %d unblocked HP damage -> Tension increased by %d" % [unblocked_damage, int(tension_gain)])
	modify_tension(tension_gain)

## Returns damage multiplier for outgoing attacks (x2 in Overwhelm)
func get_outgoing_damage_multiplier() -> float:
	return 2.0 if is_overwhelm else 1.0
