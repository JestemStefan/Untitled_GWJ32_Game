extends Node2D
class_name Encounter

onready var encounter_player: EncounterPlayer = $Encounter_Player
onready var player_sprite = $Encounter_Player/PlayerSprite
onready var player_animplayer: AnimationPlayer = $Encounter_Player/PlayerAnimationPlayer

onready var encounter_enemy: Node2D = $Encounter_Enemy
onready var enemy_sprite: Sprite
onready var enemy_animplayer: AnimationPlayer

onready var dices: Node2D = $Dices

var dice_in_hand: Dice
var dices_in_memory: Array

var picked_action: ActionBox

var enemy_stats: Resource


enum Turn{NOONE, PLAYER, ENEMY}
var current_turn: int = Turn.PLAYER

var action_buffer: Dictionary = {"Attack": 0,
								"Block": 0,
								"Heal": 0}

# Called when the node enters the scene tree for the first time.
func _ready():
	GameController.current_encounter = self


func start_encounter():
	encounter_enemy.load_enemy_data(enemy_stats)
	
	if enemy_stats.isBoss:
		GameState.player_dice_amount = 7
	
	player_animplayer.play("Idle")
	var player_tween:Tween = slide_player_in()
	
	
	enemy_animplayer.play("Idle")
	var enemy_tween:Tween = slide_enemy_in()
	
	yield(player_tween,"tween_completed")
	player_tween.call_deferred("free")
	yield(enemy_tween,"tween_completed")
	enemy_tween.call_deferred("free")
	
	
	$Encounter_Player/PlayerHealth.show()
	$Encounter_Enemy/EnemyHealthBar.show()
	
	$RollButton.show()
	$EndTurnButton.show()

	switch_turns(Turn.PLAYER) 


func slide_player_in():
	var player_tween: Tween = Tween.new()
	add_child(player_tween)
	var _err1 = player_tween.interpolate_property(player_sprite, 
										"offset", 
										player_sprite.offset, 
										Vector2(0,0), 
										2, 
										Tween.TRANS_CUBIC, 
										Tween.EASE_OUT)
	
	var _err2 = player_tween.interpolate_property($Encounter_Player/Combat_Platform, 
										"offset", 
										$Encounter_Player/Combat_Platform.offset, 
										Vector2(0,0), 
										1, 
										Tween.TRANS_CUBIC, 
										Tween.EASE_OUT)
	
	var _err3 = player_tween.interpolate_property($Encounter_Player/UI_Player_Name, 
										"offset", 
										$Encounter_Player/UI_Player_Name.offset, 
										Vector2(0,0), 
										1, 
										Tween.TRANS_CUBIC, 
										Tween.EASE_OUT)

	var _err4 = player_tween.interpolate_property($UI_Player, 
										"offset", 
										$UI_Player.offset, 
										Vector2(0,0), 
										1, 
										Tween.TRANS_CUBIC, 
										Tween.EASE_OUT)
	
	var _tween_start = player_tween.start()
	
	return player_tween


func slide_enemy_in():
	var enemy_tween: Tween = Tween.new()
	add_child(enemy_tween)
	var _err1 = enemy_tween.interpolate_property(enemy_sprite, 
										"offset:x", 
										enemy_sprite.offset.x, 
										0, 
										2, 
										Tween.TRANS_CUBIC, 
										Tween.EASE_OUT)

	var _err2 = enemy_tween.interpolate_property($Encounter_Enemy/Combat_Platform, 
											"offset:x", 
											$Encounter_Enemy/Combat_Platform.offset.x, 
											0, 
											1, 
											Tween.TRANS_CUBIC, 
											Tween.EASE_OUT)
		
	var _err3 = enemy_tween.interpolate_property($Encounter_Enemy/UI_Enemy_Name, 
											"offset:x", 
											$Encounter_Enemy/UI_Enemy_Name.offset.x, 
											0, 
											1, 
											Tween.TRANS_CUBIC, 
											Tween.EASE_OUT)
		
	var _err4 = enemy_tween.interpolate_property($UI_Enemy, 
											"offset:x", 
											$UI_Enemy.offset.x, 
											0, 
											1, 
											Tween.TRANS_CUBIC, 
											Tween.EASE_OUT)
	
	var _tween_start = enemy_tween.start()
	
	return enemy_tween


func end_encounter():
	GameState.add_dice()
	GameController.end_encounter()


func execute_buffer_actions():
	
	for action_name in action_buffer.keys():
		
		var action_value: int = action_buffer[action_name]
		
		if action_value > 0:
		
			match current_turn:
				
				Turn.PLAYER:
					match action_name:
						
						"Attack":
							encounter_enemy.take_damage(action_value)
						
						"Block":
							encounter_player.get_block(action_value)
						
						"Heal":
							encounter_player.heal(action_value)
				
				Turn.ENEMY:
					match action_name:
						
						"Attack":
							encounter_player.take_damage(action_value)
						
						"Block":
							encounter_enemy.get_block(action_value)
							
						"Heal":
							encounter_enemy.heal(action_value)


func reset_action_buffer():
	
	for action_name in action_buffer.keys():
		action_buffer[action_name] = 0
	
	match current_turn:
		Turn.PLAYER:
			encounter_player.update_stats(action_buffer)
		
		Turn.ENEMY:
			encounter_enemy.update_stats(action_buffer)


func switch_turns(next_turn: int):
	
	#reset values in bufer
	for action_name in action_buffer.keys():
		
		var action_value: int = 0
	
	dices_in_memory = []
	
	for child in dices.get_children():
		if child is Dice:
			child.call_deferred("free")
	
	if encounter_enemy.current_state != encounter_enemy.State.DEAD:
		
		match next_turn:
			
			Turn.PLAYER:
				$RollButton.show()
				$RollButton.set_disabled(false)
				$UndoActionButton.show()
				$EndTurnButton.show()
				current_turn = Turn.PLAYER
				
				encounter_player.show_stuff()
				encounter_player.reset_block()
				
				encounter_enemy.hide_stuff()
				
			Turn.ENEMY:
				$RollButton.hide()
				$RollButton.set_disabled(true)
				$UndoActionButton.hide()
				$EndTurnButton.hide()
				
				encounter_player.hide_stuff()
				
				encounter_enemy.reset_block()
				encounter_enemy.show_stuff()
				
				current_turn = Turn.ENEMY
				
				encounter_enemy.play_turn()


func _on_EndTurnButton_button_up():
	
	execute_buffer_actions()
	reset_action_buffer()
	
	switch_turns(Turn.ENEMY)
	

func _on_RollButton_button_up():
	$RollButton.set_disabled(true)
	
	var generated_dices: Array = dices.roll_random(GameState.player_dice_amount)
	GameController.current_encounter.dices_in_memory = generated_dices
	
	for dice in generated_dices:
		var dice_tween: Tween = tween_dice(dice, dice.initial_position)
		yield(dice_tween, "tween_completed")
		dice_tween.call_deferred("free")
	
	
func _on_Encounter_Enemy_enemy_died():
	
	$RollButton.hide()
	$UndoActionButton.hide()
	$EndTurnButton.hide()
	
	#$Encounter_Player/Skills.hide()
	#$Encounter_Player/PlayerHealth.hide()
	
	encounter_enemy.hide_stuff()
	encounter_player.hide_stuff()
	
	dices.hide()
	
	var tween: Tween = Tween.new()
	add_child(tween)
	var _err = tween.interpolate_property(enemy_sprite, 
										"offset", 
										null, 
										Vector2(0,128), 1, 
										Tween.TRANS_CUBIC, 
										Tween.EASE_OUT)
	
	var _tween_start = tween.start()
	yield(tween, "tween_completed")
	
	$BackToMapButton.show()


func _on_BackToMapButton_button_up():
	end_encounter()


func tween_dice(dice: Dice, final_pos: Vector2):
	
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(dice, 
								"global_position", 
								null, 
								final_pos, 
								0.3, 
								Tween.TRANS_BOUNCE, 
								Tween.EASE_OUT)
	tween.start()
	
	return tween


func _on_Dice_dice_picked_up(dice: Dice):
	dice_in_hand = dice


func _on_Dice_dice_dropped(dice: Dice):
	if picked_action != null:
		
		dice.last_position = picked_action.global_position
		dice.enter_state(dice.State.USED)
		dice.hide()
		
		picked_action.use_dice(dice_in_hand.dice_value)
		
		picked_action = null
		#dice.call_deferred("free")
		
		
	else:
		dice.enter_state(dice.State.FREE)
	
	dice_in_hand = null


func _on_Action_Box_actionbox_triggered(action_name: String, dice_value: int):
	pass
	
	action_buffer[action_name] += dice_value
	
	match current_turn:
		Turn.PLAYER:
			encounter_player.update_stats(action_buffer)
		
		Turn.ENEMY:
			encounter_enemy.update_stats(action_buffer)


	

func _on_UndoActionButton_button_up():
	
	for action_name in action_buffer.keys():
		
		action_buffer[action_name] = 0
	
	match current_turn:
		Turn.PLAYER:
			encounter_player.update_stats(action_buffer)
		
		Turn.ENEMY:
			pass
	
	for hidden_dice in dices_in_memory:
		hidden_dice.enter_state(hidden_dice.State.FREE)
		hidden_dice.show()
		
		
