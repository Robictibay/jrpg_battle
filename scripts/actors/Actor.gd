extends Node
class_name Actor

@export var actor_name: String = ""
@export var max_hp: int = 100
@export var attack_power: int = 10
@export var is_player: bool = true

var current_hp: int
var is_defending: bool = false

func _ready() -> void:
	current_hp = max_hp

func take_damage(amount: int) -> void:
	if is_defending:
		amount /= 2
		print(actor_name + " blocked some damage!")

	current_hp = clampi(current_hp - amount, 0, max_hp)
	print(actor_name + " took " + str(amount) + " damage. HP: " + str(current_hp))

	if current_hp <= 0:
		print(actor_name + " was defeated!")

func is_alive() -> bool:
	return current_hp > 0

func reset_turn_state() -> void:
	is_defending = false
