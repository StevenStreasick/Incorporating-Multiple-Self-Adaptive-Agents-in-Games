extends Node2D

signal gameStarted 
signal gameEnded
signal enemyDied;


var barrier = preload("res://Barrier.tscn")
var spikewall = preload("res://spike_wall.tscn")
var invincibility = preload("res://invincibilityPowerup.tscn")
var wall_consumption = preload("res://wallPowerup.tscn")

@onready var frame_rate_controller = get_node("FrameRateController")
@onready var enemy_controller = get_node("EnemyController")

var enemies = [
	preload("res://horizontal_enemy.tscn"),
	preload("res://vertical_enemy.tscn")
]

var numberOfEnemies = 0

@onready var start_button = $CanvasLayer/CenterContainer/Start
@onready var game_over = $CanvasLayer/CenterContainer/GameOver

var rng = RandomNumberGenerator.new()
var DEFAULTSPRITESIZE = 64
var isGameActive = false
var score: float = 0
var time: float = 0

var fileNumber = 0
#NOTE: You must press the X on the window instead of stopping the game so that the file will properly close.
var file

func startGame() -> void:
	gameStarted.emit()
	isGameActive = true
	score = 0
	
	$Player.show()
	$Player.start()
	start_button.hide()
	game_over.hide()
	$CanvasLayer/UI.show()
	$CanvasLayer/UI.updateScore(score)

func endGame() -> void:
	gameEnded.emit()
	isGameActive = false
	$Player.hide()
	get_tree().call_group("Enemies", "queue_free")
	game_over.show()	
	await get_tree().create_timer(2).timeout
	game_over.hide()
	start_button.show()
	
func getEnemyScaleFromRange(enemySizeRange: Vector2) -> Vector2:
	
	return Vector2.ONE * rng.randf_range(enemySizeRange.x, enemySizeRange.y)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Player.hide()
	start_button.show()
	game_over.hide()
	$CanvasLayer/UI.hide()
	#var b = barrier.instantiate()
	#var s = spikewall.instantiate()
	#var i = invincibility.instantiate()
	#var w = wall_consumption.instantiate()
	#b.position = Vector2(250, 250)
	#s.position = Vector2(-250, 250)
	#i.position = Vector2(-250, -250)
	#w.position = Vector2(250, -250)
	#add_child(b)
	#add_child(s)
	#add_child(i)
	#add_child(w)
	
func getFileToWriteTo():
	var filePath: String = OS.get_user_data_dir() + "/sas_data/"
	var error = DirAccess.make_dir_absolute(filePath)
	if error != null:
		print(error)
	
	var d = DirAccess.open(filePath)
	while(true):
		if(!d.file_exists("Run " + str(fileNumber) + ".txt")):
			break
			
		fileNumber += 1

	file = FileAccess.open(filePath + "Run " + str(fileNumber) + ".txt", FileAccess.WRITE)

func convertVec2ToString(vec2: Vector2) -> String:
	
	return ("(%.3f %.3f)" % [vec2.x, vec2.y])

func writeToFile(currentTime) -> void:
	#TODO: Write the current number of Enemies that are in the game.
	if file == null:
		getFileToWriteTo()
	
	var framerate = Engine.get_frames_per_second()
	var happiness = frame_rate_controller.getHappiness()
	var zoom = frame_rate_controller.getZoom()
	
	var smoothing = enemy_controller.getSmoothing()
	
	var playerSize = $Player.scale.x

	var numEnemies = enemy_controller.getNumEnemies()
	var numEnemiesRange = enemy_controller.getNumEnemiesRange()
	var enemySize = enemy_controller.getEnemySize()
	var enemySizeRange = enemy_controller.getEnemySizeRange()
	var enemyVelocity = enemy_controller.getEnemyVelocity()
	var enemyVelocityRange = enemy_controller.getEnemyVelocityRange()
	var enemySight = enemy_controller.getEnemySight()
	var enemySightRange = enemy_controller.getEnemySightRange()
	
	var zoomAdaptations = frame_rate_controller.getZoomAdaptations()
	var enemyAdaptations = frame_rate_controller.getEnemyAdaptations()
	
	var concatString = str("%2.3f" % currentTime) + "," + str("%2.3f" % framerate) + "," \
	+ str("%2.3f" % happiness)  + "," + str("%2.3f" % zoom)  + "," + str(smoothing) + "," \
	+ str("%2.3f" % numEnemies) + "," + convertVec2ToString(numEnemiesRange) + "," \
	+ convertVec2ToString(enemySize) + "," + convertVec2ToString(enemySizeRange) + "," \
	+ convertVec2ToString(enemyVelocity) + "," + convertVec2ToString(enemyVelocityRange) + "," \
	+ str("%2.3f" % enemySight) + "," + convertVec2ToString(enemySightRange) + "," \
	+ str("%2.3f" % score) + "," + str("%2.3f" % playerSize) + "," + str("%d" % numberOfEnemies) \
	+ "," + str("%2d" % zoomAdaptations) + "," + str("%2d" % enemyAdaptations) + "\n"
	
	file.store_string(concatString)
	#NOTE: # enemies and enemySight are fixed variables

func spawnEnemy() -> PhysicsBody2D:
	numberOfEnemies += 1
	var length = enemies.size()
	var enemyIndex = rng.randi_range(0, length - 1) #randi_range is fully inclusive
	var setscale = getEnemyScaleFromRange(enemy_controller.getEnemySize())

	
	var e = enemies[enemyIndex].instantiate()
	e.get_node("CollisionShape2D").scale = setscale#
	e.get_node("Sprite2D").scale = setscale
	#TODO: Figure out why the enemy is not scaling with getEnemySize	
	e.initialize(self)
	e.spawn()
	add_child(e)
	
	return e

func decEnemies() -> void:
	numberOfEnemies -= 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var spawnrate = enemy_controller.getNumEnemies()
	if !isGameActive:
		return

	if (time < 45):
		if (time > 15):
			
			writeToFile(time)
		time += delta
	else:
		print("Times up")	
		
	if rng.randf() < spawnrate * delta:
		spawnEnemy()
		
func _on_player_ate_enemy(area : PhysicsBody2D) -> void:
	score += area.scale.length() * DEFAULTSPRITESIZE 
	$CanvasLayer/UI.updateScore(score)
	
func get_score() -> float:
	return score
