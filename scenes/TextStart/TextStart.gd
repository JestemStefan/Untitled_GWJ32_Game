extends Control


onready var anim = get_node("AnimationPlayer")

func _ready():
	get_node("Text1").percent_visible = 0
	get_node("Text2").percent_visible = 0
	get_node("Text3").percent_visible = 0
	get_node("BtnOK").hide()
	
	anim.play("Show")



func _on_BtnOK_clicked(_object):
	anim.play("Hide")
	yield(anim, "animation_finished")
	
	var _err1 = get_tree().change_scene("res://scenes/Testing/GameWorld.tscn")
