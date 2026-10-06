#!/usr/bin/env python3
"""Gera o UX Scenario em PDF para a submissão na LG Content Store.

A primeira versão deste documento era só texto e a LG reprovou com
"Insufficient UX scenario": o tester precisa de capturas anotadas de cada tela,
não de descrição escrita. Este script monta um PDF com uma página por tela,
marcadores numerados sobre a captura e tabela explicando cada elemento — além
da tradução de todos os textos, já que a interface é em português.

Uso:  python3 build-ux-scenario.py
Requer: as capturas em loja/ux/ e o Chrome instalado.
"""
import base64, html as H, os, subprocess, sys, tempfile

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SAIDA = "loja/ux-scenario.pdf"

def img(nome):
    with open("loja/ux/%s.png" % nome, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()

# Posição dos marcadores, em % da imagem. Ficam AO LADO do elemento, nunca em
# cima: na primeira tentativa o marcador cobria justamente o que explicava.
POS = {
 "fase":   (2.0, 7),    "total": (82.0, 14),  "cheia": (88.4, 14), "ajustes": (94.6, 14),
 "relogio":(8.0, 34),   "sub":   (29.0, 53),  "frase": (29.0, 62),
 "zerar":  (28.0, 72),  "principal": (50.0, 72), "pular": (72.0, 72),
 "legenda":(29.0, 92),
}

TELAS = [
 ("01-inicial", "Screen 1 — Initial state (app just launched)",
  "This is what the tester sees immediately after the app opens. The timer is "
  "stopped and focus is already on the centre button, so OK starts it right away.",
  [("fase","Phase label","PREPARAR = PREPARE. The countdown before the first round."),
   ("total","Session total","Total elapsed time of the whole session. 00:00 before starting."),
   ("cheia","Fullscreen","Toggles fullscreen."),
   ("ajustes","Settings","Opens the settings screen (Screens 7 and 8)."),
   ("relogio","Countdown","00:10 — the preparation time. Configurable."),
   ("principal","Main button","INICIAR = START. Focused on launch; press OK to begin."),
   ("zerar","Reset","Returns to this initial state and clears the session total."),
   ("pular","Skip","Jumps immediately to the next phase."),
   ("legenda","Remote legend","OK starts and pauses · arrows change the selected button.")]),

 ("02-rola", "Screen 2 — Round running",
  "After the preparation ends, the round starts. The colour of the number moves "
  "continuously from green through yellow and orange as the round progresses — this "
  "is intentional and shows how much time is left without reading the digits.",
  [("fase","Phase label","ROLA = ROUND. A Brazilian Jiu-Jitsu sparring round."),
   ("total","Session total","Keeps counting across rounds and rests."),
   ("relogio","Countdown","Time left in the current round."),
   ("sub","Round counter","ROLA 2 = ROUND 2. Shows 'ROLA 2 de 6' when a round limit is set."),
   ("principal","Main button","PAUSAR = PAUSE while running.")]),

 ("03-rola-fim", "Screen 3 — Round, final seconds",
  "In the last ten seconds everything turns red and one beep sounds per second. The "
  "final beep is longer and lower. At zero, a three-blast horn plays.",
  [("relogio","Countdown","Red in the last ten seconds."),
   ("principal","Main button","Also takes the phase colour.")]),

 ("04-descanso", "Screen 4 — Rest",
  "After the round, the rest period starts in blue. The same ten-second beep countdown "
  "applies, but at zero a rising chime plays instead of the horn, signalling the start "
  "of the next round.",
  [("fase","Phase label","DESCANSO = REST."),
   ("relogio","Countdown","Time left in the rest period."),
   ("sub","Next round","VEM O ROLA 4 = ROUND 4 IS NEXT."),
   ("frase","Rest message","'Descanse. Aproveite e tome uma água.' = "
    "'Rest. Take the chance to drink water.'")]),

 ("05-pausado", "Screen 5 — Paused",
  "Pressing OK while running pauses the timer. The number dims to make the paused state "
  "obvious from a distance, and the button label returns to INICIAR.",
  [("relogio","Countdown","Dimmed while paused."),
   ("principal","Main button","Back to INICIAR = START.")]),

 ("06-fim", "Screen 6 — Session finished",
  "Shown only when a round limit was set and the last round has ended. Pressing OK "
  "restarts the session from the beginning.",
  [("fase","Phase label","FIM = END."),
   ("sub","Summary","'6 ROLAS COMPLETOS' = '6 ROUNDS COMPLETED'."),
   ("principal","Main button","RECOMEÇAR = RESTART.")]),
]

AJUSTES = [
 ("07-ajustes", "Screen 7 — Settings, upper part",
  "Reached from the main screen by moving focus up to the gear icon and pressing OK. "
  "Opens full screen. Up and Down move between rows; Left and Right move within a row, "
  "reaching the − and + buttons of each value.",
  [("Ajustes","Settings","Screen title."),
   ("Vale para os próximos rolas.","Applies to the next rounds.","Subtitle. Settings are saved on the device."),
   ("Atalhos","Shortcuts","Preset pairs. '5 + 1' = 5 min round, 1 min rest."),
   ("Tempo de rola","Round time","Length of each round. − and + change it by 15 seconds."),
   ("Descanso","Rest","Length of the rest. Zero links one round straight into the next."),
   ("Preparação","Preparation","Countdown before the first round."),
   ("Quantos rolas","How many rounds","Round limit. 'Sem limite' = no limit."),
   ("Som","Sound","Master sound toggle."),
   ("Volume","Volume","Sound level. The TV volume still applies.")]),
 ("08-ajustes-fim", "Screen 8 — Settings, lower part",
  "Scrolled to the bottom of the same screen.",
  [("Contagem final","Final countdown","Beeps in the last ten seconds."),
   ("Vibrar","Vibrate","No effect on TV; present for phone use."),
   ("Manter a tela ligada","Keep screen on","Prevents the screen saver during a session."),
   ("Modo TV","TV mode","Larger layout for viewing at a distance. On by default on TV."),
   ("Testar som","Test sound","Plays the end-of-round horn, then the start-of-round chime. "
    "Use this to verify audio without waiting for a round to end."),
   ("Pronto","Done","Closes the settings and returns focus to the main button.")]),
]

PASSOS = [
 ("Launch the app", "PREPARAR and 00:10 are shown, stopped. Focus is on the centre button."),
 ("Press OK", "The preparation counts down with one beep per second; a rising chime at zero."),
 ("Wait", "Phase changes to ROLA at 05:00 and the number is green."),
 ("Observe the colour", "It warms through yellow and orange as the round progresses."),
 ("Wait for the last 10 seconds", "Everything turns red; one beep per second; the final beep is longer."),
 ("Wait for zero", "A three-blast horn plays. Phase changes to DESCANSO at 01:00, in blue."),
 ("Wait for the rest to end", "Ten beeps again, then a rising chime. ROLA 2 starts."),
 ("Press OK", "The timer pauses, the number dims, the button reads INICIAR."),
 ("Press OK again", "The timer resumes from where it stopped."),
 ("Press Right, then OK", "The skip button advances immediately to the next phase."),
 ("Press Left twice, then OK", "The reset button returns to the initial state and clears the total."),
 ("Press Up, then navigate to the gear icon, then OK", "The settings screen opens."),
 ("Reach the + button of 'Tempo de rola' and press OK",
  "The round time increases by 15 seconds. Holding OK repeats."),
 ("Move to 'Testar som' and press OK", "The end-of-round horn plays, then the start chime."),
 ("Press Back", "The settings close and focus returns to the main button."),
 ("Press Back again", "The app exits."),
]

IDENT = [("App name","Cronômetro do Tatame"),("App ID","com.nailson.cronometrotatame"),
 ("Version","1.0.0"),("Category","Sports / Fitness"),
 ("Interface language","Portuguese (pt-BR) — every string is translated in this document"),
 ("Target resolution","1280x720"),("Login required","No"),
 ("Network required","No — the app is fully self-contained and works offline"),
 ("In-app purchase","No"),("Ads","No"),
 ("Personal data collected","None. Settings are stored locally via localStorage"),
 ("Age rating","All ages")]

TECLAS = [("OK / Enter","Activates the focused button"),
 ("Left / Right","Moves focus within the current button row"),
 ("Up / Down","Moves focus between rows: top icons and bottom buttons"),
 ("Back","Closes the settings screen; on the main screen, exits the app"),
 ("Magic Remote pointer","Click works on every control")]

NOTAS = [
 ("No network, by design","The app makes zero network requests. Fonts are embedded as data "
  "URIs and all sounds are generated at runtime with the Web Audio API — there are no audio "
  "files. Testing with the TV disconnected behaves identically. This is not a defect."),
 ("Audio check","Sound is on by default. 'Testar som' in the settings plays both the "
  "end-of-round and start-of-round sounds on demand."),
 ("Two sounds, on purpose","End of round is a flat, repeated low horn. Start of round rises "
  "and holds a bright tone. They are shaped to be told apart across a noisy gym."),
 ("Persistence","All settings survive closing and reopening the app."),
 ("Exit","Back on the main screen closes the app. Nothing keeps running in the background."),
]

CSS = """@page{size:A4;margin:14mm 12mm}
*{box-sizing:border-box}
body{font:10pt/1.5 -apple-system,"Helvetica Neue",Arial,sans-serif;color:#15202b;margin:0}
h1{font-size:20pt;margin:0 0 2pt}
p.sub{margin:0 0 12pt;color:#4a5967}
h2{font-size:13pt;margin:0 0 4pt}
p.intro{margin:0 0 8pt;color:#33424f}
.pagina{page-break-after:always}
.pagina:last-child{page-break-after:auto}
.shot{position:relative;width:100%;border:1px solid #cfd8e0;line-height:0;margin-bottom:9pt}
.shot img{width:100%;display:block}
.marca{position:absolute;transform:translate(-50%,-50%);
  width:19px;height:19px;border-radius:50%;background:#e8372c;color:#fff;
  font:bold 10.5px/19px -apple-system,Arial,sans-serif;text-align:center;
  border:2px solid #fff;box-shadow:0 0 0 1px rgba(0,0,0,.35)}
table{border-collapse:collapse;width:100%;font-size:9pt}
th{background:#eef2f6;text-align:left;font-weight:600}
th,td{border:1px solid #cfd8e0;padding:4pt 6pt;vertical-align:top}
td.n{width:22pt;text-align:center;font-weight:700;color:#e8372c}
td.el{width:26%;font-weight:600}
tr{page-break-inside:avoid}
ol.passos{margin:0;padding-left:0;list-style:none;counter-reset:p}
ol.passos li{counter-increment:p;display:flex;gap:7pt;margin-bottom:5pt;page-break-inside:avoid}
ol.passos li::before{content:counter(p);flex:0 0 17px;height:17px;border-radius:50%;
  background:#15202b;color:#fff;font:bold 9px/17px Arial;text-align:center}
.acao{flex:0 0 38%;font-weight:600}
.esperado{flex:1;color:#33424f}"""

def monta():
    o = ['<meta charset="utf-8"><style>%s</style>' % CSS]
    o.append('<div class="pagina"><h1>UX Scenario — Cronômetro do Tatame</h1>'
      '<p class="sub">Reference document for LG QA testers. Every screen is shown with '
      'numbered callouts, every on-screen string is translated, and a step-by-step test '
      'procedure is given at the end.</p><table>')
    for k, v in IDENT:
        o.append("<tr><th style='width:30%%'>%s</th><td>%s</td></tr>" % (H.escape(k), H.escape(v)))
    o.append('</table><h2 style="margin-top:14pt">What the app does</h2><p class="intro">'
      'An interval timer for Brazilian Jiu-Jitsu training. It counts a training round '
      '(called a "rola" in Brazilian Portuguese), then a rest period, then repeats until '
      'stopped. It is designed to be read from across a training mat, so the countdown '
      'fills the screen.</p>')
    o.append('<h2 style="margin-top:12pt">Remote control</h2><table>'
      '<tr><th style="width:26%">Key</th><th>Action</th></tr>')
    for k, v in TECLAS:
        o.append("<tr><td style='font-weight:600'>%s</td><td>%s</td></tr>" % (H.escape(k), H.escape(v)))
    o.append('</table><p class="intro" style="margin-top:7pt">On launch, focus is already on '
      'the main button, so OK works immediately. The focused control is filled with the phase '
      'colour and scaled up, so the focus position is readable from a distance — see Screen 9.'
      '</p></div>')

    for nome, titulo, intro, itens in TELAS:
        o.append('<div class="pagina"><h2>%s</h2><p class="intro">%s</p>'
                 % (H.escape(titulo), H.escape(intro)))
        o.append('<div class="shot"><img src="%s">' % img(nome))
        for i, (chave, _, _) in enumerate(itens, 1):
            x, y = POS[chave]
            o.append('<span class="marca" style="left:%s%%;top:%s%%">%d</span>' % (x, y, i))
        o.append('</div><table><tr><th>№</th><th>Element</th><th>Meaning and behaviour</th></tr>')
        for i, (_, el, desc) in enumerate(itens, 1):
            o.append("<tr><td class='n'>%d</td><td class='el'>%s</td><td>%s</td></tr>"
                     % (i, H.escape(el), H.escape(desc)))
        o.append("</table></div>")

    for nome, titulo, intro, itens in AJUSTES:
        o.append('<div class="pagina"><h2>%s</h2><p class="intro">%s</p>'
                 % (H.escape(titulo), H.escape(intro)))
        o.append('<div class="shot"><img src="%s"></div>' % img(nome))
        o.append('<table><tr><th>On screen (pt-BR)</th><th>Meaning</th><th>What it does</th></tr>')
        for pt, en, desc in itens:
            o.append("<tr><td class='el'>%s</td><td style='width:22%%'>%s</td><td>%s</td></tr>"
                     % (H.escape(pt), H.escape(en), H.escape(desc)))
        o.append("</table></div>")

    o.append('<div class="pagina"><h2>Screen 9 — Focus indication</h2><p class="intro">'
      'The focused control is filled with the current phase colour, scaled up and outlined '
      'in white. Here focus is on the skip button while a round is running. This is how the '
      'tester can tell which control OK will activate.</p>')
    o.append('<div class="shot"><img src="%s"></div></div>' % img("09-foco-pular"))

    o.append('<div class="pagina"><h2>Test procedure</h2><p class="intro">Each step lists the '
      'action and the expected result. To see a complete cycle quickly, first open the settings '
      'and use the "3 + 0:45" shortcut — a full round-rest-round cycle then takes under two '
      'minutes instead of six.</p><ol class="passos">')
    for acao, esperado in PASSOS:
        o.append('<li><span class="acao">%s</span><span class="esperado">%s</span></li>'
                 % (H.escape(acao), H.escape(esperado)))
    o.append('</ol><h2 style="margin-top:14pt">Notes</h2><table>'
             '<tr><th style="width:30%">Point</th><th>Detail</th></tr>')
    for k, v in NOTAS:
        o.append("<tr><td style='font-weight:600'>%s</td><td>%s</td></tr>"
                 % (H.escape(k), H.escape(v)))
    o.append("</table></div>")
    return "\n".join(o)

if __name__ == "__main__":
    if not os.path.isdir("loja/ux"):
        sys.exit("faltam as capturas em loja/ux/")
    html = monta()
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(html); caminho = f.name
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--no-pdf-header-footer",
                    "--print-to-pdf=" + SAIDA, "file://" + caminho],
                   capture_output=True)
    os.unlink(caminho)
    d = open(SAIDA, "rb").read()
    print("%s  %d kB  %d páginas" % (SAIDA, len(d)//1024,
          d.count(b"/Type /Page") - d.count(b"/Type /Pages")))
