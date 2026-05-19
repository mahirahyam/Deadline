extends Node2D

# variabel onready
@onready var room = $Room
@onready var room_dawn = $Room/BGLuar_Dawn
@onready var hp_button = $Room/HPClickArea
@onready var laptop_ui = $LaptopUI
@onready var os = $LaptopUI/OS_UI
@onready var screen_ol = $LaptopUI/ScreenOL
@onready var screen_ol2 = $LaptopUI/ScreenOL2
@onready var task_window = $LaptopUI/OS_UI/TaskWindow
@onready var article_text = %ArcticleText1
@onready var sticky_note_vbox = $LaptopUI/OS_UI/StickyNotes/MarginContainer/VBoxContainer 
@onready var black_fade = $TransitionLayer/BlackFade
@onready var end_screen = $TransitionLayer/EndScreen
@onready var day_label = $TransitionLayer/BlackFade/DayLabel
@onready var laptop_area = $Room/LaptopClickArea
@onready var vignette = $PostProcess/Vignette
@onready var ghost = $Room/PenampakanJendela
@onready var sprite_tutup = $Room/PenampakanJendela/SpriteTutup
@onready var sprite_buka = $Room/PenampakanJendela/SpriteBuka
@onready var sfx_click = $Audio/UIClick
@onready var sfx_crash = $Audio/LaptopCrash
@onready var sfx_jumpscare = $Audio/Jumpscare
@onready var sfx_rustle = $Audio/Rustle
@onready var bgm_ambience = $Audio/Ambience

# var game
var quotes_found = 0
var found_ids = []
var current_day = 1
var is_task_completed = false
var current_article_index = 0
var target_articles_per_day = { 1: 3, 2: 5, 3: 1 }
var is_busy = false

var clue_mapping = {
	"k1": "Clue1",
	"k2": "Clue2",
	"k3": "Clue3"
}

func _ready():
	laptop_ui.visible = false
	os.modulate.a = 1.0
	screen_ol.modulate.a = 0
	screen_ol2.visible = false
	task_window.visible = false
	end_screen.visible = false
	black_fade.visible = true
	black_fade.modulate.a = 1.0
	day_label.modulate.a = 0.0
	room_dawn.modulate.a = 0.0
	
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.visible = false
	sprite_buka.visible = false
	sprite_tutup.visible = true
	
	bgm_ambience.play()
	start_routine(1)

func say(text: String, duration: float = 3.0):
	var label = $DialogueSystem/NinePatchRect/DialogueLabel
	label.text = text
	$DialogueSystem.visible = true
	await get_tree().create_timer(duration).timeout
	$DialogueSystem.visible = false

func play_sfx(player: AudioStreamPlayer):
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

# SISTEM TRANSISI HARI
func start_routine(day):
	current_day = day
	update_laptop_content(day, 0)
	laptop_area.disabled = true
	
	bgm_ambience.volume_db = 0 
	
	var tween = create_tween()
	tween.tween_property(black_fade, "modulate:a", 0.0, 2.0)
	await tween.finished
	
	black_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	if day == 1:
		await say("Haduh, masih harus ngerjain tugas...")
	elif day == 2:
		apply_stress_effects(0.3)
		if not bgm_ambience.playing: 
			bgm_ambience.play()
		await say("Masih banyak tugas yang belum kukerjakan...")
	elif day == 3:
		apply_stress_effects(0.5)
		bgm_ambience.stop()
		await say("Kenapa rasanya aku ga pernah selesai selesai ya...")
	
	laptop_area.disabled = false

func start_new_day(day_number):
	var tween = create_tween()
	tween.tween_property(black_fade, "modulate:a", 1.0, 1.5)
	
	var t_audio = create_tween()
	t_audio.tween_property(bgm_ambience, "volume_db", -40.0, 1.5)
	
	await tween.finished
	room_dawn.modulate.a = 0.0
	bgm_ambience.stop()
	bgm_ambience.volume_db = 0.0
	
	quotes_found = 0
	found_ids = []
	current_article_index = 0
	is_task_completed = false
	
	day_label.text = "Hari ke - " + str(day_number)
	var t_text = create_tween()
	t_text.tween_property(day_label, "modulate:a", 1.0, 0.5)
	await t_text.finished
	await get_tree().create_timer(1.5).timeout
	
	var t_text_hide = create_tween()
	t_text_hide.tween_property(day_label, "modulate:a", 0.0, 0.5)
	await t_text_hide.finished
	
	start_routine(day_number)

func transition_to_dawn_texture():
	var t_fade = create_tween()
	t_fade.tween_property(room_dawn, "modulate:a", 1.0, 2.0)
	await t_fade.finished

# SISTEM LAPTOP
func _on_laptop_click_area_pressed():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(room, "scale", Vector2(1.5, 1.5), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(room, "position", Vector2(-300, -200), 0.5).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	laptop_ui.visible = true
	var fade_tween = create_tween()
	fade_tween.tween_property(screen_ol, "modulate:a", 0.8, 0.3)
	
func _on_task_icon_pressed():
	play_sfx(sfx_click)
	task_window.visible = true

func _on_close_app_button_pressed():
	play_sfx(sfx_click)
	task_window.visible = false

func _on_power_exit_pressed():
	if current_day == 3 and quotes_found >= 3: return
	
	laptop_ui.visible = false
	screen_ol.modulate.a = 0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(room, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(room, "position", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	
	if is_task_completed:
		await transition_to_dawn_texture()
		start_new_day(current_day + 1)
	else:
		await say("Belum selesai... aku harus lanjut nanti.")

func update_laptop_content(day, article_idx):
	var file_path = "res://data_jurnal.json"
	if not FileAccess.file_exists(file_path): return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var all_days_data = JSON.parse_string(file.get_as_text())
	
	if not all_days_data or not all_days_data.has(str(day)): return
	var articles_today = all_days_data[str(day)]
	if article_idx >= articles_today.size(): return
	var data = articles_today[article_idx]
	
	if article_text.meta_clicked.is_connected(_on_meta_clicked):
		article_text.meta_clicked.disconnect(_on_meta_clicked)
		
	article_text.text = ""
	article_text.clear()
	article_text.text = data["text"]
	
	article_text.meta_clicked.connect(_on_meta_clicked)
	
	for i in range(3):
		var node_name = "Clue" + str(i + 1)
		var clue_node = sticky_note_vbox.get_node(node_name)
		if clue_node:
			clue_node.modulate.a = 1.0
			clue_node.bbcode_enabled = true
			clue_node.text = data["sticky"][i].replace("[s]", "").replace("[/s]", "")

# GAMEPLAY
func _on_meta_clicked(meta):
	if is_busy: return
	play_sfx(sfx_click)
	if clue_mapping.has(meta) and not meta in found_ids:
		found_ids.append(meta)
		handle_quote_found(meta)

func handle_quote_found(id):
	if is_busy: return
	quotes_found += 1
	
	var node_name = clue_mapping[id]
	var clue_node = sticky_note_vbox.get_node(node_name)
	if clue_node:
		clue_node.text = "[s]" + clue_node.text + "[/s]"
		clue_node.modulate.a = 0.5

	if current_day == 3:
		apply_stress_effects(0.4 + (quotes_found * 0.1))
		match quotes_found:
			1: say("Ini... apa...?")
			2:
				ghost.visible = true
				ghost.z_index = 0
				sprite_tutup.modulate.a = 0.0
				var t = create_tween()
				t.tween_property(sprite_tutup, "modulate:a", 0.7, 4.0) 
				say("Aku ga inget ada tugas ini...")
			3: 
				is_busy = true
				await say("CUKUP!! Aku ngga tau ini ulah siapa, tapi aku capek banget!!")
				trigger_laptop_crash()
	else:
		if quotes_found >= 3:
			is_busy = true
			quotes_found = 0 
			found_ids = []
			call_deferred("finish_task")

func finish_task():
	current_article_index += 1
	var max_articles = target_articles_per_day[current_day]
	
	var t = create_tween().set_loops(2)
	t.tween_property(os, "modulate:a", 0.3, 0.05) 
	t.tween_property(os, "modulate:a", 1.0, 0.05)
	await t.finished

	if current_article_index < max_articles:
		update_laptop_content(current_day, current_article_index)
		await say("Masih ada lagi...")
		is_busy = false
	else:
		is_task_completed = true
		is_busy = false
		if current_day == 1:
			await say("Akhirnya selesai. Waktunya istirahat.")
		elif current_day == 2:
			await say("Selesai... Rasanya capek banget. Udahan dulu deh.")

# EFEK
func apply_stress_effects(stress_level: float):
	var mat = vignette.material as ShaderMaterial
	if mat:
		vignette.visible = true
		var tween = create_tween()
		tween.tween_method(
			func(val): mat.set_shader_parameter("intensity", val),
			mat.get_shader_parameter("intensity"),
			stress_level,
			2.0
		)

func trigger_laptop_crash():
	os.mouse_filter = Control.MOUSE_FILTER_STOP
	Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
	
	sfx_crash.play()
	var original_os_pos = os.position

	screen_ol2.visible = true
	var t_color = create_tween()
	t_color.tween_property(screen_ol2, "color", Color(1.0, 0.0, 0.0, 0.8), 0.1)
	
	var t_shake = create_tween().set_loops(20)
	t_shake.tween_property(os, "position", original_os_pos + Vector2(randf_range(-20,20), randf_range(-20,20)), 0.04)
	t_shake.tween_property(os, "position", original_os_pos, 0.04)
	
	await say("HAH?! Kenapa ini?!", 1.5)
	
	t_shake.kill()
	os.position = original_os_pos
	
	var t_exit = create_tween().set_parallel(true)
	t_exit.tween_property(room, "scale", Vector2(1, 1), 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t_exit.tween_property(room, "position", Vector2(0, 0), 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	t_exit.tween_property(os, "modulate:a", 0.0, 1.0)
	t_exit.tween_property(screen_ol2, "color:a", 0.0, 1.0)
	
	await t_exit.finished
	
	laptop_ui.visible = false
	laptop_area.disabled = true
	is_task_completed = true
	
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	black_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	await say("Aku ngga bisa lagi... Aku muak...")
	await say("Siapa itu di jendela..? Kamarku kan di lantai 2...")

# JUMPSCARE & ENDING
func _on_penampakan_jendela_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_day == 3 and is_task_completed:
			trigger_jumpscare()

func trigger_jumpscare():
	sfx_jumpscare.play()
	ghost.input_pickable = false
	vignette.visible = false
	
	sprite_tutup.visible = false
	sprite_buka.visible = true
	sprite_buka.modulate.a = 1.0
	
	var shake = create_tween()
	shake.tween_property(room, "position", Vector2(randf_range(-30, 30), randf_range(-30, 30)), 0.05)
	shake.tween_property(room, "position", Vector2(0, 0), 0.05)
	
	await get_tree().create_timer(0.5).timeout
	ghost.visible = false
	
	await say("AAAHHHHHH!! APA ITU!?!?")
	
	trigger_true_ending()

func trigger_true_ending():
	await say("Nggak... cukup... aku ga bisa kayak gini lagi...")
	if sfx_rustle: sfx_rustle.play()
	hp_button.visible = false
	await say("(Mengambil HP di meja...)")
	
	await say("Halo? Maaf ganggu... Kamu lagi sibuk?")
	await say("Aku... Aku cuma butuh denger suara orang. Aku ngerasa capek banget akhir akhir ini...")
	
	var fade = create_tween()
	fade.tween_property(black_fade, "modulate:a", 1.0, 4.0)
	await fade.finished
	
	show_burnout_statistics()

func show_burnout_statistics():
	var label_target = $TransitionLayer/EndScreen/FinalLabel
	var stats_text = "Paparan stres berkelanjutan tanpa istirahat yang cukup dapat memicu burnout hingga depresi.\n\n"
	stats_text += "Istirahat adalah bagian dari produktivitas.\n\n"
	stats_text += "Hubungi teman atau orang terdekat bila dirasa membutuhkan."
	
	label_target.text = stats_text
	label_target.modulate.a = 0.0
	end_screen.visible = true
	
	var t_show = create_tween()
	t_show.tween_property(label_target, "modulate:a", 1.0, 2.0)
	await t_show.finished
	
	await get_tree().create_timer(5.0).timeout
	await say("(Klik di mana saja untuk kembali ke Menu Utama)", 2.0)
	
	var waiting_for_input = true
	while waiting_for_input:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			waiting_for_input = false
		await get_tree().process_frame
		
	var fade_out = create_tween()
	fade_out.tween_property(black_fade, "modulate:a", 1.0, 1.5)
	await fade_out.finished
	
	get_tree().change_scene_to_file("res://menu.tscn")

# CURSOR
func _on_arcticle_text_1_meta_hover_started(_meta):
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
func _on_arcticle_text_1_meta_hover_ended(_meta):
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
