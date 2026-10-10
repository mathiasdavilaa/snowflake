"""Add an independent Howdy PAM conversation to the pinned Ryoku lockscreen."""
import os
from pathlib import Path

root = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
path = root / "quickshell-lockscreen/shim/SddmShim.qml"
if not path.exists():
    print("Howdy: lockscreen ainda não materializada; integração será aplicada no login.")
    raise SystemExit(0)

text = path.read_text()
marker = "// snowflake-howdy-v1"
if marker in text:
    raise SystemExit(0)

# Fail visibly if a Ryoku update changes the integration points. Do not partly
# rewrite a lockscreen or change either existing authentication conversation.
anchors = [
    "    function maybeArm() {",
    "        shim.startPw();\n        if (shim.fingerprintReady && !pamFp.active)",
    "    function resetAuth() {",
]
for anchor in anchors:
    if text.count(anchor) != 1:
        raise SystemExit("Howdy: SddmShim.qml mudou; revisar integração antes de aplicar.")

addition = '''
    // snowflake-howdy-v1
    // One bounded face scan when the compositor has secured the lock.
    // The existing password conversation remains available in parallel.
    property bool howdyAttempted: false
    onUnlockedChanged: {
        if (shim.unlocked)
            pamHowdy.abort();
    }
    PamContext {
        id: pamHowdy
        config: "ryoku-howdy"
        configDirectory: "/etc/pam.d"
        onCompleted: (result) => {
            if (!shim.armWhenReady || shim.unlocked)
                return;
            if (result === PamResult.Success) {
                shim.unlocked = true;
                pamPw.abort();
                pamFp.abort();
                shim.sddm.loginSucceeded();
                Quickshell.execDetached(["loginctl", "unlock-session"]);
            }
        }
        onError: (error) => {
            console.warn("[howdy] reconhecimento indisponível:", error);
        }
    }
    function startHowdy() {
        if (!shim.armWhenReady || shim.unlocked || shim.howdyAttempted)
            return;
        shim.howdyAttempted = true;
        pamHowdy.user = Quickshell.env("USER");
        if (!pamHowdy.start())
            console.warn("[howdy] não foi possível iniciar a autenticação");
    }

'''
text = text.replace(anchors[0], addition + anchors[0])
text = text.replace(anchors[1], "        shim.startPw();\n        shim.startHowdy();\n        if (shim.fingerprintReady && !pamFp.active)")
text = text.replace(anchors[2], anchors[2] + "\n        pamHowdy.abort();\n        shim.howdyAttempted = false;")
# Atomic replacement: never expose a partly written QML file.
tmp = path.with_name(path.name + ".howdy-tmp")
tmp.write_text(text)
tmp.chmod(path.stat().st_mode & 0o777)
tmp.replace(path)
