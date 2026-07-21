extends Control

@export var resource_manager: Node2D

@onready var mana_label: Label = $ManaLabel if has_node("ManaLabel") else null
@onready var health_label: Label = $HealthLabel if has_node("HealthLabel") else null
@onready var block_label: Label = $BlockLabel if has_node("BlockLabel") else null
@onready var tension_bar: ProgressBar = $TensionBar if has_node("TensionBar") else null
@onready var tension_label: Label = $TensionBar/TensionLabel if has_node("TensionBar/TensionLabel") else null

func _ready() -> void:
	if tension_bar:
		tension_bar.show_percentage = false
		
	if not resource_manager:
		resource_manager = get_node_or_null("../../Resource Manager")
		
	if resource_manager:
		if resource_manager.has_signal("mana_changed"):
			resource_manager.mana_changed.connect(_on_mana_changed)
		if resource_manager.has_signal("health_changed"):
			resource_manager.health_changed.connect(_on_health_changed)
		if resource_manager.has_signal("tension_changed"):
			resource_manager.tension_changed.connect(_on_tension_changed)
		if resource_manager.has_signal("overwhelm_entered"):
			resource_manager.overwhelm_entered.connect(_on_overwhelm_entered)
		if resource_manager.has_signal("overwhelm_exited"):
			resource_manager.overwhelm_exited.connect(_on_overwhelm_exited)
			
		# Initialize UI
		_on_mana_changed(resource_manager.get("current_mana"), resource_manager.get("max_mana"))
		_on_health_changed(resource_manager.get("current_health"), resource_manager.get("max_health"), resource_manager.get("block"))
		_on_tension_changed(resource_manager.get("tension"), resource_manager.get("is_overwhelm"))

func _on_mana_changed(current: int, max_val: int) -> void:
	if mana_label:
		mana_label.text = "MANA: %d / %d" % [current, max_val]

func _on_health_changed(current_hp: int, max_hp: int, block_val: int) -> void:
	if health_label:
		health_label.text = "HP: %d / %d" % [current_hp, max_hp]
		
	if block_label:
		if block_val > 0:
			block_label.visible = true
			block_label.text = "[🛡️ %d]" % block_val
		else:
			block_label.visible = false

func _on_tension_changed(value: float, is_overwhelm: bool) -> void:
	if tension_bar:
		tension_bar.value = value
	if tension_label:
		if is_overwhelm:
			tension_label.text = "!!! OVERWHELM !!! (DMG x2)"
			tension_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		else:
			tension_label.text = "TENSION: %d / 100" % int(value)
			tension_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _on_overwhelm_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.4, 0.6, 0.6), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)

func _on_overwhelm_exited() -> void:
	_on_tension_changed(0.0, false)
