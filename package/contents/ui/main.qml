import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.kwin

/*
kwinscript:
plasmapkg2 --type kwinscript -i .
plasmapkg2 --type kwinscript -u .
debug -> journalctl -g "win_audio:" -f
debug -> ksyslog filter win_audio
*/

Item {
	id: root
    property string winOpenSound: KWin.readConfig("WinOpenSound", "/usr/share/sounds/ubuntu/notifications/Blip.ogg");
    property int winOpenSoundVolume: KWin.readConfig("WinOpenSoundVolume", 50);
    
    property string winCloseSound: KWin.readConfig("WinCloseSound", "/usr/share/sounds/ubuntu/stereo/bell.ogg")
    property int winCloseSoundVolume: KWin.readConfig("WinCloseSoundVolume", 40)

    property string winMaxSound: KWin.readConfig("WinMaxSound", "/usr/share/sounds/Oxygen-Window-Maximize.ogg")
    property int winMaxSoundVolume: KWin.readConfig("WinMaxSoundVolume", 90)

    property string winUnmaxSound: KWin.readConfig("WinUnmaxSound", "/usr/share/sounds/Oxygen-Window-Minimize.ogg")
    property int winUnmaxSoundVolume: KWin.readConfig("WinUnmaxSoundVolume", 90)

    property string winMinSound: KWin.readConfig("WinMinSound", "/usr/share/sounds/Oxygen-Window-Minimize.ogg")
    property int winMinSoundVolume: KWin.readConfig("WinMinSoundVolume", 90)

    property string winUnminSound: KWin.readConfig("WinUnminSound", "/usr/share/sounds/Oxygen-Window-Maximize.ogg")
    property int winUnminSoundVolume: KWin.readConfig("WinUnminSoundVolume", 90)

    property string winResSound: KWin.readConfig("WinResSound", "")
    property int winResSoundVolume: KWin.readConfig("WinResSoundVolume", 0)

    property string winActiveSound: KWin.readConfig("WinActiveSound", "")
    property int winActiveSoundVolume: KWin.readConfig("WinActiveSoundVolume", 0)

    property string deskChangeSound: KWin.readConfig("DeskChangeSound", "/usr/share/sounds/ubuntu/stereo/window-slide.ogg")
    property int deskChangeSoundVolume: KWin.readConfig("DeskChangeSoundVolume", 40)

	property var win_open_sound: [winOpenSound, winOpenSoundVolume]
	property var win_close_sound: [winCloseSound, winCloseSoundVolume]
	property var win_max_sound: [winMaxSound, winMaxSoundVolume]
	property var win_unmax_sound: [winUnmaxSound, winUnmaxSoundVolume]
	property var win_min_sound: [winMinSound, winMinSoundVolume]
	property var win_unmin_sound: [winUnminSound, winUnminSoundVolume]
	property var win_res_sound: [winResSound, winResSoundVolume]
	property var win_active_sound: [winActiveSound, winActiveSoundVolume]
	property var desk_change_sound: [deskChangeSound, deskChangeSoundVolume]

	P5Support.DataSource {
        id: shell
        engine: "executable"
        connectedSources: []

        onNewData: function (source, data) {
            var exitCode = data["exit code"]
            var exitStatus = data["exit status"]
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            exited(source, exitCode, exitStatus, stdout, stderr)
            disconnectSource(source) // cmd finished
        }

        function audio(cmd) {
            console.error(cmd);
            shell.connectSource("paplay --volume="+(65536 * cmd[1] / 100)+" "+cmd[0]);
        }

        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
    }

	function win_type_normal(client)
	{
		var ret = false;
		if (client.minimizable && client.closeable && client.maximizable && client.resizeable && client.moveable && client.moveableAcrossScreens)
		{
			if (!client.specialWindow && !client.transient && !client.dialog && !client.notification)
			{
				ret = true;
			}
		}
		return ret;
	}

    // function win_res(client)
    // {
    //     if (win_type_normal(client))
    //     {
    //         shell.audio(win_res_sound);
    //     }
    // }

    function desk_change(desk, client)
    {
        // You can format it as /home/niko/Images/HypnOS/Audio/tab%1.ogg
        // Where %1 is the current desktop from the left starting at 1
        var x11DesktopNumber = Workspace.currentDesktop.x11DesktopNumber;
        shell.audio([desk_change_sound[0].arg(x11DesktopNumber), desk_change_sound[1]]);
    }

    function setup(window) {
        if (!win_type_normal(window)) return;

        window.maximizedChanged.connect(() => {
            if (window.maximized) {
                shell.audio(win_max_sound);
            } else {
                shell.audio(win_unmax_sound);
            }
        });

        window.minimizedChanged.connect(() => {
            if (window.minimized) {
                shell.audio(win_min_sound);
            } else {
                shell.audio(win_unmin_sound);
            }
        });

        window.activeChanged.connect(() => {
            if (window.active) {
                shell.audio(win_active_sound);
            }
        });
    }

    Component.onCompleted: {
        Workspace.windowAdded.connect(w => {
            if (!win_type_normal(w)) return;
            shell.audio(win_open_sound);
            setup(w);
        });
        Workspace.windowRemoved.connect(w => {
            if (!win_type_normal(w)) return;
            shell.audio(win_close_sound);
        });
        Workspace.currentDesktopChanged.connect(desk_change);
        Workspace.windowList().forEach(setup);
        // Workspace.clientRestored.connect(win_res);
    }
}
