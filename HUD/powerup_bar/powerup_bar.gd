extends TextureProgressBar


var charge = 0
var max_charge = 10

signal powerup_charged

func increase_charge(amount:int):
	charge += amount
	if charge >= max_charge:
		powerup_charged.emit()
		charge = 0  # Reset charge after triggering powerup

func reset_bar():
	charge = 0
