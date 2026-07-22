class_name Card
extends Node2D

# Data dict containing card info (name, cost, description, etc.)
var card_data: Dictionary = {}

# Target transforms for hand layout positioning
var home_position: Vector2 = Vector2.ZERO
var home_rotation: float = 0.0
var is_being_dragged: bool = false

@onready var name_label: Label = $Label if has_node("Label") else null
@onready var desc_label: Label = $DescriptionLabel if has_node("DescriptionLabel") else null

func _ready() -> void:
	add_to_group("cards")
	ensure_labels_exist()
	if not card_data.is_empty():
		update_card_visuals()

func ensure_labels_exist() -> void:
	# 1. Title / Header Label
	if not name_label:
		name_label = Label.new()
		name_label.name = "Label"
		name_label.position = Vector2(-70, -110)
		name_label.size = Vector2(140, 35)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART as TextServer.AutowrapMode
		
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		name_label.add_theme_constant_override("outline_size", 6)
		name_label.add_theme_font_size_override("font_size", 16)
		add_child(name_label)
		
	# 2. Human-readable Description Body Label
	if not desc_label:
		desc_label = Label.new()
		desc_label.name = "DescriptionLabel"
		desc_label.position = Vector2(-65, -30)
		desc_label.size = Vector2(130, 110)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART as TextServer.AutowrapMode
		
		desc_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
		desc_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		desc_label.add_theme_constant_override("outline_size", 4)
		desc_label.add_theme_font_size_override("font_size", 12)
		add_child(desc_label)

func setup(data: Dictionary) -> void:
	card_data = data
	set_meta("card_data", data)
	update_card_visuals()

func update_card_visuals() -> void:
	ensure_labels_exist()
	
	# Header Text: (Cost) Name
	if name_label and card_data.has("name"):
		var text = card_data["name"]
		if card_data.has("cost"):
			text = "(%d) %s" % [card_data["cost"], card_data["name"]]
		name_label.text = text
		
		# Highlight upgraded cards with a vibrant green header font
		if card_data.get("is_upgraded", false):
			name_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45, 1.0))
		else:
			name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		
	# Body Text: Human-readable Description
	if desc_label:
		if card_data.has("description"):
			desc_label.text = card_data["description"]
		else:
			desc_label.text = ""
