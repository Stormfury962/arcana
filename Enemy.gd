extends Area2D

@export var enemy_name: String = "Training Dummy"
@export var max_hp: int = 50
@export var default_attack_damage: int = 5
@export var top_margin_y: float = 170.0 # Distance from top of viewport

var current_hp: int = 50
var current_intent: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var label: Label = $Label if has_node("Label") else null
@onready var intent_label: Label = $IntentLabel if has_node("IntentLabel") else null

var is_highlighted: bool = false
var original_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp
	original_scale = scale
	
	ensure_intent_label_exists()
	update_ui()
	
	# Decides initial intent for turn 1
	decide_next_intent()
	
	# Automatically align enemy to top-middle of viewport
	center_in_top_viewport()
	get_viewport().size_changed.connect(center_in_top_viewport)

func ensure_intent_label_exists() -> void:
	if not intent_label:
		intent_label = Label.new()
		intent_label.name = "IntentLabel"
		intent_label.position = Vector2(-100, -130) # Above enemy's head
		intent_label.size = Vector2(200, 40)
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Styling: Bold warning yellow/red text with dark outline
		intent_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25, 1.0))
		intent_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
		intent_label.add_theme_constant_override("outline_size", 6)
		intent_label.add_theme_font_size_override("font_size", 18)
		add_child(intent_label)

func center_in_top_viewport() -> void:
	var viewport_size = get_viewport_rect().size
	global_position = Vector2(viewport_size.x / 2.0, top_margin_y)

func update_ui() -> void:
	if label:
		label.text = "%s\nHP: %d/%d" % [enemy_name, current_hp, max_hp]
		
	if intent_label and current_intent.has("text"):
		intent_label.text = current_intent["text"]

## Decides what action the enemy will take on their upcoming turn
func decide_next_intent() -> void:
	current_intent = {
		"type": "attack",
		"value": default_attack_damage,
		"text": "⚔️ Attack %d" % default_attack_damage
	}
	update_ui()

## Executes the current turn intent (called when player ends turn)
func execute_intent() -> void:
	if current_hp <= 0:
		return
		
	var intent_type = current_intent.get("type", "none")
	print("Enemy %s executing intent: %s" % [enemy_name, current_intent.get("text", "")])
	
	match intent_type:
		"attack":
			var dmg = current_intent.get("value", default_attack_damage)
			var res_mgr = get_node_or_null("../Resource Manager")
			if res_mgr and res_mgr.has_method("take_player_damage"):
				res_mgr.take_player_damage(dmg)
				
	# After executing action, decide next turn intent
	decide_next_intent()

func set_highlight(active: bool) -> void:
	if is_highlighted == active:
		return
	is_highlighted = active
	
	var tween = create_tween().set_parallel(true)
	if active:
		tween.tween_property(self, "scale", original_scale * 1.15, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		modulate = Color(1.3, 0.8, 0.8) # Flash reddish highlight
	else:
		tween.tween_property(self, "scale", original_scale, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		modulate = Color.WHITE

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	update_ui()
	
	# Play hit animation pulse
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.08)
	tween.tween_property(self, "modulate", Color.WHITE if not is_highlighted else Color(1.3, 0.8, 0.8), 0.15)
	print("Enemy %s took %d damage! HP remaining: %d" % [enemy_name, amount, current_hp])
	
	if current_hp <= 0:
		on_enemy_defeated()

func on_enemy_defeated() -> void:
	print("Enemy %s DEFEATED!" % enemy_name)
	visible = false
	
	# Open Victory Reward Screen
	var reward_ui = get_node_or_null("../UI/RewardUI")
	if reward_ui and reward_ui.has_method("show_victory_rewards"):
		reward_ui.show_victory_rewards(25)
