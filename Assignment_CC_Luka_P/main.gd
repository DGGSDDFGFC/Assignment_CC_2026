extends Node2D

# midi channels for each instrument
const GUITAR_CH = 0
const MARIMBA_CH = 1
const STRINGS_CH = 2

# midi notes per row (top = high pitch, bottom = low)
const GUITAR_NOTES = [72, 64, 60]
const MARIMBA_NOTES = [76, 67, 62]
const STRINGS_NOTES = [69, 62, 57]

# grid is 3 rows x 7 cols
const ROWS = 3
const COLS = 7

# 0 = empty, 1 = guitar, 2 = kick, 3 = drums
var all_lines = []       # stores all 4 lines data
var current_line = 0     # which line we are editing rn
var current_grid = []    # the grid we are currently editing (2d array)

var is_playing = false
var step = 0             # current column in the sequence
var step_timer = 0.0
var step_speed = 0.2     # seconds per beat, can tweak this

var block_buttons = []   # holds references to the buttons in the grid

# colors for each sound type
var color_empty = Color(0.3, 0.3, 0.3)
var color_guitar = Color(0.2, 0.8, 0.2)
var color_kick = Color(0.8, 0.2, 0.2)
var color_drums = Color(0.2, 0.4, 0.9)


func _ready():
	change_instrument(GUITAR_CH, 25)   # acoustic guitar
	change_instrument(MARIMBA_CH, 12)  # marimba
	change_instrument(STRINGS_CH, 45)  # pizzicato strings

	# init all 4 lines as empty grids
	for i in range(4):
		var empty_line = []
		for r in range(ROWS):
			var row_data = []
			for c in range(COLS):
				row_data.append(0)
			empty_line.append(row_data)
		all_lines.append(empty_line)

	current_grid = all_lines[0]
	build_grid()


func build_grid():
	# clear whatever was in the grid before
	for child in $CanvasLayer/VBox/Grid.get_children():
		child.queue_free()

	block_buttons = []

	for r in range(ROWS):
		var row_buttons = []
		for c in range(COLS):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(60, 60)

			# little trick to pass row and col into the signal
			var r_copy = r
			var c_copy = c
			btn.pressed.connect(func(): on_block_clicked(r_copy, c_copy))

			$CanvasLayer/VBox/Grid.add_child(btn)
			row_buttons.append(btn)

		block_buttons.append(row_buttons)

	refresh_grid_colors()


func refresh_grid_colors():
	for r in range(ROWS):
		for c in range(COLS):
			var val = current_grid[r][c]
			var btn = block_buttons[r][c]
			if val == 0:
				btn.modulate = color_empty
				btn.text = ""
			elif val == 1:
				btn.modulate = color_guitar
				btn.text = "G"
			elif val == 2:
				btn.modulate = color_kick
				btn.text = "M"
			elif val == 3:
				btn.modulate = color_drums
				btn.text = "S"


func on_block_clicked(r, c):
	if is_playing:
		return  # dont let them edit while playing

	# cycle through 0 -> 1 -> 2 -> 3 -> 0
	current_grid[r][c] = (current_grid[r][c] + 1) % 4
	refresh_grid_colors()


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			on_enter_pressed()


func on_enter_pressed():
	if is_playing:
		return

	if current_line < 3:
		current_line += 1
		current_grid = all_lines[current_line]
		build_grid()
		$CanvasLayer/VBox/StatusLabel.text = "Line %d / 4 — Click blocks, Enter to confirm" % (current_line + 1)
	else:
		# all 4 lines done, start playing!
		$CanvasLayer/VBox/StatusLabel.text = "Playing! All 4 lines looping"
		start_playing()


func start_playing():
	is_playing = true
	step = 0
	step_timer = 0.0
	$CanvasLayer/VBox/HBox/PlayButton.text = "Stop"


func stop_playing():
	is_playing = false
	$CanvasLayer/VBox/HBox/PlayButton.text = "Play"
	$CanvasLayer/VBox/StatusLabel.text = "Stopped. Press Play to resume"


func _process(delta):
	if not is_playing:
		return

	step_timer += delta
	if step_timer >= step_speed:
		step_timer = 0.0
		play_current_step()
		step = (step + 1) % COLS  # loop back after 7 steps


func play_current_step():
	# go through all 4 lines and play whatever is in the current column
	for line_idx in range(4):
		var line_data = all_lines[line_idx]
		for r in range(ROWS):
			var sound = line_data[r][step]
			if sound == 0:
				continue  # nothing here

			if sound == 1:
				play_note(GUITAR_NOTES[r], step_speed * 0.9, GUITAR_CH)
			elif sound == 2:
				play_note(MARIMBA_NOTES[r], step_speed * 0.9, MARIMBA_CH)
			elif sound == 3:
				play_note(STRINGS_NOTES[r], step_speed * 0.9, STRINGS_CH)


func _on_play_button_pressed():
	if is_playing:
		stop_playing()
	else:
		start_playing()


# --- your premade functions below, didnt touch them ---

func change_instrument(channel, instrument):
	var midi_event = InputEventMIDI.new()
	midi_event.channel = channel
	midi_event.message = MIDI_MESSAGE_PROGRAM_CHANGE
	midi_event.instrument = instrument
	$MidiPlayer.receive_raw_midi_message(midi_event)

func play_note(note, duration, channel):
	var m = InputEventMIDI.new()
	m.message = MIDI_MESSAGE_NOTE_ON
	m.pitch = note
	m.velocity = 100
	m.channel = channel		
	$MidiPlayer.receive_raw_midi_message(m)	
	await get_tree().create_timer(duration).timeout
	m = InputEventMIDI.new()
	m.message = MIDI_MESSAGE_NOTE_OFF
	m.pitch = note
	m.velocity = 100
	m.channel = channel		
	$MidiPlayer.receive_raw_midi_message(m)
