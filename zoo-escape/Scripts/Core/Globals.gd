extends Node

# Global constant that tells the game the sizes of our tiles
const TILESIZE := 32

# Global constants for Min/Max Volumes and Min/Max Deadzone
const MAXVOLUME := 0
const MINVOLUME := -20
const MAXDEADZONE := 1.0
const MINDEADZONE := 0.2

# Globally accessible list of passwords and corresponding scenes
const PASSWORDS := {
	# Debug Levels
	"9990": Scenes.TITLE,
	"9991": Scenes.DEBUG,
	"9992": Scenes.DEBUG2,
	"9993": Scenes.DEBUG3,
	
	# Real Levels
	"0001": Scenes.TUTORIAL1,
	
	"0387": Scenes.LEVEL1,
	"9102": Scenes.LEVEL2,
	"1476": Scenes.LEVEL3,
	"4111": Scenes.LEVEL4,
	"5829": Scenes.ICEANDBOX,
	# "0053": 
	
	# "7618": 
	# "2940": 
	# "8365": 
	# "0721": 
	# "6594": 
	
	# "3082": 
	# "9817": 
	# "4250":
	# "1639": 
	# "7048": 
	
	# "2561": 
	 "8934": Scenes.ICELABYRINTH
	# "0195": 
	# "5473": 
	# "3706": 
}

# Globally accessible storage locker for the user's settings
# NOTE: These double as default settings values for Data.gd
var currentSettings := {
	"masterVolume": -6,
	"musicVolume": -6,
	"sfxVolume": -6,
	"cueVolume": -6,
	"analogDeadzone": 0.50,
}

# Globally accessible data related to the currently active game
var currentGameData := {
	"gameRunning": false, # flag to change hud and window behaviors in game
	"playerScore": 0, # player score total (useful for reloads and moving to the next level)
}

# Global storage for high scores data
var highScores: Dictionary [String, Array] = {
	# Example: "password": [ [ score, time, moves ],  [ score, time, moves ], [ score, time, moves ] ]
}



# global function to update input deadzones
func deadzoneUpdate() -> void:
	InputMap.action_set_deadzone("DigitalLeft", currentSettings.analogDeadzone)
	InputMap.action_set_deadzone("DigitalDown", currentSettings.analogDeadzone)
	InputMap.action_set_deadzone("DigitalRight", currentSettings.analogDeadzone)
	InputMap.action_set_deadzone("DigitalUp", currentSettings.analogDeadzone)
