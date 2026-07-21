extends Control

signal reward_claimed()

var player_gold: int = 0
var available_card_rewards: Array[Dictionary] = []

@onready var panel: Panel = $Panel if has_node("Panel") else null
@onready var title_label: Label = $Panel/TitleLabel if has_node("Panel/TitleLabel") else null
@onready var gold_button: Button = $Panel/GoldButton if has_node("Panel/GoldButton") else null
@onready var card_button: Button = $Panel/CardButton if has_node("Panel/CardButton") else null
@onready var continue_button: Button = $Panel/ContinueButton if has_node("Panel/ContinueButton") else null
@onready var gold_label: Label = $Panel/GoldLabel if has_node("Panel/GoldLabel") else null

# Card Selection Sub-Panel
@onready var card_picker_panel: Panel = $CardPickerPanel if has_node("CardPickerPanel") else null
@onready var card_container: HBoxContainer = $CardPickerPanel/HBoxContainer if has_node("CardPickerPanel/HBoxContainer") else null

func _ready() -> void:
	visible = false
	if card_picker_panel:
		card_picker_panel.visible = false
		
	apply_opaque_styling()

## Applies a solid dark background overlay and opaque panel styling
func apply_opaque_styling() -> void:
	# Fullscreen dark semi-opaque backdrop (92% opacity)
	var backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.04, 0.05, 0.08, 0.92)
	add_child(backdrop)
	move_child(backdrop, 0)
	
	# Solid dark panel stylebox
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.13, 0.17, 0.98) # Solid dark slate
	panel_style.border_color = Color(0.35, 0.45, 0.6, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	
	if panel:
		panel.add_theme_stylebox_override("panel", panel_style)
	if card_picker_panel:
		card_picker_panel.add_theme_stylebox_override("panel", panel_style)

## Triggers and opens the combat Victory Rewards screen
func show_victory_rewards(gold_amount: int = 25) -> void:
	visible = true
	if card_picker_panel:
		card_picker_panel.visible = false
		
	# Setup Gold Reward
	if gold_button:
		gold_button.text = "💰 Claim %d Gold" % gold_amount
		gold_button.disabled = false
		gold_button.set_meta("gold_amount", gold_amount)
		
	# Setup Card Reward
	if card_button:
		card_button.text = "🃏 Choose a Card Reward"
		card_button.disabled = false
		
	# Fetch 3 random non-Basic cards for Warrior
	available_card_rewards = CardDatabase.get_random_card_rewards("Warrior", 3)

func _on_gold_button_pressed() -> void:
	var amount = gold_button.get_meta("gold_amount") if gold_button.has_meta("gold_amount") else 25
	player_gold += amount
	print("Claimed %d Gold! Total Gold: %d" % [amount, player_gold])
	
	if gold_label:
		gold_label.text = "Gold: %d" % player_gold
		
	gold_button.disabled = true
	gold_button.text = "✔️ %d Gold Claimed" % amount

func _on_card_button_pressed() -> void:
	open_card_picker()

func open_card_picker() -> void:
	if not card_picker_panel or not card_container:
		return
		
	card_picker_panel.visible = true
	
	# Clear previous card buttons
	for child in card_container.get_children():
		child.queue_free()
		
	# Create a button for each of the 3 random card choices
	for card_data in available_card_rewards:
		var c_btn = Button.new()
		c_btn.custom_minimum_size = Vector2(180, 240)
		
		# Solid dark card button stylebox
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.18, 0.20, 0.26, 1.0) # Solid card background
		btn_style.border_color = Color(0.4, 0.5, 0.65, 1.0)
		btn_style.set_border_width_all(2)
		btn_style.set_corner_radius_all(8)
		c_btn.add_theme_stylebox_override("normal", btn_style)
		
		var rarity_color = get_rarity_color(card_data.get("rarity", "Common"))
		var c_name = card_data.get("name", "Card")
		var c_cost = card_data.get("cost", 1)
		var c_rarity = card_data.get("rarity", "Common")
		var c_desc = card_data.get("description", "")
		
		# Child Label for clean multiline text wrapping
		var c_label = Label.new()
		c_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		c_label.offset_left = 8
		c_label.offset_top = 8
		c_label.offset_right = -8
		c_label.offset_bottom = -8
		c_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		c_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c_label.mouse_filter = Control.MOUSE_FILTER_IGNORE # Clicks pass through to button
		c_label.text = "(%d) %s\n[%s]\n\n%s" % [c_cost, c_name, c_rarity, c_desc]
		c_label.add_theme_color_override("font_color", rarity_color)
		c_label.add_theme_font_size_override("font_size", 14)
		
		c_btn.add_child(c_label)
		
		# Connect button click using explicit Callable binding
		c_btn.pressed.connect(_on_card_selected.bind(card_data))
		card_container.add_child(c_btn)

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Common":
			return Color(0.9, 0.9, 0.9)
		"Uncommon":
			return Color(0.3, 0.75, 1.0)
		"Rare":
			return Color(1.0, 0.8, 0.2)
		_:
			return Color.WHITE

func _on_card_selected(card_data: Dictionary) -> void:
	if card_data.is_empty():
		return
		
	print("Player selected card reward: ", card_data.get("name", "Card"))
	
	# Locate DeckManager reliably
	var deck_mgr = get_node_or_null("../../Deck Manager")
	if not deck_mgr:
		deck_mgr = get_tree().root.find_child("Deck Manager", true, false)
		
	if deck_mgr and deck_mgr.get("discard_pile") != null:
		var new_card: Dictionary = card_data.duplicate(true)
		new_card["unique_id"] = randi()
		deck_mgr.discard_pile.append(new_card)
		print("Added %s to player discard pile!" % card_data.get("name"))
		
	if card_picker_panel:
		card_picker_panel.visible = false
		
	if card_button:
		card_button.disabled = true
		card_button.text = "✔️ Card Claimed: %s" % card_data.get("name", "Card")

func _on_skip_card_pressed() -> void:
	if card_picker_panel:
		card_picker_panel.visible = false
	if card_button:
		card_button.disabled = true
		card_button.text = "❌ Card Reward Skipped"

func _on_continue_button_pressed() -> void:
	visible = false
	print("Resetting combat and deck for next encounter...")
	
	# 1. Reset player deck (reshuffle hand & discard pile back into main deck)
	var deck_mgr = get_node_or_null("../../Deck Manager")
	if not deck_mgr:
		deck_mgr = get_tree().root.find_child("Deck Manager", true, false)
	if deck_mgr and deck_mgr.has_method("reset_deck_for_new_combat"):
		deck_mgr.reset_deck_for_new_combat()
		
	# 2. Reset player resources & combat
	var res_mgr = get_node_or_null("../../Resource Manager")
	if not res_mgr:
		res_mgr = get_tree().root.find_child("Resource Manager", true, false)
	if res_mgr and res_mgr.has_method("reset_combat"):
		res_mgr.reset_combat()
		
	# 3. Respawn / Reset enemy
	var enemy = get_node_or_null("../../Training Dummy")
	if not enemy:
		enemy = get_tree().root.find_child("Training Dummy", true, false)
	if enemy:
		enemy.current_hp = enemy.max_hp
		enemy.update_ui()
		enemy.visible = true
		if enemy.has_method("decide_next_intent"):
			enemy.decide_next_intent()
			
	# 4. Reset turn manager & start turn 1
	var turn_mgr = get_node_or_null("../../Turn Manager")
	if not turn_mgr:
		turn_mgr = get_tree().root.find_child("Turn Manager", true, false)
	if turn_mgr:
		turn_mgr.turn_number = 1
		if turn_mgr.has_method("start_new_turn"):
			turn_mgr.start_new_turn()
