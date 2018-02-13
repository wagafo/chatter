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

ListItem {
    property string title
    property int messageCount: 0
    property bool mentioned
    signal deleteConversation ()

    leadingActions: ListItemActions {
        actions: [
        Action {
            iconName: "delete"
            onTriggered: deleteConversation ()
        }]
    }
    Label {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.margins: units.gu (2)
        text: title
        fontSize: "large"
    }
    Rectangle {
        visible: messageCount > 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: (parent.height - height) * 0.5
        height: parent.height * 0.5
        width: height
        radius: height * 0.5
        color: mentioned ? UbuntuColors.red : UbuntuColors.lightGrey
        Label {
            anchors.centerIn: parent
            text: messageCount
            color: mentioned ? "white" : "black"
        }
    }
}
