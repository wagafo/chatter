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
    // TRANSLATORS: Title of configure servers page
    title: i18n.tr ("IRC Servers")
    property var pageStack
    property Settings settings

    head.actions: [
        Action {
            iconName: "add"
            onTriggered: pageStack.addServer ()
        }
    ]

    Column {
        anchors.fill: parent
        Repeater {
            model: settings.serverModel
            ListItem {
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu (1)
                    text: name
                }
                onClicked: pageStack.configureServer (settings.serverModel.get (index))
            }
        }
    }
}
