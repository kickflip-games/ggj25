class_name PlayerUi
extends VBoxContainer


@onready var _bar = $PowerupBar
@onready var _scoreLbl = $PanelContainer/ScoreLabel
@onready var _hpLbl = $HealthLabel
@onready var _playerLbl = $PanelContainer/PlayerLabel


const HEART_CHAR = '\u2665'
const EMPTY_HEART_CHAR = '\u2661'

var _col:Color





func reset(player_id:int):
	_col = Globals.PLAYER_COLORS[player_id]
	update_score(0)
	update_health(Globals.MAX_HP)
	reset_bar()
	_playerLbl.text = "P"+str(player_id+1)
	set_colors()
	

func set_colors():
	_playerLbl.add_theme_color_override("font_color", _col)
	_scoreLbl.add_theme_color_override("font_color", _col)
	$Label.add_theme_color_override("font_color", _col)
	update_health(Globals.MAX_HP)
	var sb = StyleBoxFlat.new()
	sb.bg_color = _col
	_bar.add_theme_stylebox_override("fill", sb)
	

func update_score(score:int):
	_scoreLbl.text = str(score).pad_zeros(4)

func update_health(health:int):
	var hearts_display = HEART_CHAR.repeat(health) + EMPTY_HEART_CHAR.repeat(Globals.MAX_HP - health)
	var str = "[center][color=%s]%s[/color][/center]" % [_col.to_html(), hearts_display]
	_hpLbl.bbcode_text = str
	play_hp_fx()


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
