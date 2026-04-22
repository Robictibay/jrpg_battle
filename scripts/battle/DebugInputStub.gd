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
	
	if actor.actor_name == "Knight":
		# Keep the Knight's combo going
		if not actor.is_charging:
			return { "actor": actor, "type": "charge", "target": null }
		else:
			return { "actor": actor, "type": "heavy_slash", "target": target }
			
	else: 
		# If the Mage drops below half health, use a Potion!
		if actor.current_hp < (actor.max_hp / 2):
			return { "actor": actor, "type": "potion", "target": actor }
		# Otherwise, Fireball!
		else:
			return { "actor": actor, "type": "fireball", "target": target }
