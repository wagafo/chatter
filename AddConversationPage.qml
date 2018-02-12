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
    id: page
    // TRANSLATORS: Title of add conversation page
    title: i18n.tr ("Add Conversation")
    property PageStack pageStack
    property Settings settings

    Column {
        anchors.fill: parent
        anchors.margins: units.gu (2)
        spacing: units.gu (2)
        Label {
            width: parent.width
            // TRANSLATORS: Text above server selector (join channel page)
            text: i18n.tr ("Server:")
        }
        ServerSelector {
            id: serverSelector
            width: parent.width
            settings: page.settings
        }
        Label {
            width: parent.width
            // TRANSLATORS: Text above channel / nickname field (join channel page)
            text: i18n.tr ("Channel / Nickname:")
        }
        TextField {
            id: targetField
            width: parent.width
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            text: "#"
        }
        Label {
            id: errorLabel
            visible: false
            width: parent.width
        }
        Button {
            width: parent.width
            // TRANSLATORS: Text on button to start a new conversation (add conversation page)
            text: i18n.tr ("Let's chat")
            enabled: targetField.text != "" && targetField.text != "#"
            onClicked: {
                settings.addConversation (settings.serverModel.get (serverSelector.selectedIndex).url, targetField.text)
                pageStack.pop ()
            }
        }
    }
}
