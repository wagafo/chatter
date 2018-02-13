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

MainView {
    applicationName: "chatter.ruben-carneiro"
    anchorToKeyboard: !welcomeLoader.visible

    width: units.gu (40)
    height: units.gu (71)

    property var ircClients

    Component.onCompleted: {
        ircClients = {}
        settings.load ()
        if (settings.nickname == "") {
            welcomeLoader.visible = true
            welcomeLoader.setSource ("WelcomePage.qml", {"settings": settings})
        }
        else
            pageStack.push (homePage)
    }

    Settings {
        id: settings
        onConversationAdded: {
            var client = getClient (url)
            client.addConversation (target)
        }
        onConversationRemoved: {
            var client = getClient (url)
            if (client != undefined) {
                client.removeConversation (target)

                // Close this client if nothing using it now
                var useCount = 0
                for (var i = 0; i < settings.conversationModel.count; i++) {
                    if (settings.conversationModel.get (i).url == conversation.url)
                    useCount++
                }
                if (useCount == 0) {
                    ircClients[client.url].disconnectFromServer ()
                    // disconnect signals?
                    delete ircClients[client.url]
                }
            }
        }
    }

    function getClient (url) {
        var client = ircClients[url]
        if (client != undefined)
            return client

        var serverSettings = settings.getServerSettings (url)
        if (serverSettings == undefined)
            return undefined

        var component = Qt.createComponent ("IRCClient.qml")
        var nickname = serverSettings.nickname
        if (nickname == "")
            nickname = settings.nickname
        var realName = serverSettings.realName
        if (realName == "")
            realName = settings.realName
        if (realName == "")
            realName = "*"
        client = component.createObject (this, {"url": url, "password": serverSettings.password, "nickname": nickname, "userName": "chatter", "realName": realName})
        client.name = serverSettings.name
        client.conversationAdded.connect (handleConversationAdded)
        client.conversationMessage.connect (handleConversationMessage)
        ircClients[url] = client
        for (var i = 0; i < settings.conversationModel.count; i++) {
            var conversation = settings.conversationModel.get (i)
            if (conversation.url == url)
                client.addConversation (conversation.target)
        }
        client.start ()

        return client
    }

    function handleConversationAdded (url, target) {
        var config = settings.getConversation (url, target)
        if (config == undefined)
            config = settings.addConversation (url, target)
    }

    function handleConversationMessage (url, target, text, mentions) {
        var config = settings.getConversation (url, target)
        if (config == undefined)
            return

        // Don't update when viewing this page
        if (pageStack.currentPage.pageType == "ConversationPage" && pageStack.currentPage.ircClient.url == url)
            return

        config.messageCount++
        if (mentions)
            config.mentioned = true
    }

    Loader {
        id: welcomeLoader
        anchors.fill: parent
        visible: false
        Connections {
            target: welcomeLoader.item
            onDone: {
                settings.nickname = nickname
                settings.realName = realName
                if (target != "")
                    settings.addConversation (settings.serverModel.get (serverIndex).url, target)
                welcomeLoader.visible = false
                pageStack.push (homePage)
            }
        }
    }

    PageStack {
        id: pageStack

        function openPage (url, target) {
            // FIXME: Check for existing
            var ircClient = getClient (url)
            var conversation = ircClient.getConversation (target)
            var page = pageStack.push (Qt.resolvedUrl ("ConversationPage.qml"), {"pageStack": pageStack, "ircClient": ircClient, "conversation": conversation })
            settings.getConversation (url, target).messageCount = 0
        }

        function configureServers () {
            pageStack.push (Qt.resolvedUrl ("ConfigureServersPage.qml"), {"pageStack": pageStack, "settings": settings })
        }

        function addServer (index) {
            pageStack.push (Qt.resolvedUrl ("ServerPage.qml"), {"pageStack": pageStack, "settings": settings })
        }

        function configureServer (server) {
            pageStack.push (Qt.resolvedUrl ("ServerPage.qml"), {"pageStack": pageStack, "settings": settings, "server": server})
        }

        function showConversation (conversation) {
            pageStack.openPage (conversation.url, conversation.target)
        }

        function showUsers (url, conversation) {
            var ircClient = getClient (url)
            var page = pageStack.push (Qt.resolvedUrl ("UsersPage.qml"), {"pageStack": pageStack, "ircClient": ircClient, "conversation": conversation })
        }

        function showUser (url, nickname) {
            var ircClient = getClient (url)
            ircClient.sendGetUserInfo (nickname)
            ircClient.sendCTCPGetVersion (nickname)
            var page = pageStack.push (Qt.resolvedUrl ("UserPage.qml"), {"nickname": nickname, "ircClient": ircClient })
        }

        Page {
            id: homePage
            visible: false
            // TRANSLATORS: Title of application page
            title: i18n.tr ("Chatter")

            head.actions: [
                Action {
                    iconName: "add"
                    onTriggered: pageStack.push (Qt.resolvedUrl ("AddConversationPage.qml"), {"pageStack": pageStack, "settings": settings })
                },
                Action {
                    iconName: "settings"
                    onTriggered: pageStack.push (Qt.resolvedUrl ("SettingsPage.qml"), {"pageStack": pageStack, "settings": settings})
                }
            ]

            Flickable {
                anchors.fill: parent
                contentHeight: conversationColumn.height
                Column {
                    id: conversationColumn
                    width: parent.width
                    Repeater {
                        model: settings.conversationModel
                        ConversationItem {
                            title: target
                            onClicked: pageStack.showConversation (settings.conversationModel.get (index))
                            onDeleteConversation: settings.removeConversation (index)
                            messageCount: index < 0 ? 0 : settings.conversationModel.get (index).messageCount
                            mentioned: index < 0 ? false : settings.conversationModel.get (index).mentioned
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: settings.conversationModel.count == 0
                // TRANSLATORS: Placeholder text when no channels subscribed to
                text: i18n.tr ("You are not currently subscribed to any channels")
            }
        }
    }
}
