class_name PlayerUi
extends VBoxContainer


@onready var _bar = $PowerupBar
@onready var _scoreLbl = $PanelContainer/ScoreLabel
@onready var _hpLbl = $HealthLabel
@onready var _playerLbl = $PanelContainer/PlayerLabel


var _col:Color



func write_resapwning():
	$Label.text = "Respawning..."
	
func write_bash_mode():
	$Label.text = "BASH MODE"



func reset(player_id:int):
	_col = Globals.PLAYER_COLORS[player_id]
	update_score(0)
	update_health(Globals.MAX_HP)
	reset_bar()
	_playerLbl.text = "P"+str(player_id+1)
	set_colors()
	write_bash_mode()

func set_colors():
	_playerLbl.modulate = _col
	_scoreLbl.modulate = _col
	$Label.modulate = _col
	update_health(Globals.MAX_HP)
	var sb = StyleBoxFlat.new()
	sb.bg_color = _col
	_bar.add_theme_stylebox_override("fill", sb)
	

func update_score(score:int):
	_scoreLbl.text = str(score).pad_zeros(4)
	var t = create_tween().set_loops(5)
	t.tween_property(_scoreLbl, "modulate", Color.WHITE, 0.2)
	t.tween_property(_scoreLbl, "modulate", _col, 0.2)

	

func update_health(health:int):
	$HealthLabel.set_hp(health, _col)
	

func reset_bar():
	_bar.max_value = Globals.POWERUP_THRESHOLD
	_bar.value = 0 

func update_bar(value):
	_bar.value = value


func play_combo_fx(combo_multiplier:int):
	print("TODO: play_combo_fx for UI")
	
func play_hp_fx():
	print("TODO: play_hp_fx for UI")
	
func play_powerup_mode_fx():
	print("TODO: play_powerup_mode_fx for UI")
