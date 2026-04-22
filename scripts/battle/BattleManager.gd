extends Node

@onready var player_party: Array = $PlayerParty.get_children()
@onready var enemy_party: Array = $EnemyParty.get_children()

func _ready() -> void:
	randomize()
	print("Battle started!")
	start_test_round()

func start_test_round() -> void:
	print("--- Player Phase ---")

	var knight: Actor = $PlayerParty/Knight
	var mage: Actor = $PlayerParty/Mage
	var goblin: Actor = $EnemyParty/Goblin
	var slime: Actor = $EnemyParty/Slime

	if knight.is_alive() and goblin.is_alive():
		perform_attack(knight, goblin)

	if mage.is_alive() and slime.is_alive():
		perform_attack(mage, slime)

	check_win_loss()
	if not any_enemies_alive() or not any_players_alive():
		return

	print("--- Enemy Phase ---")

	if goblin.is_alive() and knight.is_alive():
		perform_attack(goblin, knight)

	if slime.is_alive() and mage.is_alive():
		perform_attack(slime, mage)

	check_win_loss()

func perform_attack(attacker: Actor, target: Actor) -> void:
	var rng_multiplier: float = randf_range(0.8, 1.2)
	var damage: int = int(attacker.attack_power * rng_multiplier)

	print(attacker.actor_name + " attacks " + target.actor_name + "!")
	target.take_damage(damage)

func any_players_alive() -> bool:
	for player in player_party:
		if player is Actor and player.is_alive():
			return true
	return false

func any_enemies_alive() -> bool:
	for enemy in enemy_party:
		if enemy is Actor and enemy.is_alive():
			return true
	return false

func check_win_loss() -> void:
	if not any_players_alive():
		print("Player Party Wipeout! You Lose.")
	elif not any_enemies_alive():
		print("Enemy Party Wipeout! You Win.")
