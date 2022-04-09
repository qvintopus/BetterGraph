extends PanelContainer
class_name GraphUnit

signal UnitChanged
signal InputPressed
signal OutputPressed
signal Disconnect
signal ConnectionsRemoved
signal DrawConnections

const EMPTY_DATA:Dictionary = {
	unitOut = null,
	output = null,
	unitIn = null,
	input = null
}


export var inputCount:int setget SetInputs
export var outputCount:int setget SetOutputs
export var inputParentPath:NodePath
export var outputParentPath:NodePath
export var connectorScene:PackedScene = preload("res://addons/BetterGraph/UnitConnector/Connector.tscn")
export var unitBellyPath:NodePath
export var handleGUIinBase:bool = true

onready var inputParent: = get_node(inputParentPath)
onready var outputParent: = get_node(outputParentPath)
onready var parent:Node = get_parent()
onready var UnitName:Node = $VBoxContainer/Top/Label
###---Belly stuff---###
onready var unitBelly: = get_node(unitBellyPath)
onready var UnitStylePanel:Node = $Panel



var isSelected: = false
var inputs:Array = []
var outputs:Array = []
var connectionsIn:Dictionary = {}	#data list array by output key
var connectionsOut:Dictionary = {}	#data list array by output key
var UnitBoardEditor = null

func SetInputs(value:int)->void:
	if value < 0:
		return
	if !is_inside_tree():
		inputCount = value
		return
	if inputCount < value:
		for i in (value - inputCount):
			var inst:Button = connectorScene.instance()
			inputParent.add_child(inst)
# warning-ignore:return_value_discarded
			inst.connect("pressed", self, "InputPressed", [inst, inputs.size()])
# warning-ignore:return_value_discarded
			inst.connect("Disconnect", self, "InputDisconnected", [inputs.size()])
# warning-ignore:return_value_discarded
			inst.connect("tree_exited", self, "InputRemoved", [inputs.size()])
			inputs.append(inst)
			inst.modulate = Color(randf(), randf(), randf())	############# TEST
	elif inputCount > value:
		for i in (inputCount - value):
			inputs.pop_back().queue_free()
	inputCount = value

func SetOutputs(value:int)->void:
	if value < 0:
		return
	if !is_inside_tree():
		outputCount = value
		return
	if outputCount < value:
		for i in (value - outputCount):
			var inst:Button = connectorScene.instance()
			outputParent.add_child(inst)
# warning-ignore:return_value_discarded
			inst.connect("pressed", self, "OutputPressed", [inst, outputs.size()])
# warning-ignore:return_value_discarded
			inst.connect("Disconnect", self, "OutputDisconnected", [outputs.size()])
# warning-ignore:return_value_discarded
			inst.connect("tree_exited", self, "OutputRemoved", [outputs.size()])
			outputs.append(inst)
			inst.modulate = Color(randf(), randf(), randf())	############# TEST
	elif outputCount > value:
		for i in (outputCount - value):
			outputs.pop_back().queue_free()
			# TO-DO: check if connections exists
	outputCount = value

func _ready()->void:
	var inC = inputCount
	var outC = outputCount
	inputCount = 0
	outputCount = 0
	SetInputs(inC)
	SetOutputs(outC)
#	UnitBoardEditor = self.get_parent().get_parent()
	

func _gui_input(event:InputEvent)->void:
	if handleGUIinBase:
		if event is InputEventMouseButton:
			if event.button_index == 1:
				if event.pressed && !isSelected:
					isSelected = true
					parent.move_child(self, parent.get_child_count() -1)
				if !event.pressed && isSelected:
					isSelected = false
		elif event is InputEventMouseMotion && isSelected:
			rect_position += event.relative
			emit_signal("UnitChanged", self, rect_position, rect_size)


func InputPressed(_connector:Button, index:int)->void:
	emit_signal("InputPressed", self, index)

func OutputPressed(_connector:Button, index:int)->void:
	emit_signal("OutputPressed", self, index)

func InputDisconnected(index:int)->void:
	if !connectionsIn.has(index):
		return
	if connectionsIn[index].empty():
		return
	var data:Dictionary = connectionsIn[index].back()
	var list:Array = data.unitIn.connectionsIn[data.input]
	for i in list.size():
		if list[i] == data:
			data.unitOut.connectionsOut[data.output].remove(i)
			connectionsIn[index].erase(data)
			emit_signal("Disconnect", data)
			break

func OutputDisconnected(index:int)->void:
	if !connectionsOut.has(index):
		return
	if connectionsOut[index].empty():
		return
	var data:Dictionary = connectionsOut[index].back()
	var list:Array = data.unitOut.connectionsOut[data.output]
#	var list:Array = data.unitIn.connectionsIn[data.input]
	for i in list.size():
		if list[i] == data:
			data.unitIn.connectionsIn[data.input].remove(i)
			connectionsOut[index].erase(data)
			emit_signal("Disconnect", data)
			break


func InputRemoved(index:int)->void:
	if !connectionsIn.has(index):
		return
	if connectionsIn[index].empty():
		return
	var list:Array = connectionsIn[index]
	for data in list:
		var listOut:Array = data.unitOut.connectionsOut[data.output]
		for i in listOut.size():
			if listOut[i] == data:
				listOut.remove(i)
				break
	emit_signal("ConnectionsRemoved", list)

func OutputRemoved(index:int)->void:
	if !connectionsOut.has(index):
		return
	if connectionsOut[index].empty():
		return
	var list:Array = connectionsOut[index]
	for data in list:
		var listIn:Array = data.unitIn.connectionsIn[data.input]
		for i in listIn.size():
			if listIn[i] == data:
				listIn.remove(i)
				break
#		data.unitIn.InputDisconnected(data.input)
#		data.unitOut.OutputDisconnected(data.output)
	emit_signal("ConnectionsRemoved", list)

func ConnectionTo(unit:GraphUnit, _disconnect:bool = false)->Dictionary:
	var result = EMPTY_DATA
	if connectionsOut.size() > 0:
		for conn in connectionsOut:
			for i in connectionsOut[conn].size():
				if unit == connectionsOut[conn][i]["unitIn"]:
					result = connectionsOut[conn][i]
					if _disconnect:
						result = connectionsOut[conn].pop_at(i)
						result.unitIn.ConnectionTo(result.unitOut, true)
					return result
	if connectionsIn.size() > 0:
		for conn in connectionsIn:
			for i in connectionsIn[conn].size():
				if unit == connectionsIn[conn][i]["unitOut"]:
					result = connectionsIn[conn][i]
					if _disconnect:
						result = connectionsIn[conn].pop_at(i)
						result.unitOut.ConnectionTo(result.unitIn, true)
					return result
	return result

#Check if connection already is existing
func ConnectionExists(data:Dictionary)->bool:
	if !connectionsOut.has(str(data.output)):
		return false
	else:
		for entry in connectionsOut[str(data.output)]:
			if entry.unitIn == data.unitIn && entry.input && data.input:
				return true
	return false

func ConnectedIn(data:Dictionary)->void:
	var entry:int = data.input
	if !connectionsIn.has(entry):
		connectionsIn[entry] = []
	connectionsIn[entry].append(data)

func ConnectedOut(data:Dictionary)->void:
	var entry:int = data.output
	if !connectionsOut.has(entry):
		connectionsOut[entry] = []
	connectionsOut[entry].append(data)
	data.unitIn.ConnectedIn(data)

func ClearConnected()->void:
	for i in connectionsIn.size():
		InputRemoved(i)
	for i in connectionsOut.size():
		OutputRemoved(i)
	connectionsOut.clear()
	connectionsIn.clear()

func RemoveSelf()->void:
# warning-ignore:unassigned_variable
	var connections:Array
	#Inputs
	for index in inputCount:
		if !connectionsIn.has(index):
			continue
		if connectionsIn[index].empty():
			continue
		var list:Array = connectionsIn[index]
		connections.append_array(list.duplicate())
		for data in list:
			var listOut:Array = data.unitOut.connectionsOut[data.output]
			for i in listOut.size():
				if listOut[i] == data:
					listOut.remove(i)
					break
	#Outputs
	for index in outputCount:
		if !connectionsOut.has(index):
			continue
		if connectionsOut[index].empty():
			continue
		var list:Array = connectionsOut[index]
		connections.append_array(list.duplicate())
		for data in list:
			var listIn:Array = data.unitIn.connectionsIn[data.input]
			for i in listIn.size():
				if listIn[i] == data:
					listIn.remove(i)
					break
	emit_signal("ConnectionsRemoved", connections)
	queue_free()

# Chance to check if connection is valid
func ConnectionValidation(data:Dictionary)->bool:
	return !ConnectionExists(data)

# Adding place where Unit exists, probs should be done in ready
func SetBoard(_board)->void:
	UnitBoardEditor = _board
	UnitName.text = str("Unit #", UnitBoardEditor.unitList.size() + 1)

# Bless the Unit for it to proceed w/ it's inherited duties
func Bless()->void:
	pass
