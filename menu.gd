extends Control

@onready var menu_panel = $Menu
@onready var how_to_play_panel = $HowToPlay
@onready var btn_start = $Menu/Start
@onready var btn_htp = $Menu/HTP
@onready var btn_exit = $Menu/Exit
@onready var btn_close = $HowToPlay/Close
@onready var bgm_menu = $BGMenu

var game_scene = "res://game.tscn"

func _ready():
	how_to_play_panel.visible = false
	menu_panel.visible = true
	
	bgm_menu.play()
	
	btn_start.pressed.connect(_on_start_pressed)
	btn_htp.pressed.connect(_on_htp_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	
	setup_hover_cursors()

# FUNGSI TOMBOL
func _on_start_pressed():
	btn_start.disabled = true 
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	bgm_menu.stop()
	get_tree().change_scene_to_file(game_scene)

func _on_htp_pressed():
	menu_panel.visible = false
	how_to_play_panel.visible = true
	
	how_to_play_panel.modulate.a = 0.0
	create_tween().tween_property(how_to_play_panel, "modulate:a", 1.0, 0.2)

func _on_close_pressed():
	how_to_play_panel.visible = false
	menu_panel.visible = true

func _on_exit_pressed():
	get_tree().quit()

func setup_hover_cursors():
	var buttons = [btn_start, btn_htp, btn_exit, btn_close]
	for btn in buttons:
		btn.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		btn.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
