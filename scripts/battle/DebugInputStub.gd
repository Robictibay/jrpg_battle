extends Node

@export var battle_manager: Node

func _ready() -> void:
	if battle_manager:
		battle_manager.player_action_requested.connect(_on_request)

func _on_request(actor: Actor) -> void:
	# Add a tiny delay so the console prints feel like a real game playing out
	await get_tree().create_timer(0.5).timeout  
	
	var action := _pick_scripted_action(actor)
	battle_manager.submit_player_action(action)

func _pick_scripted_action(actor: Actor) -> Dictionary:
	var living_enemies = battle_manager.enemy_party.filter(func(e): return e.is_alive())
	var target = living_enemies[0] if living_enemies.size() > 0 else null
	
	# Hardcoded test actions
	if actor.actor_name == "Knight":
		return { "actor": actor, "type": "attack", "target": target }
	else:
		return { "actor": actor, "type": "defend", "target": null }
