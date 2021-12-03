extends Control

onready var hScroll: = $HScrollBar
onready var vScroll: = $VScrollBar
onready var board: = $Board

var unitDictionary:Dictionary
var unitList:Array
var isDragged: = false

func _ready()->void:
# warning-ignore:return_value_discarded
	hScroll.connect("scrolling", self, "HScrolling")
# warning-ignore:return_value_discarded
	vScroll.connect("scrolling", self, "VScrolling")
	UpdateScrollBars()

func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton:
		if event.button_index == 3:
			if event.pressed && !isDragged:
				isDragged = true
			if !event.pressed && isDragged:
				isDragged = false
	elif event is InputEventMouseMotion && isDragged:
		hScroll.value -= event.relative.x
		vScroll.value -= event.relative.y
		HScrolling()
		VScrolling()

func UpdateScrollBars()->void:
	#yield(get_tree(), "idle_frame")
	hScroll.max_value = board.rect_size.x
	hScroll.value = -board.rect_position.x
	hScroll.page = rect_size.x
	vScroll.max_value = board.rect_size.y
	vScroll.value = -board.rect_position.y
	vScroll.page = rect_size.y

func HScrolling()->void:
	board.rect_position.x = -hScroll.value

func VScrolling()->void:
	board.rect_position.y = -vScroll.value

func AddUnit(unit:Node)->void:
	unitDictionary[unit.name] = unit
	unitList.append(unit)

func RemoveUnit(unit:Node)->void:
# warning-ignore:return_value_discarded
	unitDictionary.erase(unit.name)
	unitList.clear()
	for k in unitDictionary.keys():
		unitList.append(unitDictionary[k])

func MoveUnits(offset:Vector2)->void:
	for unit in unitList:
		unit.rect_position += offset

func UnitChanged(pos:Vector2, size:Vector2)->void:
	if pos.x + size.x > board.rect_size.x:
		board.rect_size.x = pos.x + size.x
	
	if pos.y + size.y > board.rect_size.y:
		board.rect_size.y = pos.y + size.y
	
	if pos.x < 0.0:
		board.rect_size.x += -pos.x
		MoveUnits(Vector2(-pos.x, 0.0))
	
	if pos.y < 0.0:
		board.rect_size.y += -pos.y
		MoveUnits(Vector2(0.0, -pos.y))
	
	
	UpdateScrollBars()
