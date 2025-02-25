extends enemy

var rightSide = rng.randi_range(0, 1)
var sideSign = (1 - rightSide) * 2 - 1

func spawn() -> bool:
	var screensize = viewportSize / camera.zoom
	var x = -sideSign * screensize.x / 2
	var yHalved = screensize.y / 2
	var y = rng.randf_range(-yHalved, yHalved) 
	
	position = Vector2(x, y)
	
	vel = Vector2(randf_range(velocityRange.x, velocityRange.y) * sideSign, 0)

	return true;

func get_velocity_for_targeting_player(delta: float, playerPos: Vector2) -> Vector2:
	# Calculate direction vector to the player
	var dx = playerPos.x - position.x
	var dy = playerPos.y - position.y

	var enemyAngle = linear_velocity.angle()
	
	# Calculate the angle to the player
	var targetAngle = atan2(dy, dx) * (180 / PI)  # Convert to degrees

	# Calculate the angle difference and clamp it to the turn speed
	var angleDifference = targetAngle - enemyAngle
	angleDifference = (fmod(angleDifference + 180, 360) - 180)  # Normalize to range -180 to 180

	# Limit the turn based on turn speed and deltaT
	var maxTurn = TURNSPEED * delta
	if abs(angleDifference) > maxTurn:
		angleDifference = abs(maxTurn) * sign(angleDifference)
	
	# Update the current angle
	var newAngle = enemyAngle + angleDifference

	# Calculate the velocity components based on the adjusted angle
	var rads = newAngle * (PI / 180.0)
	var velocityX = cos(rads) * linear_velocity.x
	var velocityY = sin(rads) * linear_velocity.y

	return Vector2(velocityX, velocityY)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("Running")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var playerPos = player.position
	var distanceToPlayer = position.distance_to(playerPos)
	var sight = enemyController.getEnemySight()
	
	if distanceToPlayer < sight:
		pass
	
		#velocity = get_velocity_for_targeting_player(delta, playerPos) 
		#print(velocity.normalized().y)

	#position += delta * velocity
	
	var screensize = viewportSize / camera.zoom
	var border = screensize / 2
	#TODO: Handle enemy size. 
	if(position.x < -border.x && sign(vel.x) == -1):
		died()
		
		queue_free()
	
	if(position.x > border.x && sign(vel.x) == 1):
		died()

		queue_free()
	#if(sign(position.x - border.x) == sign(velocity.x) && sign(position.x + border.x) == sign(velocity.x)):	
		#queue_free()
		#Destroy the entity
	if(sign(position.y - border.y) == sign(vel.y) && sign(vel.y + border.y) == sign(linear_velocity.y)):
		queue_free()
		#Destroy the entity
