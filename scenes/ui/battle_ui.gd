extends Control

@export var battle_manager: Node
@export var attack_button: Button
@export var magic_button: Button
@export var skill_button: Button
@export var item_button: Button
@export var battle_log: RichTextLabel

var current_actor = null

func _ready():
	if battle_manager:
		battle_manager.player_action_requested.connect(_on_player_action_requested)
		battle_manager.action_resolved.connect(_on_action_resolved)

	if attack_button: attack_button.pressed.connect(_on_attack_pressed)
	if magic_button: magic_button.pressed.connect(_on_magic_pressed)
	if skill_button: skill_button.pressed.connect(_on_skill_pressed)
	if item_button: item_button.pressed.connect(_on_item_pressed)

	# FIX 1: Tell Godot to wait 1 frame before checking HP, so max_hp isn't 0!
	call_deferred("_update_all_hp_bars")

func _on_player_action_requested(actor):
	current_actor = actor
	if battle_log:
		battle_log.text += "\n▶ " + actor.actor_name.to_upper() + "'S TURN! Select an action...\n"

func _on_action_resolved(actor, type, target, log_text):
	if battle_log:
		battle_log.text += log_text + "\n"
	_update_all_hp_bars()

# --- BULLETPROOF HP BAR UPDATER ---
func _update_all_hp_bars():
	if not battle_manager: return

	var knight = battle_manager.get_node_or_null("PlayerParty/Knight")
	var mage   = battle_manager.get_node_or_null("PlayerParty/Mage")
	var gob    = battle_manager.get_node_or_null("EnemyParty/Goblin")
	var slime  = battle_manager.get_node_or_null("EnemyParty/Slime")

	# Update Knight
	if knight and knight.max_hp > 0: 
		battle_manager.get_node("PlayerParty/Knight/ProgressBar").value = float(knight.current_hp) / float(knight.max_hp) * 100.0
		if knight.current_hp <= 0: 
			knight.get_node("AnimatedSprite2D").hide()
			battle_manager.get_node("PlayerParty/Knight/ProgressBar").hide()

	# Update Mage
	if mage and mage.max_hp > 0:   
		battle_manager.get_node("PlayerParty/Mage/ProgressBar").value = float(mage.current_hp) / float(mage.max_hp) * 100.0
		if mage.current_hp <= 0: 
			mage.get_node("AnimatedSprite2D").hide()
			battle_manager.get_node("PlayerParty/Mage/ProgressBar").hide()

	# Update Goblin
	if gob and gob.max_hp > 0:    
		battle_manager.get_node("EnemyParty/Goblin/ProgressBar").value = float(gob.current_hp) / float(gob.max_hp) * 100.0
		if gob.current_hp <= 0: 
			gob.get_node("AnimatedSprite2D").hide()
			battle_manager.get_node("EnemyParty/Goblin/ProgressBar").hide()

	# Update Slime
	if slime and slime.max_hp > 0:  
		battle_manager.get_node("EnemyParty/Slime/ProgressBar").value = float(slime.current_hp) / float(slime.max_hp) * 100.0
		if slime.current_hp <= 0: 
			slime.get_node("AnimatedSprite2D").hide()
			battle_manager.get_node("EnemyParty/Slime/ProgressBar").hide()

	# --- WIN OR LOSE ANNOUNCEMENT ---
	if gob and slime and gob.current_hp <= 0 and slime.current_hp <= 0:
		if battle_log and not "YOU WIN" in battle_log.text:
			battle_log.text += "\n🏆 YOU WIN! BATTLE OVER! 🏆\n"
			
	elif knight and mage and knight.current_hp <= 0 and mage.current_hp <= 0:
		if battle_log and not "YOU LOSE" in battle_log.text:
			battle_log.text += "\n💀 YOU LOSE! GAME OVER! 💀\n"

# --- BUTTON CLICKS ---
func _on_attack_pressed():
	if current_actor: _send_action("attack")

func _on_magic_pressed():
	if current_actor and current_actor.actor_name == "Mage":
		_send_action("fireball")
	else:
		if battle_log: battle_log.text += "x The " + current_actor.actor_name + " doesn't know magic!\n"

func _on_skill_pressed():
	if current_actor and current_actor.actor_name == "Knight":
		if current_actor.is_charging:
			_send_action("heavy_slash")
		else:
			_send_action("charge")
	else:
		if battle_log: battle_log.text += "x The " + current_actor.actor_name + " has no skills!\n"

func _on_item_pressed():
	if current_actor and current_actor.actor_name == "Mage":
		_send_action("potion")
	else:
		if battle_log: battle_log.text += "x The " + current_actor.actor_name + " has no items!\n"

# --- SEND TO STATE MACHINE ---
func _send_action(action_type):
	if not current_actor or not battle_manager: return

	var target = null

	if action_type == "potion":
		target = current_actor
	elif action_type != "charge" and action_type != "defend":
		target = _get_first_alive_enemy()

	# FIX 2: Immediate UI Feedback so you aren't left guessing!
	if battle_log:
		battle_log.text += ">> " + current_actor.actor_name + " locked in: " + action_type.to_upper() + "\n"

	var saved_actor = current_actor
	current_actor = null # Erase the current actor so you can't double-click!

	battle_manager.submit_player_action({
		"actor": saved_actor,
		"type": action_type,
		"target": target
	})

func _get_first_alive_enemy():
	for enemy in battle_manager.enemy_party:
		if enemy.is_alive():
			return enemy
	return null
