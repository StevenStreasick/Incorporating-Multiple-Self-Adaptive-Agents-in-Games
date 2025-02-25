extends Node

class varInfo:
	var val: float
	var range: Vector2
	var minVal: float
	var maxVal: float
	var offset: float
	var useVal: bool
	
var numEnemiesInfo: varInfo = varInfo.new()
var enemySizeInfo: varInfo = varInfo.new()
var enemyVelocityInfo: varInfo = varInfo.new()
var enemySightInfo: varInfo = varInfo.new()

var smoothing = false

var SIGMA = .05
#@export var numEnemies: int
#@export var enemySize : int
#@export var enemyVelocity: int
#@export var enemySight: int

@onready var main = get_parent()
@onready var frameRateController = main.get_node("FrameRateController")
@onready var player = main.get_node("Player")

var happiness: float# = frameRateController.happiness

func updateVal(varInfoContainer: varInfo):
	
	var varToUpdate = varInfoContainer.val
	var minVal = varInfoContainer.minVal
	var maxVal = varInfoContainer.maxVal
	
	var offset = varInfoContainer.offset
	
	if(smoothing): 
		#This seems to be a concave down exponential growth graph. I want a linear graph.
		#Additionally independent of framerate. Is this a good thing?
		varToUpdate = clamp((1.0 - SIGMA) * varToUpdate + SIGMA * pow(happiness, 3) * offset, 
						minVal, 
						maxVal)
		varInfoContainer.val = varToUpdate
		return varToUpdate
		#varToUpdate = clamp(((1.0 - SIGMA) * varToUpdate + SIGMA * pow(happiness, 3)) * offset + minVal, 
						#minVal, 
						#maxVal)
		#varInfoContainer.val = varToUpdate 
		#return varToUpdate

	varToUpdate = clamp(pow(happiness, 3) * offset + minVal, minVal, maxVal) # + minVal
	varInfoContainer.val = varToUpdate
	return varToUpdate
	
func updateRange(varInfoContainer: varInfo): 
	var minVal: float = varInfoContainer.minVal
	var maxVal: float = varInfoContainer.maxVal
	var currentRange: Vector2 = varInfoContainer.range
	var updatedRange: Vector2 = currentRange + currentRange * SIGMA * (happiness - .6)
	
	if updatedRange.x < minVal:
		#print("Too low")
		var scale_factor = (minVal - currentRange.x) / (updatedRange.x - currentRange.x)
		updatedRange.x = minVal
		updatedRange.y = currentRange.y + (updatedRange.y - currentRange.y) * scale_factor
		
	if updatedRange.y > maxVal:
		#print("Too high")
		var scale_factor = (maxVal - currentRange.y) / (updatedRange.y - currentRange.y)
		updatedRange.y = maxVal
		updatedRange.x = currentRange.x + (updatedRange.x - currentRange.x) * scale_factor
	
	updatedRange.x = clamp(updatedRange.x, minVal, maxVal)
	updatedRange.y = clamp(updatedRange.y, minVal, maxVal)
	
	varInfoContainer.range = updatedRange

func updateVar(varInfoContainer: varInfo):
	
	if(varInfoContainer.useVal):
		return updateVal(varInfoContainer)
		
	return updateRange(varInfoContainer)
	
	
func instantiateVarInfo(varInfoContainer: varInfo, minVal: float, maxVal: float, useVal: bool):
	var offset = (maxVal - minVal) * 1.0
	var quarteredOffset = offset / 4
	varInfoContainer.minVal = minVal
	varInfoContainer.maxVal = maxVal
	varInfoContainer.range = Vector2(minVal + quarteredOffset, maxVal - quarteredOffset)
	varInfoContainer.val = minVal
	varInfoContainer.offset = offset
	varInfoContainer.useVal = useVal
	
	return varInfoContainer
	
func updateSmoothingVar():
	#If smoothing is true, I want it to be enabled until happiness goes below .4
	#If smoothing is false, I want it to be disabled until happiness goes above .45

	smoothing = (happiness > 0.45) or (smoothing and happiness > 0.4)
	return smoothing

func updateEnemySizeBounds() -> bool:
	var score = main.get_score()
	var playerSize = player.scale.x
	
	var decayFactor = 1.0 / (pow(score + 1.0, 1/3.0))  # Controls how fast the gap shrinks for lower bound
	var growthFactor = sqrt(score) / (sqrt(score) + 100.0)   # Controls how fast the gap grows for upper bound
	
	var lowerBoundEnemySize = playerSize - (playerSize * decayFactor) / 5.0  # Shrinking gap, smoother progression
	var upperBoundEnemySize = playerSize + (playerSize * growthFactor)  # Growing gap, but gradually

	enemySizeInfo = instantiateVarInfo(enemySizeInfo, lowerBoundEnemySize, upperBoundEnemySize, false)
	#print(Vector2(lowerBoundEnemySize, upperBoundEnemySize))
	return true
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	numEnemiesInfo = instantiateVarInfo(varInfo.new(), 0, 2, true)

	enemySizeInfo = instantiateVarInfo(varInfo.new(), 1, 10, false)
	enemyVelocityInfo = instantiateVarInfo(varInfo.new(), 50, 300, false)
	enemySightInfo	= instantiateVarInfo(varInfo.new(), 1000, 1000, true)
	
func _process(_delta: float) -> void:
	happiness = frameRateController.happiness
	
	#Adjust the lowerbound/upperbound of the enemy size based on performance.
	#Check the framerate. If sufficient, call updateBounds
	if(happiness > .6):
		updateEnemySizeBounds()
		
	
	updateSmoothingVar()
	
#Double check that these values update based on score as well.
	updateVar(numEnemiesInfo)
	updateVar(enemySizeInfo)
	updateVar(enemyVelocityInfo)
	#updateVar(enemySightInfo)
	#print(enemySizeInfo.range)
		
	
func getVarVal(varInfoContainer: varInfo):
	if(varInfoContainer.useVal):
		return varInfoContainer.val
	return varInfoContainer.range
	
func getVarRange(varInfoContainer: varInfo):
	return Vector2(varInfoContainer.minVal, varInfoContainer.maxVal)
	
func getNumEnemies():
	return getVarVal(numEnemiesInfo)
	
func getNumEnemiesRange():
	return getVarRange(numEnemiesInfo)
	
func getEnemySize():
	return getVarVal(enemySizeInfo)
	
func getEnemySizeRange():
	return getVarRange(enemySizeInfo)

func getEnemyVelocity():
	return getVarVal(enemyVelocityInfo)

func getEnemyVelocityRange():
	return getVarRange(enemyVelocityInfo)

func getEnemySight():
	return getVarVal(enemySightInfo)

func getEnemySightRange():
	return getVarRange(enemySightInfo)
	
func getSmoothing():
	return smoothing
