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
    // TRANSLATORS: Title of settings page
    title: i18n.tr ("Settings")
    property PageStack pageStack
    property Settings settings

    Column {
        anchors.fill: parent
        anchors.margins: units.gu (2)
        spacing: units.gu (2)
        Label {
            width: parent.width
            // TRANSLATORS: Text above nickname field (settings page)
            text: i18n.tr ("Nickname:")
        }
        TextField {
            width: parent.width
            id: nicknameField
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            validator: RegExpValidator { regExp: /[A-Za-z][A-Za-z0-9\[\]\\`_\-^{|}]*/ }
            text: settings.nickname
            onTextChanged: settings.nickname = text
        }
        Label {
            width: parent.width
            // TRANSLATORS: Text above real name field (settings page)
            text: i18n.tr ("Real Name:")
        }
        TextField {
            width: parent.width
            id: realNameField
            text: settings.realName
            inputMethodHints: Qt.ImhNoPredictiveText
            onTextChanged: settings.realName = text
        }
        Button {
            width: parent.width
            // TRANSLATORS: Text above settings button to configure servers
            text: i18n.tr ("Configure Servers...")
            onClicked: pageStack.configureServers ()
        }
    }
}
