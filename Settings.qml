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
import QtQuick.LocalStorage 2.0

Item {
    property string nickname
    property string realName
    property ListModel serverModel: serverModel
    property ListModel conversationModel: conversationModel
    property bool ready: false

    signal conversationAdded (string url, string target)
    signal conversationRemoved (string url, string target)

    function load () {
        var db = get_database ()
        try {
            db.transaction (function (t) {
                var result = t.executeSql ("SELECT nickname, realName FROM Settings")
                var row = result.rows.item (0)
                nickname = row.nickname
                realName = row.realName
            })
        }
        catch (e) {
        }
        var loadedServers = false
        try {
            db.transaction (function (t) {
                var result = t.executeSql ("SELECT url, name, password, nickname, userName, realName FROM Servers")
                for (var i = 0; i < result.rows.length; i++) {
                    var row = result.rows.item (i)
                    function string_value (value) {
                        return value == null ? '' : value
                    }
                    addServer (row.url, row.name, string_value (row.password), string_value (row.nickname), string_value (row.userName), string_value (row.realName))
                }
            })
            loadedServers = true
        }
        catch (e) {
        }
        try {
            db.transaction (function (t) {
                var result = t.executeSql ("SELECT target, url FROM Channels")
                for (var i = 0; i < result.rows.length; i++) {
                    var row = result.rows.item (i)
                    addConversation (row.url, row.target)
                }
            })
        }
        catch (e) {
        }
        ready = true

        // Add some default servers
        if (!loadedServers) {
            addServer ("ircs://irc.freenode.net", "freenode", "", "", "", "")
            addServer ("ircs://irc.gimp.org", "GIMPNet", "", "", "", "")
            addServer ("ircs://irc.oftc.net", "OFTC", "", "", "", "")            
        }
    }

    onNicknameChanged: if (ready) saveSettings ()
    onRealNameChanged: if (ready) saveSettings ()
    function saveSettings () {
        get_database ().transaction (function (t) {
            // The lock field is to ensure the INSERT will always replace this row instead of adding another
            t.executeSql ("CREATE TABLE IF NOT EXISTS Settings(lock INTEGER, nickname STRING, realName STRING, PRIMARY KEY (lock))");
            t.executeSql ("INSERT OR REPLACE INTO Settings VALUES(0, ?, ?)", [nickname, realName])
        })
    }

    ListModel {
        id: serverModel
    }

    function getServerIndex (url) {
        for (var i = 0; i < serverModel.count; i++) {
            var server = serverModel.get (i)
            if (server.url == url)
                return i
        }
    }

    function getServerSettings (url) {
        for (var i = 0; i < serverModel.count; i++) {
            var server = serverModel.get (i)
            if (server.url == url)
                return server
        }
    }

    function addServer (url, name, password, nickname, userName, realName) {
        // FIXME: Check name collision
        var values = {"url": url, "name": name, "password": password, "nickname": nickname, "userName": userName, "realName": realName}
        serverModel.append (values)
        if (ready) {
            get_database ().transaction (function (t) {
                t.executeSql ("CREATE TABLE IF NOT EXISTS Servers(name STRING, url STRING, password STRING, nickname STRING, userName STRING, realName STRING)");
                t.executeSql ("INSERT INTO Servers VALUES (?, ?, ?, ?, ?, ?)", [name, url, password, nickname, userName, realName])
            })
        }
    }

    function updateServer (url, name, password, nickname, userName, realName) {
        var index = getServerIndex (url)
        var values = {"name": name, "password": password, "nickname": nickname, "userName": userName, "realName": realName}
        if (index != undefined)
            serverModel.set (index, values)
        get_database ().transaction (function (t) {
            t.executeSql ("UPDATE Servers SET name = ?, password = ?, nickname = ?, userName = ?, realName = ? WHERE url = ?", [name, password, nickname, userName, realName, url])
        })
    }

    function removeServer (url) {
        // Remove any conversations that use this server
        function matchingConversation (url) {
            for (var i = 0; i < conversationModel.count; i++) {
                var channel = conversationModel.get (i)
                if (channel.url == url)
                    return i
            }
        }
        while (true) {
            var i = matchingConversation (url)
            if (i == undefined)
                break
            removeConversation (i)
        }

        try {
            get_database ().transaction (function (t) {
                t.executeSql ("DELETE FROM servers WHERE url=?", [url])
            })
        }
        catch (e) {
        }
        var index = getServerIndex (url)
        if (index != undefined)
            serverModel.remove (index)
    }

    ListModel {
        id: conversationModel
    }

    function getConversation (url, target) {
        for (var i = 0; i < conversationModel.count; i++) {
            var channel = conversationModel.get (i)
            // FIXME: Copied from IRCClient.qml
            function isChannel (target) {
                return target[0] == '&' || target[0] == '#' || target[0] == '+' || target[0] == '!'
            }
            function targetMatches (target1, target2) {
                if (isChannel (target1))
                    return target1.toLowerCase () == target2.toLowerCase ()
                else
                    return target1 == target2
            }
            if (channel.url == url && targetMatches (channel.target, target))
                return channel
        }
    }

    function addConversation (url, target) {
        var conversation = conversationModel.insert (0, {"url": url, "target": target, "messageCount": 0, "mentioned": false })
        if (ready) {
            get_database ().transaction (function (t) {
                t.executeSql ("CREATE TABLE IF NOT EXISTS Channels(target STRING, url STRING)");
                t.executeSql ("INSERT INTO Channels VALUES (?, ?)", [target, url])
            })
        }
        conversationAdded (url, target)
        return conversation
    }

    function removeConversation (index) {
        var conversation = conversationModel.get (index)
        try {
            get_database ().transaction (function (t) {
                t.executeSql ("DELETE FROM Channels WHERE target=? AND url=? ", [conversation.target, conversation.url])
            })
        }
        catch (e) {
        }
        conversationModel.remove (index)
        conversationRemoved (conversation.url, conversation.target)
    }

    function get_database () {
        return LocalStorage.openDatabaseSync ("settings", "1", "Chatter Settings", 0)
    }
}
