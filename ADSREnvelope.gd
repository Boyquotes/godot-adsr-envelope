# General purpose ADSR envelope for Godot.  
# Made by ussaohelcim.
# License: Public Domain 

#TODO implement DAHDSR, delay, attack, hold, decay, sustain, release
#TODO find a way to add description on inspecto

#TODO Reimplement from scratch using gdnative/gdextension, maybe try to make a pull request to Godot?

class_name ADSREnvelope
extends Node

signal delay_started()
# signal holdStarted()
signal attack_started()
signal decay_started()
signal release_started()
signal sustain_started()
signal finished()

enum PHASE{
	DELAY, 
	ATTACK, 
	DECAY, 
	SUSTAIN, 
	RELEASE, 
	DONE,
}

@export_category("Delay")
@export var delay_time : float = 0.0

@export_category("Attack")
@export var attack_time : float = 1.0
@export var attack_ease_type : Tween.TransitionType
@export_range(0,1.0) var attack_max_value : float = 1.0

@export_category("Decay")
@export var decay_time : float = 1.0
@export var decay_ease_type : Tween.TransitionType

@export_category("Sustain")
@export_range(0,1.0) var sustain_level : float = 1.0

@export_category("Release")
@export var release_time : float = 1.0
@export var release_ease_type : Tween.TransitionType

## The current value of this adsr envelope.
var VALUE := 0.0
## Is this adsr donw? (Did something called adsr.hold() before?) (GETTER only)
var is_down := false
## Is this adsr trigged now? (GETTER only)
var is_trigged := false
## Is this adsr done? (GETTER only)
var is_done := true

## The current phase of this adsr envelope.
var current_phase: PHASE

var _attackTween: Tween
var _decayTween: Tween
var _releaseTween: Tween
var _delayTween: Tween

func _ready():
	_attackTween = create_tween().set_loops()
	_attackTween.tween_property(self, "VALUE", attack_max_value, attack_time).set_trans(self.attack_ease_type)
	_attackTween.tween_callback(self._start_decay)
	_attackTween.tween_callback(_attackTween.stop)
	_attackTween.stop()

	_delayTween = get_tree().create_tween().bind_node(self).set_loops()
	_delayTween.tween_property(self, "VALUE", 0, delay_time)#.set_trans(self.decay_ease_type)
	_delayTween.tween_callback(self._start_attack)
	_delayTween.tween_callback(_delayTween.stop)
	_delayTween.stop()

	_decayTween = get_tree().create_tween().bind_node(self).set_loops()
	_decayTween.tween_property(self, "VALUE", sustain_level, decay_time).set_trans(self.decay_ease_type)
	_decayTween.tween_callback(self._startRelease)
	_decayTween.tween_callback(_decayTween.stop)
	_decayTween.stop()

	_releaseTween = get_tree().create_tween().bind_node(self).set_loops()
	_releaseTween.tween_property(self, "VALUE", 0, release_time).set_trans(self.release_ease_type)
	_releaseTween.tween_callback(self._done)
	_releaseTween.tween_callback(_releaseTween.stop)
	_releaseTween.stop()


## Starts this adsr evelope.
func trigger():
	self.VALUE = 0
	self.is_trigged = true
	self.is_done = false
	_start_delay()


## Tells this adsr evelope to stop the sustain phase and start the release phase.
func drop():
	self.is_down = false
	if(current_phase == PHASE.SUSTAIN):
		_startRelease()


## Tells this adsr evelope to hold `adsr.VALUE` when on sustain phase.
func hold():
	self.is_down = true


## Stop all tweens. `adsr.VALUE` will be 0.0. 
func force_stop():
	_delayTween.stop()
	_attackTween.stop()
	_decayTween.stop()
	_releaseTween.stop()
	_delayTween.stop()
	self.VALUE = 0
	_done()


func _start_delay():
	current_phase = PHASE.DELAY

	delay_started.emit()
	_delayTween.play()


func _start_attack():
	current_phase = PHASE.ATTACK

	_attackTween.play()
	attack_started.emit()


func _start_decay():
	current_phase = PHASE.DECAY
	
	if decay_time == 0:
		self.VALUE = attack_max_value
	_decayTween.play()
	decay_started.emit()


func _startRelease():
	if(self.is_down):
		current_phase = PHASE.SUSTAIN

		self.VALUE = sustain_level
		sustain_started.emit()
	else:
		current_phase = PHASE.RELEASE

		_releaseTween.play()
		release_started.emit()


func _done():
	current_phase = PHASE.DONE
	self.is_trigged = false
	self.is_done = true

	finished.emit()
