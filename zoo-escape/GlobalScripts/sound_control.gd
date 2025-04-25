extends Node2D


@onready var bgm = $BGM ## music (pauses position on pause)
@onready var sfx = $SFX ## in-game sound effects (pauses position on pause)
@onready var cue = $Cue ## ui sound effects (ignores pause)


## export for testing purposes, const to set boundaries and ease debugging
const DEFAULT_VOLUME = -24
const SILENCE = -80
const _defaultBgm = "res://Assets/Sound/theme.ogg"
const _testBgm = "res://Assets/Sound/tutorial.ogg"
var _currentBgm : String

## references to global volume levels (we can have options for this to adjust)
var _volumeReference : float = DEFAULT_VOLUME ## monitored by players and updates
@export var bgmLevel : int = DEFAULT_VOLUME
@export var sfxLevel : int = DEFAULT_VOLUME
@export var cueLevel : int = DEFAULT_VOLUME
@export var fadeRate : float = 0.2 ## default fade rate, can be updated in code
var max_volume = -24 ## reference for maximum

## fade state machine for audio fading
var fadeState : int = 1
enum FADE_STATES {
	SILENCE, ## no audio
	IN_TRIGGER, ## audio starts increase (one-shot)
	IN_CURVE, ## audio fading in
	PEAK_VOLUME, ## audio continuous (idle)
	OUT_TRIGGER, ## audio starts decrease (one-shot)
	OUT_CURVE} ## audio fades out


## global audio references for easy access
const _alert = "res://Assets/Sound/alert.ogg"
const _blip = "res://Assets/Sound/blip.ogg"
const _chomp = "res://Assets/Sound/chompy.ogg"
const _down = "res://Assets/Sound/flourish_down.ogg"
const _pickup = "res://Assets/Sound/pickup.ogg"
const _flutter = "res://Assets/Sound/flutter.ogg"
const _fail = "res://Assets/Sound/game_over.ogg"
const _ruined = "res://Assets/Sound/crumble_noise.ogg"
const _scratch = "res://Assets/Sound/scratch_delay.ogg"
const _scuff = "res://Assets/Sound/scuff_noise.ogg"
const _splorch = "res://Assets/Sound/splorch.ogg"
const _success = "res://Assets/Sound/success.ogg"
const _thump = "res://Assets/Sound/thump.ogg"
const _zap = "res://Assets/Sound/zap_delayed.ogg"

const _start = "res://Assets/Sound/flourish_up.ogg"




func _ready() -> void: ## sound preferences retrieved at ready
	_setSoundPreferences(SILENCE,sfxLevel,cueLevel) ## set levels
	## TODO: make options screen for user-determined levels
	_currentBgm = _testBgm ## default title music


func _process(delta: float) -> void: ## listen for fade states and update volumes
	_bgmFadingMachine(delta,fadeRate)


## values set for sound levels
func _setSoundPreferences(_bgm:int, _sfx:int, _cue:int):
	$BGM.volume_db = _bgm ## default to silence for fade in
	$SFX.volume_db = _sfx
	$Cue.volume_db = _cue


## call bgm file and play (state machine handles stop and start automatically)
func _playBgm():
	var _loadBgm = load(_currentBgm)
	bgm.volume_db = bgmLevel
	bgm.stream = _loadBgm
	bgm.play()


## to update fade value
func _fadeRateUpdate(_newValue:float):
	fadeRate = _newValue


## queue next track and update fade if needed
func _levelChangeSoundCall(_value:float, _music:String):
	_currentBgm = _music ## allows music to change on next fade start
	fadeState = FADE_STATES.OUT_TRIGGER
	_fadeRateUpdate(_value)


# hard stop function
func _stopSounds():
	bgm.stop()
	sfx.stop()


## call sfx file and play
func _playSfx(_sfxFile:String):
	randomize() ## queue rng
	var _variant = randf_range(-0.3,0.3) ## change pitch each time
	var _loadSfx = load(_sfxFile)
	sfx.stream = _loadSfx
	sfx.pitch_scale = 1+_variant
	sfx.play()


## call system noises and play (note: system noises do not pause)
func _playCue(_cueFile:String,_pitch:float):
	cue.pitch_scale = _pitch
	var _loadCue = load(_cueFile)
	cue.stream = _loadCue
	cue.play()


## fade volume state machine for music
func _bgmFadingMachine(_delta:float,_rate:float):
	bgm.volume_db = _volumeReference ## volume reflects abstraction value
	
	match fadeState:
		FADE_STATES.IN_TRIGGER:
			fadeRate = 0.25 ## default rate
			_playBgm() ## start play
			fadeState+=1 ## move to next
		FADE_STATES.IN_CURVE:
			if _volumeReference < max_volume: ## increase volume while below target
				_volumeReference+=(_delta+_rate)
			else: ## then update state
				fadeState+=1
		FADE_STATES.PEAK_VOLUME: # hold volume steady when not fading
			_volumeReference = max_volume
		FADE_STATES.OUT_TRIGGER: # start volume decrease (one-shot)
			if _volumeReference >= max_volume:
				_volumeReference-=(_delta+_rate)
				fadeState+=1
		FADE_STATES.OUT_CURVE: ## if not silence, reduce rate
			if _volumeReference > SILENCE:
				_volumeReference-=(_delta+_rate*2)
			else: ## then set to silence
				fadeState = 0
		FADE_STATES.SILENCE: ## silence immediately begins next fade in
			_volumeReference = SILENCE
			fadeState+=1
