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
import chatter 1.0

Page {
    title: conversation.target
    property string pageType: "ConversationPage"
    property PageStack pageStack
    property IRCClient ircClient
    property IRCConversation conversation

    head.actions: [
        Action {
            iconName: "contact"
            onTriggered: {
                if (ircClient._isChannel (conversation.target))
                    pageStack.showUsers (ircClient.url, conversation)
                else
                    pageStack.showUser (ircClient.url, conversation.target)
            }
        }
    ]

    function setTopic (topic) {
        // TRANSLATORS: Topic header (channel page). The %topic is replaced by the topic
        topicLabel.text = i18n.tr ('<font color="grey">Topic: </font><font color="black">%topic</font>').replace ('%topic', escapeText (topic))
    }

    function escapeText (text) {
        // Replace special characters
        text = text.replace ('&', '&amp;').replace ('<', '&lt;').replace ('>', '&gt;')

        // Find URLs
        var urlRegex = /(https?:\/\/[^\s]+)/g;
        text = text.replace (urlRegex, '<a href="$1">$1</a>')

        return text
    }

    Label {
        id: topicLabel
        width: parent.width
        anchors.top: parent.top
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        onLinkActivated: {
            Qt.openUrlExternally (link)
        }
    }

    ListView {
        id: messageView
        width: parent.width
        anchors.top: topicLabel.bottom
        anchors.bottom: chatEntry.top
        verticalLayoutDirection: ListView.BottomToTop
        model: conversation.getMessageModel ()
        delegate: Text {
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            text: {
                if (index < 0)
                    return ''

                var message = messageView.model.get (index)
                function makeNicknameLink (nickname) {
                    return '<a href="user:' + nickname + '">' + nickname + '</a>'
                }
                if (message.type == 'm') {
                    return '<font color="grey">' + makeNicknameLink (message.nickname) + ': </font><font color="black">' + escapeText (message.text) + '</font>'
                }
                else if (message.type == 'a')
                    return '<font color="grey">' + makeNicknameLink (message.nickname) + ' ' + message.text + '</font>'
                else if (message.type == 'ct') {
                    // TRANSLATORS: Text shown when the topic is changed. %1 is replaced with the nickname of the user who changed the topic, %2 is replaced with the new topic.
                    return '<font color="grey">' + i18n.tr ('%1 has changed topic to %2').arg (makeNicknameLink (message.nickname)).arg (message.topic) + '</font>'
                }
                else if (message.type == 'cn') {
                    // TRANSLATORS: Text shown when a nickname is changed. %1 is replaced with the nickname of the user who is changing. %2 is replaced with the new nickname.
                    return '<font color="grey">' + i18n.tr ('%1 is now known as %2').arg (message.oldNickname).arg (makeNicknameLink (message.newNickname)) + '</font>'
                }
                else if (message.type == 'j') {
                    // TRANSLATORS: Text shown when a user joins a channel. %1 is replaced with the nickname of the user.
                    return '<font color="grey">' + i18n.tr ('%1 has joined').arg (makeNicknameLink (message.nickname)) + '</font>'
                }
                else if (message.type == 'p') {
                    // TRANSLATORS: Text shown when a user leaves a channel. %1 is replaced with the nickname of the user. %2 is replaced with the reason.
                    return '<font color="grey">' + i18n.tr ('%1 has left (%2)').arg (makeNicknameLink (message.nickname)).arg (message.message) + '</font>'
                }
                else if (message.type == 'q') {
                    // TRANSLATORS: Text shown when a user quits. %1 is replaced with the nickname of the user.
                    return '<font color="grey">' + i18n.tr ('%1 has quit').arg (message.nickname) + '</font>'
                }
            }
            width: parent.width
            onLinkActivated: {
                if (link.indexOf ('user:') == 0)
                    pageStack.showUser (ircClient.url, link.substring (5))
                else
                    Qt.openUrlExternally (link)
            }
        }
    }

    TextField {
        id: chatEntry
        width: parent.width
        anchors.bottom: parent.bottom
        readOnly: !(ircClient.connected && conversation.joined)
        onAccepted: {
            if (text[0] == '/') {
                var i = text.indexOf (' ')
                var command, args
                if (i < 0) {
                    command = text.slice (1)
                    args = ''
                }
                else {
                    command = text.slice (1, i)
                    args = text.slice (i + 1)
                }
                command = command.toUpperCase ()
                args = args.trim ()
                if (command == 'MSG') {
                    // FIXME: Report errors
                    i = args.indexOf (' ')
                    if (i > 0) {
                        var nickname = args.slice (0, i)
                        var message = args.slice (i + 1).trim ()
                        ircClient.sendMessage (nickname, message)
                    }
                }
                else if (command == 'TOPIC') {
                    ircClient.sendSetTopic (target, args)
                }
                else if (command == 'NICK') {
                    ircClient.sendSetNickname (args)
                }
                else if (command == 'J' || command == 'JOIN') {
                    // FIXME
                }
            }
            else
                ircClient.sendMessageEcho (conversation.target, text)
            text = ''
        }
    }

    StatusBox {
        id: statusBox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu (2)
        height: units.gu (6)
        running: true
        opacity: ircClient.connected && conversation.joined ? 0 : 1
        text: {
            if (ircClient.connected) {
                // TRANSLATORS: Text show when waiting to join a channel. %n is replaced by the channel name
                i18n.tr ('Joining %n...').replace ('%n', conversation.target)
            }
            else {
                // TRANSLATORS: Text show when waiting to connect to server. %n is replaced by the server name
                i18n.tr ('Connecting to %n...').replace ('%n', ircClient.name)
            }
        }
    }
}
