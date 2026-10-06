# Defeito QA2026100223681 — Insufficient UX scenario

**Causa:** o documento enviado era só texto. A LG usa o UX Scenario para o
tester navegar no app, e precisa de capturas anotadas de cada tela — ainda mais
num app cuja interface está em português.

**Correção:** documento refeito, de 3 para 11 páginas, com uma página por tela,
marcadores numerados sobre a captura, tabela explicando cada elemento com a
tradução, e um procedimento de teste passo a passo com o resultado esperado.

Texto para a resposta do chamado:

```
The UX Scenario has been replaced with a much more detailed version.

The previous document was text only. The new one has 11 pages and contains:

- One page per screen, with the actual screenshot of that screen
- Numbered callouts placed on each screenshot, with a table explaining what
  every element is and how it behaves
- A full translation of every on-screen string, since the interface is in
  Portuguese (pt-BR)
- A dedicated page showing how focus is indicated, so the tester can see which
  control OK will activate
- A step-by-step test procedure, each step listing the action and the expected
  result
- Notes covering the points that could be mistaken for defects, in particular
  that the app makes no network requests by design and behaves identically with
  the TV offline

Screens documented: initial state, round running, round final seconds, rest,
paused, session finished, settings (upper and lower part), and focus
indication.
```
