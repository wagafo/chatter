/*
 * Copyright (C) 2018 Rúben Carneiro <rubencarneiro01@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

import QtQuick 2.0
import Ubuntu.Components 1.3

Item {
    property string text
    property bool running

    Rectangle {
        anchors.fill: parent
        id: statusBox
        color: "green"
        opacity: 0.25
        radius: units.gu (1)
    }
    Label {
        anchors.verticalCenter: statusBox.verticalCenter
        anchors.left: statusBox.left
        anchors.right: activity.left
        anchors.margins: units.gu (2)
        text: parent.text
    }
    ActivityIndicator {
        id: activity
        anchors.verticalCenter: statusBox.verticalCenter
        anchors.right: statusBox.right
        anchors.margins: units.gu (2)
        running: parent.running
    }
    Behavior on opacity {
        NumberAnimation {
            easing: UbuntuAnimation.StandardEasing
            duration: UbuntuAnimation.FastDuration
        }
    }
}
