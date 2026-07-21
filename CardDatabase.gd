class_name CardDatabase
extends Node2D

# Centralized Card Repository
const CARDS: Dictionary = {
	"strike": {
		"id": "strike",
		"name": "Strike",
		"cost": 1,
		"type": "Attack",
		"class": "Warrior",
		"rarity": "Basic",
		"target_type": "enemy",
		"description": "Deal 8 damage.",
		"effects_sequence": [
			{"type": "damage", "value": 8}
		]
	},
	"defend": {
		"id": "defend",
		"name": "Defend",
		"cost": 1,
		"type": "Skill",
		"class": "Warrior",
		"rarity": "Basic",
		"target_type": "none",
		"description": "Gain 5 Block.",
		"effects_sequence": [
			{"type": "block", "value": 5}
		]
	},
	"frenzy_strike": {
		"id": "frenzy_strike",
		"name": "Frenzy Strike",
		"cost": 1,
		"type": "Attack",
		"class": "Warrior",
		"rarity": "Common",
		"target_type": "enemy",
		"description": "Gain +50 Tension. Deal 10 damage.",
		"effects_sequence": [
			{"type": "tension_change", "value": 50.0},
			{"type": "damage", "value": 10}
		]
	},
	"calm_mind": {
		"id": "calm_mind",
		"name": "Calm Mind",
		"cost": 1,
		"type": "Skill",
		"class": "Warrior",
		"rarity": "Common",
		"target_type": "none",
		"description": "Reduce Tension by 20.",
		"effects_sequence": [
			{"type": "tension_change", "value": -20.0}
		]
	},
	"iron_wave": {
		"id": "iron_wave",
		"name": "Iron Wave",
		"cost": 1,
		"type": "Attack",
		"class": "Warrior",
		"rarity": "Common",
		"target_type": "enemy",
		"description": "Deal 6 damage. Gain 5 Block.",
		"effects_sequence": [
			{"type": "damage", "value": 6},
			{"type": "block", "value": 5}
		]
	},
	"overwhelm_slash": {
		"id": "overwhelm_slash",
		"name": "Overwhelm Slash",
		"cost": 2,
		"type": "Attack",
		"class": "Warrior",
		"rarity": "Uncommon",
		"target_type": "enemy",
		"overwhelm": true,
		"description": "Overwhelm. Deal 12 damage. Gain +10 Tension.",
		"effects_sequence": [
			{"type": "damage", "value": 12},
			{"type": "tension_change", "value": 10.0}
		]
	},
	"rage_burst": {
		"id": "rage_burst",
		"name": "Rage Burst",
		"cost": 2,
		"type": "Attack",
		"class": "Warrior",
		"rarity": "Rare",
		"target_type": "enemy",
		"description": "Gain +60 Tension. Deal 18 damage.",
		"effects_sequence": [
			{"type": "tension_change", "value": 60.0},
			{"type": "damage", "value": 18}
		]
	}
}

## Returns a unique copy of a card by its ID
static func get_card(card_id: String) -> Dictionary:
	if CARDS.has(card_id):
		return CARDS[card_id].duplicate(true)
	push_error("Card ID '%s' not found in CardDatabase!" % card_id)
	return {}

## Returns a starter deck list of card dictionaries
static func get_starter_deck(deck_size: int = 12) -> Array[Dictionary]:
	var starter_ids = ["strike", "defend", "frenzy_strike", "calm_mind", "overwhelm_slash"]
	var result: Array[Dictionary] = []
	
	for i in range(deck_size):
		var card_id = starter_ids[i % starter_ids.size()]
		var card_data = get_card(card_id)
		card_data["unique_id"] = i + 1
		result.append(card_data)
		
	return result

## Returns X random card choices matching player_class, excluding "Basic" rarity cards
static func get_random_card_rewards(player_class: String = "Warrior", count: int = 3) -> Array[Dictionary]:
	var eligible_cards: Array[Dictionary] = []
	
	for key in CARDS:
		var card_data = CARDS[key]
		var c_class = card_data.get("class", "")
		var c_rarity = card_data.get("rarity", "")
		
		# Filter: Must match player class AND must NOT be Basic rarity
		if c_class == player_class and c_rarity != "Basic":
			eligible_cards.append(card_data.duplicate(true))
			
	eligible_cards.shuffle()
	
	var rewards: Array[Dictionary] = []
	for i in range(min(count, eligible_cards.size())):
		rewards.append(eligible_cards[i])
		
	return rewards
