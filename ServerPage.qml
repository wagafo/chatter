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
    // TRANSLATORS: Title of configuration page for new server (i.e. no name yet entered)
    title: nameField.text == "" ? i18n.tr ("Unnamed Server") : nameField.text
    property Settings settings
    property var server
    property bool loaded: false

    Component.onCompleted: {
        loaded = true
    }

    function updateServer ()
    {
        if (!loaded)
            return
        if (server != undefined)
            settings.updateServer (server.url, nameField.text, passwordField.text, nicknameField.text, "", realNameField.text)
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: units.gu (2)
        contentHeight: settingsColumn.height
        Column {
            id: settingsColumn
            width: parent.width
            spacing: units.gu (2)
            Label {
                width: parent.width
                // TRANSLATORS: Text above server name field (server configuration page)
                text: i18n.tr ("Name:")
            }
            TextField {
                width: parent.width
                id: nameField
                inputMethodHints: Qt.ImhNoPredictiveText
                text: server == undefined ? "" : server.name
                onTextChanged: updateServer ()
            }
            Label {
                width: parent.width
                // TRANSLATORS: Text above server URL field (server configuration page)
                text: i18n.tr ("URL:")
            }
            TextField {
                width: parent.width
                id: urlField
                readOnly: server != undefined
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                text: server == undefined ? "ircs://" : server.url
            }
            Label {
                width: parent.width
                visible: server == undefined
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                // TRANSLATORS: Text describing IRC URLs
                text: i18n.tr ("IRC URLs are in the form:<br/>\
ircs://<i>host</i>[:<i>port</i>] (secure connections)<br/>\
irc://<i>host</i>[:<i>port</i>] (insecure connections)<br/>\
<br/>\
The port is optional and will default to 6697 for secure connections and 6667 for insecure connections.<br/>\
<br/>\
For example, ircs://irc.freenode.net is the URL for the freenode server.")
            }
            Label {
                width: parent.width
                // TRANSLATORS: Text above server password field (server configuration page)
                text: i18n.tr ("Server password (optional):")
            }
            TextField {
                width: parent.width
                id: passwordField
                echoMode: showPasswordCheck.checked ? TextInput.Normal : TextInput.PasswordEchoOnEdit
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                text: server == undefined ? "" : server.password
                onTextChanged: updateServer ()
            }
            Row {
                width: parent.width
                spacing: units.gu (1)
                CheckBox {
                    id: showPasswordCheck
                }
                Label {
                    // TRANSLATORS: Label beside checkbox that makes the server password visible (server configuration page)
                    text: i18n.tr ("Show password")
                }
            }
            Label {
                width: parent.width
                // TRANSLATORS: Text above server nickname fields (server configuration page)
                text: i18n.tr ("Nickname:")
            }
            TextField {
                width: parent.width
                id: nicknameField
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                placeholderText: settings.nickname
                text: server == undefined ? "" : server.nickname
                onTextChanged: updateServer ()
            }
            Label {
                width: parent.width
                // TRANSLATORS: Text above server nickname fields (server configuration page)
                text: i18n.tr ("Real name:")
            }
            TextField {
                width: parent.width
                id: realNameField
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                placeholderText: settings.realName
                text: server == undefined ? "" : server.realName
                onTextChanged: updateServer ()
            }
            Button {
                width: parent.width
                visible: server == undefined
                enabled: nameField.text != ""
                // TRANSLATORS: Text on button to add a new server (server configuration page)
                text: i18n.tr ("Add Server")
                onClicked: {
                    settings.addServer (urlField.text, nameField.text, passwordField.text, nicknameField.text, "", realNameField.text)
                    pageStack.pop ()
                }
            }
            Button {
                width: parent.width
                visible: server != undefined
                // TRANSLATORS: Text on button to delete selected server
                text: i18n.tr ("Delete Server")
                color: "red"
                onClicked: {
                    // FIXME: Warn user if we had open conversations
                    settings.removeServer (server.url)
                    pageStack.pop ()
                }
            }
        }
    }
}
