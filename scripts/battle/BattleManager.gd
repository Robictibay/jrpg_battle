extends Node

# --- SIGNALS FOR UI ---
signal battle_started
signal player_action_requested(actor: Actor)
signal action_resolved(actor: Actor, action_type: String, target: Actor, log_text: String)
signal battle_ended(player_won: bool)

# --- STATE MACHINE ---
enum BattleState { START, PLAYER_SELECT, PLAYER_RESOLVE, ENEMY_SELECT, ENEMY_RESOLVE, TURN_END, VICTORY, DEFEAT }
var current_state: BattleState = BattleState.START

@onready var player_party: Array = $PlayerParty.get_children()
@onready var enemy_party: Array = $EnemyParty.get_children()

var action_queue: Array[Dictionary] = []
var players_needing_commands: Array = []

func _ready() -> void:
	randomize()
	print("--- BATTLE SYSTEM INITIALIZED ---")
	call_deferred("start_battle") # Waits 1 frame to ensure everything is loaded safely

func start_battle() -> void:
	battle_started.emit()
	transition_to(BattleState.PLAYER_SELECT)

func transition_to(new_state: BattleState) -> void:
	current_state = new_state
	
	match current_state:
		BattleState.PLAYER_SELECT:
			action_queue.clear()
			# Gather all living players who need to make a move
			players_needing_commands = player_party.filter(func(p): return p.is_alive())
			request_next_player_action()
			
		BattleState.PLAYER_RESOLVE:
			print("--- Resolving Player Actions ---")
			resolve_queue(BattleState.ENEMY_SELECT)
			
		BattleState.ENEMY_SELECT:
			generate_enemy_actions()
			
		BattleState.ENEMY_RESOLVE:
			print("--- Resolving Enemy Actions ---")
			resolve_queue(BattleState.TURN_END)
			
		BattleState.TURN_END:
			# Reset defense flags for the new round
			for actor in player_party + enemy_party:
				if actor.is_alive():
					actor.reset_turn_state()
			transition_to(BattleState.PLAYER_SELECT)
			
		BattleState.VICTORY:
			print("VICTORY! Enemy Party Defeated.")
			battle_ended.emit(true)
			
		BattleState.DEFEAT:
			print("DEFEAT! Player Party Wiped Out.")
			battle_ended.emit(false)

# --- PLAYER SELECTION LOGIC ---
func request_next_player_action() -> void:
	if players_needing_commands.is_empty():
		transition_to(BattleState.PLAYER_RESOLVE)
		return
		
	var current_actor: Actor = players_needing_commands.pop_front()
	# This pauses the manager. It waits here until submit_player_action is called!
	player_action_requested.emit(current_actor) 

func submit_player_action(action: Dictionary) -> void:
	action_queue.append(action)
	request_next_player_action() 

# --- ENEMY SELECTION LOGIC ---
func generate_enemy_actions() -> void:
	var living_enemies = enemy_party.filter(func(e): return e.is_alive())
	var living_players = player_party.filter(func(p): return p.is_alive())
	
	for enemy in living_enemies:
		if living_players.is_empty(): break
		
		# Simple AI: 70% chance to attack a random player, 30% to defend
		var is_attacking = randf() < 0.7
		var target = living_players.pick_random() if is_attacking else null
		var type = "attack" if is_attacking else "defend"
		
		action_queue.append({"actor": enemy, "type": type, "target": target})
		
	transition_to(BattleState.ENEMY_RESOLVE)

# --- RESOLUTION LOGIC ---
func resolve_queue(next_state: BattleState) -> void:
	for action in action_queue:
		var actor: Actor = action["actor"]
		var target: Actor = action["target"]
		var type: String = action["type"]
		
		if not actor.is_alive():
			continue # Dead characters can't act
			
		if target != null and not target.is_alive():
			print(actor.actor_name + "'s target is already dead! Attack missed.")
			continue 
			
		# Execute the command
		match type:
			"attack":
				var rng_mod = randf_range(0.8, 1.2)
				var dmg = int(actor.attack_power * rng_mod)
				var log_txt = actor.actor_name + " attacks " + target.actor_name + "!"
				print(log_txt)
				target.take_damage(dmg)
				action_resolved.emit(actor, type, target, log_txt)
				
			"defend":
				actor.is_defending = true
				var log_txt = actor.actor_name + " takes a defensive stance!"
				print(log_txt)
				action_resolved.emit(actor, type, target, log_txt)
		
		# Check for Win/Loss after EVERY move
		if check_win_loss(): return 
		
	action_queue.clear()
	transition_to(next_state)

func check_win_loss() -> bool:
	var players_alive = player_party.any(func(p): return p.is_alive())
	var enemies_alive = enemy_party.any(func(e): return e.is_alive())
	
	if not players_alive:
		transition_to(BattleState.DEFEAT)
		return true
	if not enemies_alive:
		transition_to(BattleState.VICTORY)
		return true
	return false
