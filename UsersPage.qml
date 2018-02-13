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

Page {
    title: conversation.target
    property PageStack pageStack
    property IRCClient ircClient
    property IRCConversation conversation

    Flickable {
        anchors.fill: parent
        contentHeight: usersColumn.height
        Column {
            id: usersColumn
            width: parent.width
            Repeater {
                model: conversation.getUserModel ()
                ListItem {
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu (1)
                        text: user.nickname
                    }
                    onClicked: pageStack.showUser (ircClient.url, user.nickname)
                }
            }
        }
    }
}
