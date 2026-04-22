extends Node
class_name Actor

# We added these two signals for the UI to use later
signal hp_changed(actor: Actor, new_hp: int, max_hp: int)
signal died(actor: Actor)

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
	
	# Emit the signal so UI health bars can update later
	hp_changed.emit(self, current_hp, max_hp)

	if current_hp <= 0:
		print(actor_name + " was defeated!")
		died.emit(self)

func is_alive() -> bool:
	return current_hp > 0

func reset_turn_state() -> void:
	is_defending = false
