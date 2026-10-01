# Resposta ao defeito QA2026093023459

**Problema relatado:** App Icon Background does not match the tile color (P2)

Texto para colar na resposta do chamado:

```
Fixed in version 1.0.1.

Cause: the appinfo.json did not declare "iconColor". As the default tile colour
is white, the launcher drew a white tile behind an icon whose own background is
dark (#0B1016), producing the mismatch.

Fix: "iconColor": "#0B1016" was added to appinfo.json, matching the icon
background exactly. No change was made to the icon image itself.

Note: the package previously declared "bgColor": "#07090C", which we now
understand is ignored from webOS 3.x onwards and never affected the tile.

Updated packages attached as version 1.0.1.
```
