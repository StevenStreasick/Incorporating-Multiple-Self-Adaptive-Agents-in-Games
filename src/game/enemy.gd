extends RigidBody2D
class_name enemy

var rng = RandomNumberGenerator.new()

var TURNSPEED = 15 #degrees/sec

var main;
var player;
var enemyController;
var camera;
var viewportSize;
var velocityRange;
var vel: Vector2 = Vector2.ZERO;

func initialize(mainToSetTo: Node2D) -> bool:
	
	main = mainToSetTo
	player = main.get_node("Player")
	enemyController = main.get_node("EnemyController")
	camera = main.get_node("Camera2D")
	viewportSize = camera.get_viewport_rect().size
	velocityRange = enemyController.getEnemyVelocity()
	
	return true
	
func died() -> bool:
	main.emit_signal("enemyDied")
	return true
	
func _integrate_forces(_bodyState : PhysicsDirectBodyState2D) -> void:
	linear_velocity = vel

func spawn() -> bool:
	return true
