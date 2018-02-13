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

Item {
    property string target
    property string topic: ""
    property bool joined

    ListModel {
        id: userModel
    }

    function getUserModel () {
        return userModel
    }

    ListModel {
        id: messageModel
    }

    function getMessageModel () {
        return messageModel
    }

    function _getUserIndex (nickname) {
        for (var i = 0; i < userModel.count; i++)
            if (userModel.get (i).user.nickname == nickname)
                return i;
        return -1
    }

    function handleUsers (users) {
        for (var i = 0; i < users.length; i++)
            if (_getUserIndex (users[i].nickname) < 0)
                userModel.append ({"user": users[i]})
    }

    function handleMessage (nickname, text) {
        messageModel.insert (0, {'type': 'm', 'nickname': nickname, 'text': text})
    }
    function handleAction (nickname, text) {
        messageModel.insert (0, {'type': 'a', 'nickname': nickname, 'text': text})
    }
    function handleChangeTopic (nickname, topic) {
        messageModel.insert (0, {'type': 'ct', 'nickname': nickname, 'topic': topic})
    }
    function handleChangeNickname (oldNickname, newNickname) {
        var index = _getUserIndex (nickname)
        if (index < 0)
            return
        messageModel.insert (0, {'type': 'cn', 'oldNickname': oldNickname, 'newNickname': newNickname})
    }
    function handleJoin (user) {
        if (_getUserIndex (user.nickname) >= 0)
            return
        userModel.append ({"user": user})
        messageModel.insert (0, {'type': 'j', 'nickname': user.nickname})
    }
    function handlePart (nickname, message) {
        var index = _getUserIndex (nickname)
        if (index < 0)
            return
        userModel.remove (index)
        messageModel.insert (0, {'type': 'p', 'nickname': nickname, 'message': message})
    }
    function handleQuit (nickname) {
        var index = _getUserIndex (nickname)
        if (index < 0)
            return
        userModel.remove (index)
        messageModel.insert (0, {'type': 'q', 'nickname': nickname})
    }
}
