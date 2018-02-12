/*
 * Copyright (C) 2016 Robert Ancell <robert.ancell@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

import QtQuick 2.0
import Ubuntu.Components 1.3

Page {
    title: nickname
    property IRCClient ircClient
    property string nickname
    property var user: ircClient.getUser (nickname)

    Column {
        anchors.fill: parent
        anchors.margins: units.gu (2)
        spacing: units.gu (2)
        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "contact"
            width: units.gu (6)
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            fontSize: "large"
            text: nickname
        }
        Label {
            visible: user.realName != ''
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: user.realName
        }
        Label {
            visible: user.username != '' && user.hostname != ''
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: user.username + "@" + user.hostname
        }
        Label {
            visible: user.clientVersion != ''
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: user.clientVersion
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: false
            text: "Private Conversation"
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: false
            text: "Kick from ?"
        }
    }
}
