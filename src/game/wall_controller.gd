extends Node

@onready var main = get_parent()
@onready var camera = main.get_node("Camera2D")

@onready var viewportSize = camera.get_viewport_rect().size 
@onready var spawnRange = viewportSize * 5#Not really sure why this is 5 instead of 10 to accomodate zoom

var rng = RandomNumberGenerator.new()

var barrier = preload("res://Barrier.tscn")
var spike = preload("res://spike_wall.tscn")

var spikeCount = 8
var barrierCount = 15

var spikes = []
var barriers = []


#camera.get_viewport_rect().size
func generatePosition() -> Vector2:
	var signVector = Vector2(
		randi_range(0, 1) * 2 - 1, 
		randi_range(0, 1) * 2 - 1)
		
	var position = signVector * Vector2(
		rng.randf_range(450, spawnRange.x), 
		rng.randf_range(450, spawnRange.y))
			
	return position
	
func spawnBarriers() -> bool:	
		
	for i in range(barrierCount):
		
		var position = generatePosition()
			
		var b = barrier.instantiate()
		
		b.position = position
		main.add_child.call_deferred(b)
		
		barriers.append(b)
	
	return true
	
func spawnSpikes() -> bool:
	for i in range(spikeCount):
		
		var position = generatePosition()
		
		var s = spike.instantiate()
		
		s.position = position
		main.add_child.call_deferred(s)
		
		spikes.append(s)
		
	return true
	
func spawnEntities() -> bool:
	return spawnBarriers() && spawnSpikes()
		
func removeBarriers() -> bool:
	for v in barriers:
		v.queue_free()
		
	barriers.clear()
	
	return true
		
func removeSpikes() -> bool:
	for v in spikes:
		v.queue_free()
		
	spikes.clear()
	
	return true

func cleanupEntities() -> bool:
	return removeBarriers() && removeSpikes()
