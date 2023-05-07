extends Node2D

@export var adsr:ADSREnvelope
@export var sprite:Sprite2D
@export var targetPoint:Node2D
@export var stateLabel:Label
@export var valueLabel:Label

var startPoint:Vector2
func _ready():
	startPoint = sprite.position

func _process(_delta):
	valueLabel.text = str(adsr.VALUE)
	if(Input.is_action_pressed("start_move")):
		adsr.hold()
		if(adsr.is_done):
			adsr.trigger()

	if(Input.is_action_just_released("start_move") and !adsr.is_done):
		adsr.drop()

	if(adsr.current_phase == ADSREnvelope.PHASE.SUSTAIN):
		sprite.rotate(0.1)

	sprite.position = lerp(startPoint, targetPoint.position, adsr.VALUE)

func debug(state):
	stateLabel.text = str("State: ",state) 

func _on_adsr_envelope_sustain_started():
	debug("Sustain")

func _on_adsr_envelope_release_started():
	debug("Release")

func _on_adsr_envelope_finished():
	debug("Done")

func _on_adsr_envelope_delay_started():
	debug("Delay")

func _on_adsr_envelope_decay_started():
	debug("Decay")

func _on_adsr_envelope_attack_started():
	debug("Attack")
