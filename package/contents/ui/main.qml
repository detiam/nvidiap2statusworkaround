import QtQuick 2.5

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

Item {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.compactRepresentation: Plasmoid.fullRepresentation

    property bool firstTime: true
    property bool initModeState: false
    property bool changeModeStateFailed: false
    property string servName: plasmoid.configuration.servName

    function lowClock(enableOrDisable, callbacks) {
        let command = 'systemctl '+enableOrDisable+' --now '+servName+''
        executable.exec(command, callbacks)
    }

    Component.onCompleted: {
        executable.exec('systemctl is-active '+servName+'', function(retcode, stdout) {
            if (retcode == 0 && stdout.trim() === 'active') {
                initModeState = true
            } else {
                initModeState = false
            }
        })
    }

    PlasmaComponents.Switch {
        id: toggleSwitch

        anchors.centerIn: parent

        transform: Translate { x: 2 }
        checked: initModeState
        onCheckedChanged: {
            if (firstTime) { firstTime = false
                if (initModeState) { return }
            }
            if (changeModeStateFailed) {
                changeModeStateFailed = false
            } else {
                if (checked) {
                    lowClock('enable', function(retcode) {
                        if(retcode !== 0) {
                            changeModeStateFailed = true
                            checked = false
                        }
                    })
                } else {
                    lowClock('disable', function(retcode) {
                        if(retcode !== 0) {
                            changeModeStateFailed = true
                            checked = true
                        }
                    })
                } 
            }
        }
    }

    Plasmoid.onActivated: {
        toggleSwitch.checked = !toggleSwitch.checked
    }

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: {
            let retcode = data["exit code"]
            var stdout = data["stdout"]
            
            if (callbacks[sourceName] !== undefined) {
                callbacks[sourceName](retcode, stdout);
            }
            
            exited(sourceName, stdout)
            disconnectSource(sourceName) // cmd finished
        }
        function exec(cmd, onNewDataCallback) {
            if (onNewDataCallback !== undefined){
                callbacks[cmd] = onNewDataCallback
            }
            connectSource(cmd)
        }
        signal exited(string sourceName, string stdout)
    }
}
