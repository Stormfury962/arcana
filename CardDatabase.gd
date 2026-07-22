class_name CardDatabase
extends Node2D

# Centralized Card Repository with Upgrade schemas
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
		],
		"upgrade": {
			"name": "Strike+",
			"description": "Deal 11 damage.",
			"effects_sequence": [
				{"type": "damage", "value": 11}
			]
		}
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
		],
		"upgrade": {
			"name": "Defend+",
			"description": "Gain 8 Block.",
			"effects_sequence": [
				{"type": "block", "value": 8}
			]
		}
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
		],
		"upgrade": {
			"name": "Frenzy Strike+",
			"description": "Gain +50 Tension. Deal 14 damage.",
			"effects_sequence": [
				{"type": "tension_change", "value": 50.0},
				{"type": "damage", "value": 14}
			]
		}
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
		],
		"upgrade": {
			"name": "Calm Mind+",
			"description": "Reduce Tension by 35.",
			"effects_sequence": [
				{"type": "tension_change", "value": -35.0}
			]
		}
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
		],
		"upgrade": {
			"name": "Iron Wave+",
			"description": "Deal 8 damage. Gain 7 Block.",
			"effects_sequence": [
				{"type": "damage", "value": 8},
				{"type": "block", "value": 7}
			]
		}
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
		],
		"upgrade": {
			"name": "Overwhelm Slash+",
			"cost": 1,
			"description": "Overwhelm. Deal 14 damage. Gain +10 Tension.",
			"effects_sequence": [
				{"type": "damage", "value": 14},
				{"type": "tension_change", "value": 10.0}
			]
		}
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
		],
		"upgrade": {
			"name": "Rage Burst+",
			"description": "Gain +60 Tension. Deal 24 damage.",
			"effects_sequence": [
				{"type": "tension_change", "value": 60.0},
				{"type": "damage", "value": 24}
			]
		}
	}
}

# Centralized Charms / Enchantments Repository
const CHARMS: Dictionary = {
	"charm_heavy": {
		"id": "charm_heavy",
		"name": "Heavy",
		"description": "+4 Damage",
		"type": "prefix",
		"modify_damage": 4
	},
	"charm_sturdy": {
		"id": "charm_sturdy",
		"name": "Sturdy",
		"description": "+3 Block",
		"type": "prefix",
		"modify_block": 3
	},
	"charm_siphon": {
		"id": "charm_siphon",
		"name": "Siphoning",
		"description": "Gain 4 Block",
		"type": "suffix",
		"add_effect": {"type": "block", "value": 4}
	},
	"charm_light": {
		"id": "charm_light",
		"name": "Lightweight",
		"description": "-1 Cost",
		"type": "prefix",
		"modify_cost": -1
	},
	"charm_focused": {
		"id": "charm_focused",
		"name": "Focusing",
		"description": "Reduce Tension by 15",
		"type": "suffix",
		"add_effect": {"type": "tension_change", "value": -15.0}
	},
	"charm_furious": {
		"id": "charm_furious",
		"name": "Furious",
		"description": "Gain +20 Tension",
		"type": "suffix",
		"add_effect": {"type": "tension_change", "value": 20.0}
	}
}

## Instantiates a fresh card instance with upgrade & charm state metadata
static func create_card_instance(card_id: String, is_upgraded: bool = false, charms: Array[String] = []) -> Dictionary:
	if not CARDS.has(card_id):
		push_error("Card ID '%s' not found in CardDatabase!" % card_id)
		return {}
		
	var instance: Dictionary = CARDS[card_id].duplicate(true)
	instance["is_upgraded"] = false
	instance["charms"] = []
	
	if is_upgraded:
		apply_upgrade(instance)
		
	for charm_id in charms:
		apply_charm(instance, charm_id)
		
	return instance

## Returns a unique copy of a card by its ID (backward compatible)
static func get_card(card_id: String) -> Dictionary:
	return create_card_instance(card_id)

## Returns true if the card can be upgraded
static func can_upgrade(card_instance: Dictionary) -> bool:
	if card_instance.is_empty():
		return false
	if card_instance.get("is_upgraded", false):
		return false
	var card_id = card_instance.get("id", "")
	if CARDS.has(card_id) and CARDS[card_id].has("upgrade"):
		return true
	return card_instance.has("upgrade")

## Applies card upgrade transformations in-place to a card instance
static func apply_upgrade(card_instance: Dictionary) -> bool:
	if not can_upgrade(card_instance):
		return false
		
	card_instance["is_upgraded"] = true
	var card_id = card_instance.get("id", "")
	var upgrade_data: Dictionary = {}
	
	if CARDS.has(card_id) and CARDS[card_id].has("upgrade"):
		upgrade_data = CARDS[card_id]["upgrade"]
	elif card_instance.has("upgrade"):
		upgrade_data = card_instance["upgrade"]
		
	if upgrade_data.has("name"):
		card_instance["name"] = upgrade_data["name"]
	else:
		card_instance["name"] = card_instance.get("name", "Card") + "+"
		
	if upgrade_data.has("cost"):
		card_instance["cost"] = upgrade_data["cost"]
		
	if upgrade_data.has("description"):
		card_instance["description"] = upgrade_data["description"]
		
	if upgrade_data.has("effects_sequence"):
		card_instance["effects_sequence"] = upgrade_data["effects_sequence"].duplicate(true)
		
	# Re-apply any existing charms on top of the upgraded base
	var existing_charms = card_instance.get("charms", []).duplicate()
	card_instance["charms"] = []
	for charm_id in existing_charms:
		apply_charm(card_instance, charm_id)
		
	return true

## Applies a Charm / Enchantment to a card instance in-place
static func apply_charm(card_instance: Dictionary, charm_id: String) -> bool:
	if not CHARMS.has(charm_id):
		push_error("Charm ID '%s' not found in CardDatabase!" % charm_id)
		return false
		
	var charm_def = CHARMS[charm_id]
	var charms_list: Array = card_instance.get("charms", [])
	
	# Prevent duplicate charm of same ID on a single card
	if charm_id in charms_list:
		return false
		
	charms_list.append(charm_id)
	card_instance["charms"] = charms_list
	
	# 1. Modify Cost
	if charm_def.has("modify_cost"):
		var new_cost = max(0, card_instance.get("cost", 0) + charm_def["modify_cost"])
		card_instance["cost"] = new_cost
		
	# 2. Modify Damage / Block values in effects_sequence
	var effects: Array = card_instance.get("effects_sequence", [])
	if charm_def.has("modify_damage"):
		for step in effects:
			if step.get("type") == "damage":
				step["value"] = step.get("value", 0) + charm_def["modify_damage"]
				
	if charm_def.has("modify_block"):
		for step in effects:
			if step.get("type") == "block":
				step["value"] = step.get("value", 0) + charm_def["modify_block"]
				
	# 3. Append additional effect steps
	if charm_def.has("add_effect"):
		effects.append(charm_def["add_effect"].duplicate(true))
		
	card_instance["effects_sequence"] = effects
	
	# 4. Update Name & Description with Charm text
	var charm_name = charm_def.get("name", "")
	var card_name = card_instance.get("name", "Card")
	if not ("[" + charm_name + "]") in card_name:
		card_instance["name"] = "[%s] %s" % [charm_name, card_name]
		
	var charm_desc = charm_def.get("description", "")
	var current_desc = card_instance.get("description", "")
	if not charm_desc in current_desc:
		card_instance["description"] = "%s %s." % [current_desc.trim_suffix("."), charm_desc]
		
	return true

## Returns all charms available in the database
static func get_all_charms() -> Dictionary:
	return CHARMS.duplicate(true)

## Returns a specific charm definition dictionary
static func get_charm(charm_id: String) -> Dictionary:
	if CHARMS.has(charm_id):
		return CHARMS[charm_id].duplicate(true)
	return {}

## Returns a random charm definition
static func get_random_charm() -> Dictionary:
	var keys = CHARMS.keys()
	if keys.is_empty():
		return {}
	keys.shuffle()
	return CHARMS[keys[0]].duplicate(true)

## Returns a starter deck list of card dictionaries
static func get_starter_deck(deck_size: int = 12) -> Array[Dictionary]:
	var starter_ids = ["strike", "defend", "frenzy_strike", "calm_mind", "overwhelm_slash"]
	var result: Array[Dictionary] = []
	
	for i in range(deck_size):
		var card_id = starter_ids[i % starter_ids.size()]
		var card_data = create_card_instance(card_id)
		card_data["unique_id"] = i + 1
		result.append(card_data)
		
	return result

## Returns X random card choices matching player_class, excluding "Basic" rarity cards
static func get_random_card_rewards(player_class: String = "Warrior", count: int = 3) -> Array[Dictionary]:
	var eligible_ids: Array[String] = []
	
	for key in CARDS:
		var card_data = CARDS[key]
		var c_class = card_data.get("class", "")
		var c_rarity = card_data.get("rarity", "")
		
		# Filter: Must match player class AND must NOT be Basic rarity
		if c_class == player_class and c_rarity != "Basic":
			eligible_ids.append(key)
			
	eligible_ids.shuffle()
	
	var rewards: Array[Dictionary] = []
	for i in range(min(count, eligible_ids.size())):
		var card_id = eligible_ids[i]
		rewards.append(create_card_instance(card_id))
		
	return rewards
