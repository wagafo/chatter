/*
 * Copyright (C) 2018 Rúben Carneiro <rubencarneiro01@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

#ifndef IRC_CLIENT_H
#define IRC_CLIENT_H

#include <QObject>
#include <QTcpSocket>

enum UserMode
{
    Away              = 1 << 0,
    Present           = 1 << 1,
    Invisible         = 1 << 2,
    Visible           = 1 << 3,
    ReceiveWallops    = 1 << 4,
    IgnoreWallops     = 1 << 5,
    DropOperator      = 1 << 6,
    DropLocalOperator = 1 << 7,
};

class IRCUser: public QObject
{
    Q_OBJECT
    Q_PROPERTY (QString nickname READ nickname WRITE setNickname NOTIFY nicknameChanged)
    Q_PROPERTY (QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY (QString hostname READ hostname WRITE setHostname NOTIFY hostnameChanged)
    Q_PROPERTY (QString realName READ realName WRITE setRealName NOTIFY realNameChanged)
    Q_PROPERTY (QString clientVersion READ clientVersion WRITE setClientVersion NOTIFY clientVersionChanged)

public:
    void setNickname (const QString& nickname)
    {
        if (nickname != m_nickname) {
            m_nickname = nickname;
            emit nicknameChanged ();
        }
    }

    QString nickname () const
    {
        return m_nickname;
    }

    void setUsername (const QString& username)
    {
        if (username != m_username) {
            m_username = username;
            emit usernameChanged ();
        }
    }

    QString username () const
    {
        return m_username;
    }

    void setHostname (const QString& hostname)
    {
        if (hostname != m_hostname) {
            m_hostname = hostname;
            emit hostnameChanged ();
        }
    }

    QString hostname () const
    {
        return m_hostname;
    }

    void setRealName (const QString& realName)
    {
        if (realName != m_realName) {
            m_realName = realName;
            emit realNameChanged ();
        }
    }

    QString realName () const
    {
        return m_realName;
    }

    void setClientVersion (const QString& clientVersion)
    {
        if (clientVersion != m_clientVersion) {
            m_clientVersion = clientVersion;
            emit clientVersionChanged ();
        }
    }

    QString clientVersion () const
    {
        return m_clientVersion;
    }

signals:
    void nicknameChanged ();
    void usernameChanged ();
    void hostnameChanged ();
    void realNameChanged ();
    void clientVersionChanged ();

private:
    QString m_nickname;
    QString m_username;
    QString m_hostname;
    QString m_realName;
    QString m_clientVersion;
};

class IRCClient: public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE QString ctcpVersionData ();
    Q_INVOKABLE void connectToServer (const QString &host, quint16 port);
    Q_INVOKABLE void connectToSslServer (const QString &host, quint16 port);
    Q_INVOKABLE void disconnectFromServer ();
    Q_INVOKABLE void sendPassword (const QString& password);
    Q_INVOKABLE void sendSetNickname (const QString& nickname);
    Q_INVOKABLE void sendUserInformation (const QString& userName, bool receiveWallops, bool isInvisible, const QString& realName);
    Q_INVOKABLE void sendUserInformation (const QString& userName, const QString& realName);
    Q_INVOKABLE void sendSetOperator (const QString& userName, const QString& password);
    Q_INVOKABLE void sendSetUserMode (const QString& nickname, UserMode mode);
    Q_INVOKABLE void sendRegisterService (const QString& nickname, const QString& distribution, const QString& info);
    Q_INVOKABLE void sendQuit (const QString& message);
    Q_INVOKABLE void sendQuit ();
    Q_INVOKABLE void sendServerQuit (const QString& server, const QString& comment);
    Q_INVOKABLE void sendJoin (const QStringList& channels);
    Q_INVOKABLE void sendJoin (const QString& channel);
    Q_INVOKABLE void sendPart (const QStringList& channels, const QString& message);
    Q_INVOKABLE void sendPart (const QString& channel, const QString& message);
    Q_INVOKABLE void sendPart (const QStringList& channels);
    Q_INVOKABLE void sendPart (const QString& channel);
    Q_INVOKABLE void sendPartAll ();
    Q_INVOKABLE void sendSetChannelMode (const QString& channel);
    Q_INVOKABLE void sendSetTopic (const QString& channel, const QString& topic);
    Q_INVOKABLE void sendGetTopic (const QString& channel);
    Q_INVOKABLE void sendGetNames (const QStringList& channels, const QString& target);
    Q_INVOKABLE void sendGetNames (const QStringList& channels);
    Q_INVOKABLE void sendListChannels (const QStringList& channels, const QString& target);
    Q_INVOKABLE void sendListChannels (const QStringList& channels);
    Q_INVOKABLE void sendListChannels ();
    Q_INVOKABLE void sendListChannel (const QString& channel, const QString& target);
    Q_INVOKABLE void sendListChannel (const QString& channel);
    Q_INVOKABLE void sendInvite (const QString& nickname, const QString& channel);
    Q_INVOKABLE void sendKick (const QStringList& channels, const QStringList& usernames, const QString& comment);
    Q_INVOKABLE void sendKick (const QStringList& channels, const QStringList& usernames);
    Q_INVOKABLE void sendKick (const QString& channel, const QString& username, const QString& comment);
    Q_INVOKABLE void sendKick (const QString& channel, const QString& username);
    Q_INVOKABLE void sendMessage (const QString& target, const QString& text, bool canAutoReply);
    Q_INVOKABLE void sendMessage (const QString& target, const QString& text);
    Q_INVOKABLE void sendGetMOTD (const QString& target);
    Q_INVOKABLE void sendGetMOTD ();
    Q_INVOKABLE void sendGetUsers (const QString& target);
    Q_INVOKABLE void sendGetUsers ();
    Q_INVOKABLE void sendGetVersion (const QString& target);
    Q_INVOKABLE void sendGetVersion ();
    Q_INVOKABLE void sendGetStats (const QString& query, const QString& target);
    Q_INVOKABLE void sendGetStats (const QString& query);
    Q_INVOKABLE void sendGetStats ();
    Q_INVOKABLE void sendGetTime (const QString& target);
    Q_INVOKABLE void sendGetTime ();
    Q_INVOKABLE void sendConnect (const QString& targetServer, quint32 port, const QString& remoteServer);
    Q_INVOKABLE void sendConnect (const QString& targetServer, quint32 port);
    Q_INVOKABLE void sendTrace (const QString& target);
    Q_INVOKABLE void sendTrace ();
    Q_INVOKABLE void sendGetAdmin (const QString& target);
    Q_INVOKABLE void sendGetAdmin ();
    Q_INVOKABLE void sendGetServerInfo (const QString& target);
    Q_INVOKABLE void sendGetServerInfo ();
    Q_INVOKABLE void sendWho (const QString& mask, bool operatorsOnly);
    Q_INVOKABLE void sendWho (const QString& mask);
    Q_INVOKABLE void sendWho ();
    Q_INVOKABLE void sendGetUserInfo (const QString& target, const QStringList& masks);
    Q_INVOKABLE void sendGetUserInfo (const QStringList& masks);
    Q_INVOKABLE void sendGetUserInfo (const QString& mask);
    Q_INVOKABLE void sendKill (const QString& nickname, const QString& command);
    Q_INVOKABLE void sendPing (const QString& server1, const QString& server2);
    Q_INVOKABLE void sendPing (const QString& server);
    Q_INVOKABLE void sendPong (const QString& server1, const QString& server2);
    Q_INVOKABLE void sendPong (const QString& server);
    Q_INVOKABLE void sendReloadConfiguration ();
    Q_INVOKABLE void sendShutdownServer ();
    Q_INVOKABLE void sendRestartServer ();
    Q_INVOKABLE IRCUser *getUser (const QString& nickname);
    Q_INVOKABLE void changeNickname (const QString& oldNickname, const QString& newNickname);

signals:
    void commandReceived (const QString& prefix, const QString& command, const QStringList& params);
    void commandSent (const QString& command, const QStringList& params);
    void welcomeReceived (const QString& prefix, const QString& nickname, const QString& message);
    void nicknameChangedReceived (const QString& prefix, const QString& nickname);
    void joinReceived (const QString& prefix, const QString& channel);
    void quitReceived (const QString& prefix, const QString& message);
    void partReceived (const QString& prefix, const QString& channel, const QString& message);
    void setTopicReceived (const QString& prefix, const QString& channel, const QString& topic);
    void messageReceived (const QString& prefix, const QString& target, const QString& text, bool canAutoReply);
    void killReceived (const QString& prefix, const QString& nickname, const QString& comment);
    void pingReceived (const QString& prefix, const QString& server1, const QString& server2);
    void pongReceived (const QString& prefix, const QString& server1, const QString& server2);
    void errorReceived (const QString& prefix, const QString& message);
    void userInfoReceived (const QString& prefix, const QString& nickname, const QString& username, const QString& hostname, const QString& realName);
    void getTopicReplyReceived (const QString& prefix, const QString& channel, const QString& topic);
    void getNamesReplyReceived (const QString& prefix, const QString& nickname, const QString& channelType, const QString& channel, const QStringList& nicknames);
    void getNamesReplyEndReceived (const QString& prefix, const QString& nickname, const QString& channel, const QString& comment);
    void errNicknameInUseReceived (const QString& prefix, const QString& nickname, const QString& errorNickname, const QString& comment);
    void disconnected ();

private slots:
    void readData ();
    void handleDisconnected ();
    void handleError (QAbstractSocket::SocketError socketError);

private:
    QTcpSocket *socket;
    QByteArray read_buffer;
    QHash<QString, IRCUser*> users;
    void sendCommand (const QString& command, const QStringList& parameters);
    void sendCommand (const QString& command, const QString& parameter);
    void sendCommand (const QString& command);
};

#endif
