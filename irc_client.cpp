/*
 * Copyright (C) 2016 Robert Ancell <robert.ancell@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

#include <QSslSocket>
#include <QSysInfo>

#include "irc_client.h"
#include "version.h"

QString IRCClient::ctcpVersionData ()
{
    return "Chatter " + QString (VERSION) + " (" + QSysInfo::prettyProductName () + ")";
}

void IRCClient::connectToServer (const QString& host, quint16 port)
{
    socket = new QTcpSocket (this);
    connect (socket, SIGNAL (readyRead()), this, SLOT (readData()));
    connect (socket, SIGNAL (disconnected()), this, SLOT (handleDisconnected()));  
    void (QAbstractSocket:: *sig)(QAbstractSocket::SocketError) = &QAbstractSocket::error;
    connect (socket, sig, this, &IRCClient::handleError);
    socket->connectToHost (host, port);
}

void IRCClient::connectToSslServer (const QString& host, quint16 port)
{
    QSslSocket *sslSocket = new QSslSocket (this);
    socket = sslSocket;
    connect (sslSocket, SIGNAL (readyRead()), this, SLOT (readData()));
    connect (sslSocket, SIGNAL (disconnected()), this, SLOT (handleDisconnected()));  
    void (QAbstractSocket:: *sig)(QAbstractSocket::SocketError) = &QAbstractSocket::error;
    connect (sslSocket, sig, this, &IRCClient::handleError);
    sslSocket->connectToHostEncrypted (host, port);
}

void IRCClient::disconnectFromServer ()
{
    socket->disconnectFromHost ();
}

void IRCClient::readData ()
{
    QByteArray data = socket->readAll ();
    read_buffer.append (data);

    while (true) {
        // Extract a line
        int index = read_buffer.indexOf ("\r\n");
        if (index < 0)
            break;
        QByteArray line = read_buffer.left (index);
        read_buffer.remove (0, index + 2);

        // Empty messages can be ignored
        if (line.isEmpty ())
            continue;

        // Extract optional prefix
        QString prefix;
        if (line[0] == ':') {
            index = line.indexOf (' ');
            if (index > 0) {
                prefix = line.mid (1, index - 1);
                line.remove (0, index + 1);
            }
            else {
                prefix = line;
                line.clear ();
            }
        }

        // Extract command
        QString command;
        index = line.indexOf (' ');
        if (index > 0) {
            command = line.left (index);
            line.remove (0, index + 1);
        }
        else {
            command = line;
            line.clear ();
        }

        // Parameters separated by spaces, except for the last one that starts with ':' which stops at the end of the line
        QStringList params;
        while (!line.isEmpty ()) {
            index = line.indexOf (' ');
            if (line[0] == ':') {
                params.append (line.right (line.size () - 1));
                line.clear ();
            }
            else if (index < 0) {
                params.append (line);
                line.clear ();
            }
            else {
                params.append (line.left (index));
                line.remove (0, index + 1);
            }
        }

        emit commandReceived (prefix, command, params);

        if (command == "NICK") {
            if (params.size () == 1)
                emit nicknameChangedReceived (prefix, params[0]);
        }
        else if (command == "QUIT") {
            if (params.size () == 1)
                emit quitReceived (prefix, params[0]);
        }
        else if (command == "JOIN") {
            if (params.size () == 1)
                emit joinReceived (prefix, params[0]);
        }
        else if (command == "PART") {
            if (params.size () == 2)
                emit partReceived (prefix, params[0], params[1]);
        }
        else if (command == "TOPIC") {
            if (params.size () == 2)
                emit setTopicReceived (prefix, params[0], params[1]);
        }
        else if (command == "PRIVMSG") {
            if (params.size () == 2)
                emit messageReceived (prefix, params[0], params[1], true);
        }
        else if (command == "NOTICE") {
            if (params.size () == 2)
                emit messageReceived (prefix, params[0], params[1], false);
        }
        else if (command == "KILL") {
            if (params.size () == 2)
                emit killReceived (prefix, params[0], params[1]);
        }
        else if (command == "PING") {
            if (params.size () == 1)
                emit pingReceived (prefix, params[0], QString ());
            else if (params.size () == 2)
                emit pingReceived (prefix, params[0], params[1]);
        }
        else if (command == "PONG") {
            if (params.size () == 1)
                emit pongReceived (prefix, params[0], QString ());
            else if (params.size () == 2)
                emit pongReceived (prefix, params[0], params[1]);
        }
        else if (command == "ERROR") {
            if (params.size () == 1)
                emit errorReceived (prefix, params[0]);
        }
        else if (command == "001") {
            // NOTE: We allow the incorrect number of arguments to work with the broken Slack IRC gateway
            // https://bugs.launchpad.net/bugs/1588046
            if (params.size () >= 2)
                emit welcomeReceived (prefix, params[0], params[1]);
        }
        else if (command == "311") {
            if (params.size () == 6)
                emit userInfoReceived (prefix, params[1], params[2], params[3], params[5]);
        }
        else if (command == "332") {
            if (params.size () == 3)
                emit getTopicReplyReceived (prefix, params[1], params[2]);
        }
        else if (command == "353") {
            if (params.size () == 4)
                emit getNamesReplyReceived (prefix, params[0], params[1], params[2], params[3].split (" ", QString::SkipEmptyParts));
        }
        else if (command == "366") {
            if (params.size () == 3)
                emit getNamesReplyEndReceived (prefix, params[0], params[1], params[2]);
        }
        else if (command == "433") {
            if (params.size () == 3)
                emit errNicknameInUseReceived (prefix, params[0], params[1], params[2]);
        }
    }
}

void IRCClient::handleDisconnected ()
{
    qDebug () << "DISCONNECTED";
    emit disconnected ();
}

void IRCClient::handleError (QAbstractSocket::SocketError socketError)
{
    qDebug () << "ERROR << " << socketError;
}

void IRCClient::sendCommand (const QString& command, const QStringList& parameters)
{
    QByteArray data;
    data.append (command);
    for (int i = 0; i < parameters.size (); i++) {
        data.append (" ");
        data.append (parameters.at (i));
    }
    data.append ("\r\n");
    socket->write (data);
    emit commandSent (command, parameters);
}

void IRCClient::sendCommand (const QString& command, const QString& parameter)
{
    sendCommand (command, QStringList (parameter));
}

void IRCClient::sendCommand (const QString& command)
{
    sendCommand (command, QStringList ());
}

void IRCClient::sendPassword (const QString& password)
{
    // assert !password.isEmpty
    sendCommand ("PASS", password);
}

void IRCClient::sendSetNickname (const QString& nickname)
{
    // assert !nickname.isEmpty
    sendCommand ("NICK", nickname);
}

void IRCClient::sendUserInformation (const QString& userName, bool receiveWallops, bool isInvisible, const QString& realName)
{
    int mode_value = 0;
    if (receiveWallops)
        mode_value |= (1 << 2);
    if (isInvisible)
        mode_value |= (1 << 3);
    sendCommand ("USER", QStringList () << userName << QString::number (mode_value) << "*" << (":" + realName));
}

void IRCClient::sendUserInformation (const QString& userName, const QString& realName)
{
    sendUserInformation (userName, false, false, realName);
}

void IRCClient::sendSetOperator (const QString& userName, const QString& password)
{
    sendCommand ("OPER", QStringList () << userName << password);
}

void IRCClient::sendSetUserMode (const QString& nickname, UserMode mode)
{
    QStringList parameters (nickname);
    // FIXME: Check conflicting options?
    if ((mode & UserMode::Away) != 0)
        parameters.append (" +a");
    else if ((mode & UserMode::Present) != 0)
        parameters.append (" -a");
    if ((mode & UserMode::Invisible) != 0)
        parameters.append (" +i");
    else if ((mode & UserMode::Visible) != 0)
        parameters.append (" -i");
    if ((mode & UserMode::ReceiveWallops) != 0)
        parameters.append (" +w");
    else if ((mode & UserMode::IgnoreWallops) != 0)
        parameters.append (" -w");
    if ((mode & UserMode::DropOperator) != 0)
        parameters.append (" -o");
    if ((mode & UserMode::DropLocalOperator) != 0)
        parameters.append (" -O");
    sendCommand ("MODE", parameters);
}

void IRCClient::sendRegisterService (const QString& nickname, const QString& distribution, const QString& info)
{
    sendCommand ("SERVICE", QStringList () << nickname << "*" << distribution << "0" << "0" << (":" + info));
}

void IRCClient::sendQuit (const QString& message)
{
     sendCommand ("QUIT", ":" + message);
}

void IRCClient::sendQuit ()
{
    sendCommand ("QUIT");
}

void IRCClient::sendServerQuit (const QString& server, const QString& comment)
{
    sendCommand ("SQUIT", QStringList () << server << (":" + comment));
}

void IRCClient::sendJoin (const QStringList& channels) // FIXME: keys
{
    sendCommand ("JOIN", channels.join (","));
}

void IRCClient::sendJoin (const QString& channel)
{
    sendCommand ("JOIN", channel);
}

void IRCClient::sendPart (const QStringList& channels, const QString& message)
{
    sendCommand ("PART", QStringList () << channels.join (",") << (":" + message));  
}

void IRCClient::sendPart (const QString& channel, const QString& message)
{
    sendCommand ("PART", QStringList () << channel << (":" + message));    
}

void IRCClient::sendPart (const QStringList& channels)
{
    sendCommand ("PART", channels.join (","));
}

void IRCClient::sendPart (const QString& channel)
{
    sendCommand ("PART", channel);
}

void IRCClient::sendPartAll ()
{
    sendCommand ("JOIN", "0");
}

void IRCClient::sendSetChannelMode (const QString& channel)
{
    // FIXME
}

void IRCClient::sendSetTopic (const QString& channel, const QString& topic)
{
    sendCommand ("TOPIC", QStringList () << channel << (":" + topic));
}

void IRCClient::sendGetTopic (const QString& channel)
{
    sendCommand ("TOPIC", channel);
}

void IRCClient::sendGetNames (const QStringList& channels, const QString& target)
{
    sendCommand ("NAMES", QStringList () << channels.join (",") << target);
}

void IRCClient::sendGetNames (const QStringList& channels)
{
    sendCommand ("NAMES", channels.join (","));
}

void IRCClient::sendListChannels (const QStringList& channels, const QString& target)
{
    sendCommand ("LIST", QStringList () << channels.join (",") << target);
}

void IRCClient::sendListChannels (const QStringList& channels)
{
    sendCommand ("LIST", channels.join (","));
}

void IRCClient::sendListChannels ()
{
    sendCommand ("LIST");
}

void IRCClient::sendListChannel (const QString& channel, const QString& target)
{
    sendListChannels (QStringList () << channel, target);
}

void IRCClient::sendListChannel (const QString& channel)
{
    sendListChannel (channel, QString ());
}

void IRCClient::sendInvite (const QString& nickname, const QString& channel)
{
    sendCommand ("INVITE", QStringList () << nickname << channel);
}

void IRCClient::sendKick (const QStringList& channels, const QStringList& usernames, const QString& comment)
{
    sendCommand ("KICK", QStringList () << channels.join (",") << usernames.join (",") << (":" + comment));
}

void IRCClient::sendKick (const QStringList& channels, const QStringList& usernames)
{
    sendCommand ("KICK", QStringList () << channels.join (",") << usernames.join (","));
}

void IRCClient::sendKick (const QString& channel, const QString& username, const QString& comment)
{
    sendKick (QStringList (channel), QStringList (username), comment);
}

void IRCClient::sendKick (const QString& channel, const QString& username)
{
    sendKick (QStringList (channel), QStringList (username));
}

void IRCClient::sendMessage (const QString& target, const QString& text, bool canAutoReply)
{
    if (canAutoReply)
        sendCommand ("PRIVMSG", QStringList () << target << (":" + text));
    else
        sendCommand ("NOTICE", QStringList () << target << (":" + text));  
}

void IRCClient::sendMessage (const QString& target, const QString& text)
{
    sendCommand ("PRIVMSG", QStringList () << target << (":" + text));  
}

void IRCClient::sendGetMOTD (const QString& target)
{
    sendCommand ("MOTD", target);  
}

void IRCClient::sendGetMOTD ()
{
    sendCommand ("MOTD");
}

void IRCClient::sendGetUsers (const QString& target)
{
    sendCommand ("USERS", target);
}

void IRCClient::sendGetUsers ()
{
    sendCommand ("USERS");
}

void IRCClient::sendGetVersion (const QString& target)
{
    sendCommand ("VERSION", target);
}

void IRCClient::sendGetVersion ()
{
    sendCommand ("VERSION");
}

void IRCClient::sendGetStats (const QString& query, const QString& target)
{
    sendCommand ("STATS", QStringList () << query << target);
}

void IRCClient::sendGetStats (const QString& query)
{
    sendCommand ("STATS", query);
}

void IRCClient::sendGetStats ()
{
    sendCommand ("STATS");  
}

void IRCClient::sendGetTime (const QString& target)
{
    sendCommand ("TIME", target);
}

void IRCClient::sendGetTime ()
{
    sendCommand ("TIME");
}

void IRCClient::sendConnect (const QString& targetServer, quint32 port, const QString& remoteServer)
{
    sendCommand ("CONNECT", QStringList () << targetServer << QString::number (port) << remoteServer);
}

void IRCClient::sendConnect (const QString& targetServer, quint32 port)
{
    sendCommand ("CONNECT", QStringList () << targetServer << QString::number (port));
}

void IRCClient::sendTrace (const QString& target)
{
    sendCommand ("TRACE", target);
}

void IRCClient::sendTrace ()
{
    sendCommand ("TRACE");
}

void IRCClient::sendGetAdmin (const QString& target)
{
    sendCommand ("ADMIN", target);  
}

void IRCClient::sendGetAdmin ()
{
    sendCommand ("ADMIN");
}

void IRCClient::sendGetServerInfo (const QString& target)
{
    sendCommand ("INFO", target);  
}

void IRCClient::sendGetServerInfo ()
{
    sendCommand ("INFO");
}

void IRCClient::sendWho (const QString& mask, bool operatorsOnly)
{
    sendCommand ("WHO", QStringList () << mask << "o");
}

void IRCClient::sendWho (const QString& mask)
{
    sendCommand ("WHO", mask);
}

void IRCClient::sendWho ()
{
    sendCommand ("WHO");
}

void IRCClient::sendGetUserInfo (const QString& target, const QStringList& masks)
{
    sendCommand ("WHOIS", QStringList () << target << masks.join (","));
}

void IRCClient::sendGetUserInfo (const QStringList& masks)
{
    sendCommand ("WHOIS", masks.join (","));
}

void IRCClient::sendGetUserInfo (const QString& mask)
{
    sendCommand ("WHOIS", mask);
}

void IRCClient::sendKill (const QString& nickname, const QString& comment)
{
    sendCommand ("PING", QStringList () << nickname << (":" + comment));
}

void IRCClient::sendPing (const QString& server1, const QString& server2)
{
    sendCommand ("PING", QStringList () << server1 << server2);  
}

void IRCClient::sendPing (const QString& server)
{
    sendCommand ("PING", server);
}

void IRCClient::sendPong (const QString& server1, const QString& server2)
{
    sendCommand ("PONG", QStringList () << server1 << server2);  
}

void IRCClient::sendPong (const QString& server)
{
    sendCommand ("PONG", server);
}

// ...

void IRCClient::sendReloadConfiguration ()
{
    sendCommand ("REHASH");
}

void IRCClient::sendShutdownServer ()
{
    sendCommand ("DIE");
}

void IRCClient::sendRestartServer ()
{
    sendCommand ("RESTART");
}

IRCUser *IRCClient::getUser (const QString& nickname)
{
    IRCUser *user = users[nickname];
    if (user == NULL) {
        user = users[nickname] = new IRCUser ();
        user->setParent (this);
        user->setNickname (nickname);
    }
    return user;
}

void IRCClient::changeNickname (const QString& oldNickname, const QString& newNickname)
{
    if (!users.contains (oldNickname))
        return;

    IRCUser *user = users[oldNickname];
    user->setNickname (newNickname);

    users[newNickname] = user;
    users.remove (oldNickname);
}
