extends MarginContainer


func updateScore(score) -> void:
	$HBoxContainer/Score.text = str(snapped(score, 1))
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
