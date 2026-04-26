# Music Sequencer — Godot 4

## Project Title
Music Sequencer

## Contributor
| | |
|---|---|
| **Name** | Luka Paranyak |
| **Student Number** | A00041906 |
| **Class Group** | TU850 |

## Video
*(YouTube link to be added)*

## Screenshots
*(Add screenshots here using relative or absolute URLs)*

## Description
This project is a music sequencer built in Godot 4. It features a 4-line grid system where each line consists of 3 rows and 8 columns of blocks. You can place one of 3 different instruments — Guitar, Marimba, and Pizzicato Strings — into any block to build up melodies. Each row represents a different pitch, with the top row being the highest and the bottom being the lowest. All 4 lines loop simultaneously when played, allowing you to layer sounds and create interesting musical combinations.

## Instructions for Use
1. Launch the project in Godot 4
2. You will start on Line 1. Click any block in the grid to cycle through sounds — **G** (Guitar), **M** (Marimba), **S** (Strings), or back to empty
3. Use the **arrow keys (Up/Down)** to switch between the 4 lines
4. Use the **BPM slider** to control the playback speed
5. Press the **Play button** to start playback — all 4 lines will loop at the same time
6. Press **Stop** to pause and go back to editing

## How It Works
The sequencer is built around a timer that ticks on every beat. On each tick it reads the current column across all 4 lines and plays whatever sounds it finds there using MIDI. The grid is generated in code using a loop that creates 24 buttons arranged in 3 rows and 8 columns. Each button stores its row and column position so when clicked it knows which slot to update. A playhead line smoothly slides across the 4 line indicator bars to show the current playback position in real time.

## List of Classes/Assets

| Class/Asset | Source |
|---|---|
| `main.gd` | Self written |
| `Main.tscn` | Self written |
| Godot MIDI Player plugin | From [arlez80/GodotMidiPlayer](https://github.com/arlez80/GodotMidiPlayer) |

## References
* [Godot 4 Documentation](https://docs.godotengine.org/en/stable/)
* [Godot MIDI Player plugin by arlez80](https://github.com/arlez80/GodotMidiPlayer)

## What I Am Most Proud Of
The part I am most proud of is the grid generation system and the way sounds are inserted into the buttons. Building the whole 3×8 grid dynamically in code, having each button correctly remember its position, and making the cycling between sounds work cleanly was a satisfying challenge to solve.

## What I Learned
Through this project I deepened my understanding of Godot and GDScript — particularly how to manage UI nodes in code, handle input, and work with timers for real-time playback. I also learned how small design decisions, like which instruments to combine or how to arrange the pitch rows, can lead to surprisingly interesting and varied musical results.
