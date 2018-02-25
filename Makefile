all: binary-armhf \
     chatter.desktop \
     po/chatter.ruben-carneiro.pot \
     share/locale/de/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/el/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/es/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/fi/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/fr/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/hu/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/it/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/nl/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/pt/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/ru/LC_MESSAGES/chatter.ruben-carneiro.mo \
     share/locale/zh_CN/LC_MESSAGES/chatter.ruben-carneiro.mo     

CPP_SOURCES = main.cpp irc_client.cpp irc_client_moc.cpp
CPP_HEADERS = irc_client.h version.h
QML_SOURCES = AddConversationPage.qml ConversationItem.qml ConversationPage.qml ConfigureServersPage.qml IRCClient.qml IRCConversation.qml ServerPage.qml ServerSelector.qml SettingsPage.qml StatusBox.qml UserPage.qml UsersPage.qml WelcomePage.qml main.qml
FRAMEWORK = ubuntu-sdk-15.04

lib/arm-linux-gnueabihf/bin/chatter: $(CPP_SOURCES) $(CPP_HEADERS)
	click chroot -a armhf -f $(FRAMEWORK) run ARCH_PREFIX=arm-linux-gnueabihf- make binary-armhf

binary-armhf:
	arm-linux-gnueabihf-g++ -g -Wall -std=c++11 -fPIC $(CPP_SOURCES) -o lib/arm-linux-gnueabihf/bin/chatter `arm-linux-gnueabihf-pkg-config --cflags --libs Qt5Widgets Qt5Quick Qt5Network`

lib/x86_64-linux-gnu/bin/chatter: $(CPP_SOURCES) $(CPP_HEADERS)
	click chroot -a amd64 -f $(FRAMEWORK) run ARCH_PREFIX=x86_64-linux-gnu- make binary-amd64

binary-amd64:
	x86_64-linux-gnu-g++ -g -Wall -std=c++11 -fPIC $(CPP_SOURCES) -o lib/x86_64-linux-gnu/bin/chatter `pkg-config --cflags --libs Qt5Widgets Qt5Quick Qt5Network`

lib/i386-linux-gnu/bin/chatter: $(CPP_SOURCES) $(CPP_HEADERS)
	click chroot -a i386 -f $(FRAMEWORK) run ARCH_PREFIX=i386-linux-gnu- make binary-i386

binary-i386:
	g++ -g -Wall -std=c++11 -fPIC $(CPP_SOURCES) -o lib/i386-linux-gnu/bin/chatter `pkg-config --cflags --libs Qt5Widgets Qt5Quick Qt5Network`

click:
	click build --ignore=Makefile --ignore=*.cpp --ignore=*.h --ignore=*.pot --ignore=*.po --ignore=*.qmlproject --ignore=*.qmlproject.user --ignore=*.in --ignore=po .

version.h: manifest.json
	echo -n "#define VERSION " > $@
	jq .version $< >> $@        

irc_client_moc.cpp: irc_client.h
	moc $< -o $@

chatter.desktop: chatter.desktop.in po/*.po
	intltool-merge --desktop-style po $< $@

po/chatter.ruben-carneiro.pot: $(QML_SOURCES) chatter.desktop.in
	touch po/chatter.ruben-carneiro.pot
	xgettext --from-code=UTF-8 --language=JavaScript --keyword=tr --keyword=tr:1,2 --add-comments=TRANSLATORS $(QML_SOURCES) -o po/chatter.ruben-carneiro.pot
	intltool-extract --type=gettext/keys chatter.desktop.in
	xgettext --keyword=N_ chatter.desktop.in.h -j -o po/chatter.ruben-carneiro.pot
	rm -f chatter.desktop.in.h

share/locale/%/LC_MESSAGES/chatter.ruben-carneiro.mo: po/%.po
	msgfmt -o $@ $<

clean:
	rm -f lib/arm-linux-gnueabihf/bin/chatter
	rm -f lib/x86_64-linux-gnu/bin/chatter
	rm -f lib/i386-linux-gnu/bin/chatter        
	rm -f share/locale/*/*/*.mo
	rm -f chatter.desktop

run:
	./lib/x86_64-linux-gnu/bin/chatter
