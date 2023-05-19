import QtQuick 2.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.1 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents

Item {
    id: root

    property bool switchState: false
    property bool switchStatefail: false
    
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.compactRepresentation: Plasmoid.fullRepresentation

    PlasmaComponents.Switch {
        id: toggleSwitch

        anchors.centerIn: parent
        checked: root.switchState
        transform: Translate { x: 2 }
        
        onCheckedChanged: {
            if (switchStatefail) {
                switchStatefail = false
            } else {
                if (checked) {
                    executable.exec('pkexec sh -c "nvidia-smi -lgc 210,600 & nvidia-smi -lmc 405,810"', function(retcode) {
                        if(retcode !== 0) {
                            switchStatefail = true
                            toggleSwitch.checked = false
                        }
                    })
                } else {
                    executable.exec('pkexec sh -c "nvidia-smi -rgc & nvidia-smi -rmc"', function(retcode) {
                        if(retcode !== 0) {
                            switchStatefail = true
                            toggleSwitch.checked = true
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
