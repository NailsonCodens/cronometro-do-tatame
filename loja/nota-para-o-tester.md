# Note for Tester

Opção a marcar: **Other Information** (é primeira submissão, não uma revisão).

Texto para colar no campo:

```
First submission.

The app is an interval timer for Brazilian Jiu-Jitsu training. The interface is
in Portuguese (pt-BR); the target audience is Brazilian gyms.

Points that may look unusual, declared up front:

1. NO NETWORK. The app makes zero network requests. Fonts are embedded as data
   URIs and all sounds are generated at runtime with the Web Audio API — there
   are no audio files. Testing with the TV disconnected is expected to behave
   exactly the same. This is intentional, not a defect.

2. NO LOGIN, NO PURCHASE, NO ADS, NO DATA COLLECTION. Settings are kept in
   localStorage on the device only.

3. FASTER TESTING. Default times are 5 minutes of round and 1 minute of rest.
   To see a full cycle quickly, open the settings (gear icon, top right) and
   use the "3 + 0:45" shortcut, or lower "Tempo de rola" and "Descanso" with
   the minus buttons. A complete round-rest-round cycle then takes under two
   minutes.

4. AUDIO. Sound is on by default. The settings screen has a "Testar som"
   button that plays the end-of-round horn followed by the start-of-round
   chime, so the audio can be verified without waiting for a round to end.

5. REMOTE. On launch, focus is already on the main button, so OK starts the
   timer immediately. Arrows move focus between buttons; the focused button is
   filled with colour and scaled up. Back closes the settings panel, and exits
   the app from the main screen. Magic Remote pointer clicks work on every
   control.

The UX Scenario document attached describes every screen and the expected
result of each step.
```
