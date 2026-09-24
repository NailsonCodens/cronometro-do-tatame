# UX Scenario — Cronômetro do Tatame

Reference document for LG QA testers. Describes every screen, every remote key
and the expected behaviour of each function.

| | |
| --- | --- |
| App name | Cronômetro do Tatame |
| App ID | com.nailson.tatame |
| Version | 1.0.0 |
| Category | Sports / Fitness |
| Language | Portuguese (pt-BR) |
| Target resolution | 1280x720 |
| Login required | **No** |
| Network required | **No** — the app is fully self-contained and works offline |
| In-app purchase | **No** |
| Personal data collected | **None**. Settings are stored locally via `localStorage` |
| Age rating | All ages |

## What the app does

An interval timer for Brazilian Jiu-Jitsu training. It counts a training round
("rola"), then a rest period, then repeats. It is designed to be read from
across a training mat, so the countdown fills the screen.

## Remote control mapping

| Key | Action |
| --- | --- |
| **OK / Enter** | Activates the focused button |
| **Left / Right** | Moves focus within the current button row |
| **Up / Down** | Moves focus between rows (top icons ↔ bottom buttons) |
| **Back** | Closes the settings panel; on the main screen, exits the app |
| Magic Remote pointer | Click works on every control |

On launch, focus is placed on the main button, so OK works immediately.
The focused control is filled with the phase colour and scaled up, so the
focus position is readable from a distance.

## Screen 1 — Main screen

Layout, top to bottom: phase label and status dot, total elapsed time, two
icon buttons (fullscreen, settings); academy crest; large countdown; round
label; rest message; three buttons (reset, start/pause, skip); remote legend.

### Test steps

1. Launch the app. Expect: `PREPARAR` (prepare) and `00:10`, stopped, focus on
   the centre button labelled `INICIAR`.
2. Press **OK**. Expect: countdown starts. Short beeps during the final
   seconds, then a rising chime, then the phase changes to `ROLA` at `05:00`.
3. During `ROLA`, observe the colour: it moves continuously from green through
   yellow and orange to red as the round progresses. The final 10 seconds are
   red, with one beep per second — the last three higher pitched and the final
   one longer.
4. At zero, a three-blast horn sounds and the phase changes to `DESCANSO`
   (rest) at `01:00`, in blue, showing the message
   "Descanse. Aproveite e tome uma água." (Rest. Take the chance to drink water.)
5. At the end of the rest, a rising chime sounds and the next round starts.
   The round counter increments.
6. Press **OK** again. Expect: countdown pauses, the number dims, the button
   reads `INICIAR`.
7. Press **Right**, then **OK**. Expect: the skip button advances to the next
   phase immediately.
8. Press **Left** twice, then **OK**. Expect: the reset button returns to the
   initial state with the total cleared.

## Screen 2 — Settings

Reached by moving focus **Up** to the top row and pressing **OK** on the gear
icon. Opens full screen.

### Test steps

1. **Up / Down** moves between rows; **Left / Right** moves within a row,
   reaching the `−` and `+` buttons of each value.
2. Press **OK** on `+` next to "Tempo de rola" (round time). Expect: value
   increases by 15 seconds. Holding OK repeats.
3. The shortcut row (`5 + 1`, `6 + 1`, …) sets round and rest together.
4. Toggles: sound, final countdown, vibration, keep screen on, TV mode.
5. "Testar som" (test sound) plays the end-of-round horn followed by the
   start-of-round chime, so volume can be checked.
6. Press **OK** on "Pronto" (done), or press **Back**. Expect: the panel
   closes and focus returns to the main button.
7. Reopen the settings. Expect: every value persists.

## Audio

All sound is generated at runtime with the Web Audio API — there are no audio
files. Frequencies sit between 500 Hz and 2 kHz so they carry over gym noise.
Sound can be disabled entirely in the settings.

## Exit

Pressing **Back** on the main screen closes the app. No data is left running in
the background.

## Notes for the tester

- The app never requests the network. Testing with the TV offline is expected
  to behave identically, including fonts.
- Text is Portuguese (pt-BR); the audience is Brazilian jiu-jitsu academies.
- The crest shown on screen is the logo of the academy the app was built for.
