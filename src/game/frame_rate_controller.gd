extends Node


#@onready var player = get_node("Player")
#@onready var vel = player.velocity
var framerate
var idealFramerate = 1500
var minimumFramerate = 750

var minimumDynamicZoomFramerate = 1000
var maximumDynamicZoomFramerate = 1400
var minimumSmoothZoomFramerate = 850

var minZoom = 1
var zoom = 1

var previousFramerate = 0;
var zoomAdaptations = 0;
var enemyAdapatations = 0;

@export var happiness = 0.0

@onready var main = get_parent()
@onready var player = main.get_node("Player")
@onready var viewport = get_viewport()
@onready var camera = main.get_node("Camera2D")
#@onready var camera = main.get_node("Camera2D")

#Maybe I could get the default screen size and then multiply it by the zoom factor 

func update_framerate() -> float:
	previousFramerate = framerate
	framerate = Engine.get_frames_per_second()
	
	if(previousFramerate == null):
		return framerate
	
	if(framerate == previousFramerate):
		return framerate
	
	if(!(previousFramerate < minimumSmoothZoomFramerate && framerate < minimumSmoothZoomFramerate)):
		if(!(previousFramerate > maximumDynamicZoomFramerate && framerate > maximumDynamicZoomFramerate)):
			zoomAdaptations += 1
	#minimumFramerate
	#idealFramerate
	if(!(previousFramerate < minimumFramerate && framerate < minimumFramerate)):
		if(!(previousFramerate > idealFramerate && framerate > idealFramerate)):
			enemyAdapatations += 1

	return framerate

func determineHappiness():
	
	#print(framerate)
	#print((framerate - minimumFramerate) / (idealFramerate - minimumFramerate))
	happiness = clamp((framerate - minimumFramerate) / (idealFramerate - minimumFramerate), 0, 1) 
	return happiness

func calcIdealZoom() -> float:
	
	return .1;
	
func calcInterpolatedZoom(targetZoom : float, delta):
	
	var diff = targetZoom - zoom
	var deltaZoom = diff * delta
	
	return deltaZoom + zoom
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Engine.max_fps = 0
	#print(main.get_viewport_rect().size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	update_framerate()
	determineHappiness()
	#print(zoom)
	match framerate:
		var f when f >= maximumDynamicZoomFramerate:
			
			zoom = calcInterpolatedZoom(calcIdealZoom(), delta)
		var f when f >= minimumDynamicZoomFramerate:
			
			var scalar =  framerate / (maximumDynamicZoomFramerate - minimumDynamicZoomFramerate)
			zoom = calcInterpolatedZoom(calcIdealZoom() * scalar, delta)
		var f when f >= minimumSmoothZoomFramerate:
			zoom = calcInterpolatedZoom(minZoom, delta)
		_:
			zoom = minZoom
	#zoom = .5
	camera.zoom = Vector2.ONE * zoom
	
func getHappiness() -> float:
	return happiness

func getZoom() -> float:
	return zoom

func getZoomAdaptations() -> float:
	return zoomAdaptations

func getEnemyAdaptations() -> float:
	return enemyAdapatations
