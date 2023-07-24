import QtQuick 2.5
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.4 as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_servName: servName.text

    QQC2.TextField {
        id: servName
        Kirigami.FormData.label: i18n("Systemd Service Name:")
        placeholderText: 'nvidia-p2statusworkaround'
    }
}