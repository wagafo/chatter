/*
 * Copyright (C) 2018 Rúben Carneiro <rubencarneiro01@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */
#include <QApplication>
#include <QQuickView>
#include <QQmlContext>

#include "irc_client.h"

int main(int argc, char *argv[])
{
    QApplication app (argc, argv);

    qmlRegisterType<IRCClient> ("chatter", 1, 0, "IRCClientNative");
    qmlRegisterType<IRCUser> ("chatter", 1, 0, "IRCUser");

    QQuickView view (QUrl::fromLocalFile ("main.qml"));
    view.setResizeMode (QQuickView::SizeRootObjectToView);
    view.show ();
    return app.exec ();
}
