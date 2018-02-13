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
    id: page
    property int pageNumber
    property Settings settings
    signal done (string nickname, string realName, int serverIndex, string target)

    Component.onCompleted: setPage (0)

    Column {
        id: introductionPage
        anchors.fill: parent
        anchors.margins: units.gu (2)
        spacing: units.gu (2)
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Description of IRC / Chatter (first run wizard)
            text: i18n.tr ("Welcome to Chatter!<br/>\
<br/>\
Chatter is a program that allows you to use an Internet Relay Chat (IRC) network. An IRC network is made up of thousands of users communicating using text in <i>channels</i>. For most networks, anyone can open a channel and the channels are public.<br/>\
<br/>\
For example, you might join the channel #ilovecats:<br/>\
<br/>\
&lt;catlover&gt; You know what I think? Cats are great!<br>&lt;felinefriend&gt; catlover: Me too!<br>&lt;dogsarebest&gt; I think I'm in the wrong channel...")
        }
    }

    Column {
        id: identityPage
        visible: false
        anchors.fill: parent
        anchors.margins: units.gu (2)
        spacing: units.gu (2)
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Instructions on how to pick a nickname (first run wizard)
            text: i18n.tr ("To use IRC, you need to pick a <i>nickname</i> for yourself. It must start with a letter and only contain letters, numbers and the '_' character (a small number of other characters are allowed but are probably not useful<br/>\
<br/>\
Traditionally nicknames are short (not more than nine characters). You can change your nickname at any time.")
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Text above field for entering nickname
            text: i18n.tr ("My nickname is:")
        }
        TextField {
            width: parent.width
            id: nicknameField
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            validator: RegExpValidator { regExp: /[A-Za-z][A-Za-z0-9\[\]\\`_\-^{|}]*/ }
            // TRANSLATORS: Example nickname
            placeholderText: i18n.tr ("chattyman")
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Instructions on how to pick a real name (first run wizard)
            text: i18n.tr ("As well as a nickname, you can set your real name. This is optional, and can be set to whatever you like. You can change your name later if you wish.")
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Text above field for entering real name
            text: i18n.tr ("My real name is:")
        }
        TextField {
            width: parent.width
            id: realNameField
            inputMethodHints: Qt.ImhNoPredictiveText
            // TRANSLATORS: Example real name
            placeholderText: i18n.tr ("Sir Talksalot")
        }
    }

    Column {
        id: serverPage
        visible: false
        anchors.fill: parent
        anchors.margins: units.gu (2)
        spacing: units.gu (2)
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Instructions for picking a channel to use (first run wizard)
            text: i18n.tr ("You know, they say talking to yourself is the first sign of madness... Probably better to find a channel to talk to others on.<br/>\
<br/>\
I've gone ahead an picked #ubuntu on freenode for you. You can chat there about how great your Ubuntu device is. Or perhaps you know a better channel?")
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Text above server selector
            text: i18n.tr ("Connect to the server:")
        }
        ServerSelector {
            id: serverSelector
            width: parent.width
            settings: page.settings
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            // TRANSLATORS: Text above field for entering channel to join
            text: i18n.tr ("Chat on the channel:")
        }
        TextField {
            id: targetField
            width: parent.width
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            // TRANSLATORS: Default IRC channel to connect to on freenode
            text: i18n.tr ("#ubuntu")
        }
    }

    function setPage (number) {
        pageNumber = number
        if (pageNumber == 0) {
            introductionPage.visible = true
            identityPage.visible = false
            serverPage.visible = false
            backButton.visible = false
            // TRANSLATORS: Text on button to switch from IRC description page to picking a nickname (first run wizard)
            continueButton.text = i18n.tr ("OK, I'm in")
        }
        else if (pageNumber == 1) {
            introductionPage.visible = false
            identityPage.visible = true
            serverPage.visible = false
            backButton.visible = true
            // TRANSLATORS: Text on button to return to IRC description page (first run wizard)
            backButton.text = i18n.tr ("What was IRC again?")
            // TRANSLATORS: Text on button to switch from nickname page to picking a channel page (first run wizard)
            continueButton.text = i18n.tr ("That's my real name, honest")
        }
        else if (pageNumber == 2) {
            introductionPage.visible = false
            identityPage.visible = false
            serverPage.visible = true
            backButton.visible = true
            // TRANSLATORS: Text on button to return to nickname page (first run wizard)
            backButton.text = i18n.tr ("Um, I think I spelt my name wrong")
            // TRANSLATORS: Text on button to complete setup (first run wizard)
            continueButton.text = i18n.tr ("Let's talk")
        }
        else {
            done (nicknameField.text, realNameField.text, serverSelector.selectedIndex, targetField.text)
        }
    }

    Button {
        id: backButton
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: continueButton.top
        anchors.margins: units.gu (2)
        onClicked: setPage (pageNumber - 1)
    }

    Button {
        id: continueButton
        enabled: pageNumber == 1 ? nicknameField.text != "" : true
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: units.gu (2)
        color: UbuntuColors.orange
        onClicked: setPage (pageNumber + 1)
    }
}
