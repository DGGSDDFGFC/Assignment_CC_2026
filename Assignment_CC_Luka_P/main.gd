extends Node2D

const GUITAR_CH = 0
const MARIMBA_CH = 1
const STRINGS_CH = 2

const GUITAR_NOTES = [72, 64, 60]
const MARIMBA_NOTES = [76, 67, 62]
const STRINGS_NOTES = [69, 62, 57]

const ROWS = 3
const COLS = 8
const NUM_LINES = 4

var all_lines = []
var current_line = 0
var current_grid = []

var is_playing = false
var step = 0
var step_timer = 0.0
var step_speed = 0.5
var bpm = 120.0

var block_buttons = []

# beat indicator stuff
var beat_blocks = []
var beat_flash_timer = 0.0
var beat_is_lit = false
var beat_flash_duration = 0.1

# line indicator stuff
var line_bars = []

# playhead stuff
var playhead_x = 0.0

# colors
var color_empty = Color(0.3, 0.3, 0.3)
var color_guitar = Color(0.2, 0.8, 0.2)
var color_marimba = Color(0.8, 0.2, 0.2)
var color_strings = Color(0.2, 0.4, 0.9)

var color_beat_off = Color(0.2, 0.2, 0.2)
var color_beat_on = Color(1.0, 0.85, 0.2)

var color_bar_inactive = Color(0.25, 0.25, 0.25)
var color_bar_active = Color(0.9, 0.9, 0.9)


func _ready():
	change_instrument(GUITAR_CH, 25)
	change_instrument(MARIMBA_CH, 12)
	change_instrument(STRINGS_CH, 45)

	for i in range(NUM_LINES):
		var empty_line = []
		for r in range(ROWS):
			var row_data = []
			for c in range(COLS):
				row_data.append(0)
			empty_line.append(row_data)
		all_lines.append(empty_line)

	current_grid = all_lines[0]

	build_beat_indicator()
	build_line_indicator()
	build_grid()

	$CanvasLayer/VBox/BpmSlider.value = bpm
	$CanvasLayer/VBox/BpmLabel.text = "BPM: %d" % int(bpm)
	update_step_speed()

	if not $CanvasLayer/VBox/BpmSlider.value_changed.is_connected(_on_bpm_slider_value_changed):
		$CanvasLayer/VBox/BpmSlider.value_changed.connect(_on_bpm_slider_value_changed)

	$CanvasLayer/VBox/PlayButton.pressed.connect(_on_play_button_pressed)


func build_beat_indicator():
	beat_blocks = []
	for i in range(COLS):
		var b = ColorRect.new()
		b.custom_minimum_size = Vector2(60, 16)
		b.color = color_beat_off
		$CanvasLayer/VBox/BeatIndicator.add_child(b)
		beat_blocks.append(b)


func build_line_indicator():
	line_bars = []
	line_bars.append($CanvasLayer/VBox/LineIndicator/Bar0)
	line_bars.append($CanvasLayer/VBox/LineIndicator/Bar1)
	line_bars.append($CanvasLayer/VBox/LineIndicator/Bar2)
	line_bars.append($CanvasLayer/VBox/LineIndicator/Bar3)
	refresh_line_indicator()


func refresh_line_indicator():
	for i in range(NUM_LINES):
		if i == current_line:
			line_bars[i].color = color_bar_active
		else:
			line_bars[i].color = color_bar_inactive


func build_grid():
	for child in $CanvasLayer/VBox/Grid.get_children():
		child.queue_free()

	block_buttons = []

	for r in range(ROWS):
		var row_buttons = []
		for c in range(COLS):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(60, 60)

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

			var is_active_col = is_playing and (c == step)

			if val == 0:
				btn.text = ""
				if is_active_col:
					btn.modulate = Color(0.6, 0.6, 0.6)
				else:
					btn.modulate = color_empty
			elif val == 1:
				btn.text = "G"
				if is_active_col:
					btn.modulate = Color(0.5, 1.0, 0.5)
				else:
					btn.modulate = color_guitar
			elif val == 2:
				btn.text = "M"
				if is_active_col:
					btn.modulate = Color(0.5, 0.8, 1.0)
				else:
					btn.modulate = color_marimba
			elif val == 3:
				btn.text = "S"
				if is_active_col:
					btn.modulate = Color(0.8, 0.6, 1.0)
				else:
					btn.modulate = color_strings


func on_block_clicked(r, c):
	if is_playing:
		return
	current_grid[r][c] = (current_grid[r][c] + 1) % 4
	refresh_grid_colors()


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DOWN:
			on_arrow_down()
		elif event.keycode == KEY_UP:
			on_arrow_up()


func on_arrow_down():
	if is_playing:
		return
	if current_line < 3:
		go_to_line(current_line + 1)


func on_arrow_up():
	if is_playing:
		return
	if current_line > 0:
		go_to_line(current_line - 1)


func go_to_line(idx):
	current_line = idx
	current_grid = all_lines[current_line]
	build_grid()
	refresh_line_indicator()
	$CanvasLayer/VBox/StatusLabel.text = "Line %d / 4 — Click blocks, Enter to confirm" % (current_line + 1)


func start_playing():
	is_playing = true
	step = 0
	step_timer = 0.0
	playhead_x = 0.0
	$CanvasLayer/VBox/PlayButton.text = "Stop"
	$CanvasLayer/VBox/StatusLabel.text = "Playing! All 4 lines looping"


func stop_playing():
	is_playing = false
	step = 0
	playhead_x = 0.0
	# reset playhead position
	var playhead = $CanvasLayer/VBox/LineIndicatorOverlay/Playhead
	playhead.position.x = 0
	# turn off beat blocks
	for b in beat_blocks:
		b.color = color_beat_off
	$CanvasLayer/VBox/PlayButton.text = "Play"
	$CanvasLayer/VBox/StatusLabel.text = "Line %d / 4 — Click blocks to edit" % (current_line + 1)
	refresh_grid_colors()


func update_step_speed():
	step_speed = 60.0 / bpm


func _on_bpm_slider_value_changed(value):
	bpm = value
	update_step_speed()
	$CanvasLayer/VBox/BpmLabel.text = "BPM: %d" % int(bpm)


func _process(delta):
	# handle beat flash fading out
	if beat_is_lit:
		beat_flash_timer += delta
		if beat_flash_timer >= beat_flash_duration:
			beat_is_lit = false
			for b in beat_blocks:
				b.color = color_beat_off

	if not is_playing:
		return

	step_timer += delta

	# update playhead position smoothly
	# total time for one full loop across all 4 lines
	var total_loop_time = step_speed * COLS * NUM_LINES
	var elapsed = (step * step_speed) + step_timer  # how far we are in the loop
	var progress = fmod(elapsed, total_loop_time) / total_loop_time

	var bar = $CanvasLayer/VBox/LineIndicator/Bar0
	var bar_width = bar.get_rect().size.x
	playhead_x = progress * bar_width

	var playhead = $CanvasLayer/VBox/LineIndicatorOverlay/Playhead
	var indicator = $CanvasLayer/VBox/LineIndicator
	playhead.size = Vector2(4, indicator.get_rect().size.y)
	playhead.global_position = Vector2(indicator.global_position.x + playhead_x, indicator.global_position.y)

	if step_timer >= step_speed:
		step_timer = 0.0
		flash_beat()
		play_current_step()
		step = (step + 1) % COLS


func flash_beat():
	beat_is_lit = true
	beat_flash_timer = 0.0
	for b in beat_blocks:
		b.color = color_beat_on


func play_current_step():
	for line_idx in range(NUM_LINES):
		var line_data = all_lines[line_idx]
		for r in range(ROWS):
			var sound = line_data[r][step]
			if sound == 0:
				continue
			if sound == 1:
				play_note(GUITAR_NOTES[r], step_speed * 0.9, GUITAR_CH)
			elif sound == 2:
				play_note(MARIMBA_NOTES[r], step_speed * 0.9, MARIMBA_CH)
			elif sound == 3:
				play_note(STRINGS_NOTES[r], step_speed * 0.9, STRINGS_CH)

	refresh_grid_colors()


func _on_play_button_pressed():
	if is_playing:
		stop_playing()
	else:
		start_playing()


# --- premade functions ---

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
