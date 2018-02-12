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
import chatter 1.0

IRCClientNative {
    id: ircClient
    property string name
    property string url
    property string password
    property string nickname
    property string userName
    property string realName
    property var conversations
    property var connected: false
    property int refCount: 0
    signal conversationAdded (string url, string target)
    signal conversationMessage (string url, string target, string text, bool mentions)

    Component.onCompleted: {
        conversations = []
    }

    function start () {
        var tokens = url.split ("://", 2)
        var host = tokens[1]
        var port
        var index = host.indexOf (':')
        if (index > 0) {
            host = tokens[1].slice (0, index)
            port = parseInt (tokens[1].slice (index + 1))
        }
        if (tokens[0] == 'ircs')
            connectToSslServer (host, port == undefined ? 6697 : port)
        else if (tokens[0] == 'irc')
            connectToServer (host, port == undefined ? 6667 : port)
        sendPassword (password == "" ? "*" : password)
        sendSetNickname (nickname)
        sendUserInformation (userName, realName)
    }

    function getConversation (target) {
        var index = _getConversationIndex (target)
        if (index >= 0)
            return conversations[index]
        return addConversation (target)
    }

    function sendMessageEcho (target, text) {
        var c = getConversation (target)
        sendMessage (target, text)
        c.handleMessage (nickname, text)
    }

    function sendCTCPGetVersion (target) {
        sendMessage (target, String.fromCharCode (1) + 'VERSION' + String.fromCharCode (1))
    }

    function addConversation (target) {
        var index = _getConversationIndex (target)
        if (index >= 0)
            return
        var component = Qt.createComponent ('IRCConversation.qml')
        var conversation = component.createObject (this, {'target': target})
        conversations.push (conversation)
        if (_isChannel (target)) {
            if (connected)
                sendJoin (target)
        }
        else
            conversation.joined = true
        conversationAdded (url, conversation.target)
        return conversation
    }

    function removeConversation (target) {
        var index = _getConversationIndex (target)
        if (index >= 0)
            conversations.splice (i, 1)
        if (connected && _isChannel (target))
            sendPart (target)
        conversationRemoved (url, conversation.target)
    }

    function _isChannel (target) {
        return target[0] == '&' || target[0] == '#' || target[0] == '+' || target[0] == '!'
    }

    function _messageMentions (message) {
        function isNicknameCharacter (code) {
            return (code >= 0x41 && code <= 0x5A) ||
                   (code >= 0x61 && code <= 0x7A) ||
                   (code >= 0x30 && code <= 0x39) ||
                   (code >= 0x5B && code <= 0x60) ||
                   (code >= 0x7B && code <= 0x7D)
        }
        function isNickname (message, offset) {
            // Check text is a nickname
            for (var i = 0; i < nickname.length; i++)
                if (message[offset+i] != nickname[i])
                    return false

            // Check character before is not possibly part of a nickname
            if (offset != 0 && isNicknameCharacter (message.charCodeAt (offset - 1)))
                return false

            // Check character after is not possibly part of a nickname
            var endIndex = offset + nickname.length
            if (endIndex < message.length && isNicknameCharacter (message.charCodeAt (endIndex)))
                return false

            return true
        }

        for (var i = 0; i < (message.length - nickname.length + 1); i++)
            if (isNickname (message, i))
                return true;

        return false
    }

    function _getConversationIndex (target) {
        function targetMatches (target1, target2) {
            if (_isChannel (target1))
                return target1.toLowerCase () == target2.toLowerCase ()
            else
                return target1 == target2
        }
        for (var i = 0; i < conversations.length; i++)
            if (targetMatches (conversations[i].target, target))
                return i
        return -1
    }

    function _getNicknameFromPrefix (prefix) {
        return prefix.split ('!')[0]
    }

    function _handleCTCPMessage (sourceNickname, conversationTarget, message, canAutoReply) {
        if (message == 'VERSION') {
            if (canAutoReply)
                sendMessage (sourceNickname, String.fromCharCode (1) + 'VERSION ' + ctcpVersionData () + String.fromCharCode (1), false)
        }
        else if (message.indexOf ('VERSION ') == 0) {
            var user = getUser (sourceNickname)
            user.clientVersion = message.substring (8)
        }
        else if (message.indexOf ('ACTION') == 0) {
            var action = message.substring (6)
            if (action != '') {
                var c = getConversation (conversationTarget)
                c.handleAction (sourceNickname, action)
            }
        }
    }

    onErrNicknameInUseReceived: {
        // Retry with alternative name
        if (!connected) {
            ircClient.nickname += "_"
            sendSetNickname (ircClient.nickname)
        }
    }

    onWelcomeReceived: {
        connected = true
        // Join subscribed channels
        for (var i = 0; i < conversations.length; i++)
            if (_isChannel (conversations[i].target))
                sendJoin (conversations[i].target)
    }

    onDisconnected: {
        console.log ("CLOSED")
        connected = false
        // Try and reconnect
        // FIXME: Should do some sort of expoential backoff so don't try too much
        start ()
    }

    onCommandReceived: {
        console.log (url + " > " + prefix, command, params)
    }

    onCommandSent: {
        if (command == "PASS")
            console.log (url + " < " + command, "(hidden)")
        else
            console.log (url + " < " + command, params)
    }

    onNicknameChangedReceived: {
        var oldNickname = _getNicknameFromPrefix (prefix)
        changeNickname (oldNickname, nickname);
        for (var i = 0; i < conversations.length; i++)
            conversations[i].handleChangeNickname (oldNickname, nickname)
    }

    onQuitReceived: {
        var nickname = _getNicknameFromPrefix (prefix)
        for (var i = 0; i < conversations.length; i++)
            conversations[i].handleQuit (nickname)
    }

    onJoinReceived: {
        var c = getConversation (channel)
        c.handleJoin (getUser (_getNicknameFromPrefix (prefix)))
    }

    onPartReceived: {
        var c = getConversation (channel)
        c.handlePart (_getNicknameFromPrefix (prefix), message)
    }

    onSetTopicReceived: {
        var c = getConversation (channel)
        c.topic = topic
        c.handleChangeTopic (_getNicknameFromPrefix (prefix), topic)
    }

    onMessageReceived: {
        var sourceNickname = _getNicknameFromPrefix (prefix)
        var conversationTarget = target == nickname ? sourceNickname : target
        
        // Skip server messages - should probably collect these for something else
        if (target == "*")
            return

        // Extract Client To Client Protocol (CTCP) messages
        while (true) {
            var startIndex = text.indexOf (String.fromCharCode (1))
            if (startIndex < 0)
                break
            var endIndex = text.indexOf (String.fromCharCode (1), startIndex + 1)
            var start = text.substring (0, startIndex)
            _handleCTCPMessage (sourceNickname, conversationTarget, text.substring (startIndex + 1, endIndex < 0 ? text.length : endIndex), canAutoReply)
            var end = endIndex < 0 ? "" : text.substring (endIndex + 1)
            text = start + end
        }

        if (text != "") {
            var c = getConversation (conversationTarget)
            c.handleMessage (sourceNickname, text)
            conversationMessage (url, conversationTarget, text, _isChannel (conversationTarget) ? _messageMentions (text) : true)
        }
    }

    onPingReceived: {
        sendPong (server1);
    }

    onUserInfoReceived: {
        var user = getUser (nickname)
        user.username = username
        user.hostname = hostname
        user.realName = realName
    }

    onGetTopicReplyReceived: {
        var c = getConversation (channel)
        c.topic = topic
    }

    onGetNamesReplyReceived: {
        var users = []
        for (var i = 0; i < nicknames.length; i++) {
            var nickname = nicknames[i]
            // Skip channel operator or moderated flag
            if (nickname[0] == '@' || nickname[0] == '+')
                nickname = nickname.substring (1)
            var user = getUser (nickname)
            users.push (user)
        }

        var c = getConversation (channel)
        c.handleUsers (users)
    }

    onGetNamesReplyEndReceived: {
        var c = getConversation (channel)
        c.joined = true
    }
}
