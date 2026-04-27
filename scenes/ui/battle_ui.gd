extends Control

@export var battle_manager: Node
@export var attack_button: Button
@export var magic_button: Button
@export var skill_button: Button
@export var item_button: Button
@export var battle_log: RichTextLabel

var current_actor = null

func _ready():
	# Connect to your finished BattleManager
	if battle_manager:
		battle_manager.player_action_requested.connect(_on_player_action_requested)
		battle_manager.action_resolved.connect(_on_action_resolved)
		
	# Connect the buttons
	if attack_button: attack_button.pressed.connect(_on_attack_pressed)
	if magic_button: magic_button.pressed.connect(_on_magic_pressed)
	if skill_button: skill_button.pressed.connect(_on_skill_pressed)
	if item_button: item_button.pressed.connect(_on_item_pressed)

func _on_player_action_requested(actor):
	current_actor = actor

func _on_action_resolved(actor, type, target, log_text):
	if battle_log:
		battle_log.text += log_text + "\n"

# --- BUTTON CLICKS ---
func _on_attack_pressed():
	_send_action("attack")

func _on_magic_pressed():
	_send_action("fireball")

func _on_skill_pressed():
	if current_actor.actor_name == "Knight":
		if current_actor.is_charging:
			_send_action("heavy_slash")
		else:
			_send_action("charge")
	else:
		_send_action("defend")

func _on_item_pressed():
	_send_action("potion")

# --- SEND TO YOUR STATE MACHINE ---
func _send_action(action_type):
	if not current_actor or not battle_manager: return
	
	var target = null
	
	if action_type == "potion":
		target = current_actor
	elif action_type != "charge" and action_type != "defend":
		target = _get_first_alive_enemy()
		
	battle_manager.submit_player_action({
		"actor": current_actor,
		"type": action_type,
		"target": target
	})

func _get_first_alive_enemy():
	for enemy in battle_manager.enemy_party:
		if enemy.is_alive():
			return enemy
	return null
