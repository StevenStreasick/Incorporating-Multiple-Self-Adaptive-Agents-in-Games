extends Node

@onready var main = get_parent()
@onready var camera = main.get_node("Camera2D")

@onready var viewportSize = camera.get_viewport_rect().size
@onready var spawnRange = viewportSize * 5#Not really sure why this is 5 instead of 10 to accomodate zoom

var rng = RandomNumberGenerator.new()

var sourcePowerups = [
	preload("res://wallPowerup.tscn"),
	preload("res://invincibilityPowerup.tscn")
]

var powerupEntities = []
var gameActive = false
var spawnrate: float = 5.0 / 60 #powerups per second

func generatePosition() -> Vector2:
	var signVector = Vector2(
		randi_range(0, 1) * 2 - 1, 
		randi_range(0, 1) * 2 - 1)
		
	var position = signVector * Vector2(
		rng.randf_range(450, spawnRange.x), 
		rng.randf_range(450, spawnRange.y))
			
	return position

func spawnPowerup() -> bool:
	var powerup = sourcePowerups[rng.randi_range(0, sourcePowerups.size() - 1)].instantiate()
	
	var position = generatePosition()
	powerup.position = position

	powerupEntities.append(powerup)
	
	main.add_child.call_deferred(powerup)

	return true
	
func beginSpawningEntities() -> bool:
	gameActive = true
	
	return true

func cleanupEntities() -> bool:
	gameActive = false
	
	for v in powerupEntities:
		if !v:
			pass
		else:
			v.queue_free()
		
	powerupEntities.clear()
	
	return true

func _process(delta: float) -> void:
	if !gameActive: 
		return
	
	if rng.randf() <= delta * spawnrate:
		spawnPowerup()
