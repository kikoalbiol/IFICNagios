IFICNagios
==========

Nagios status bar monitoring tool for MacOS X.

Inspired in MACNagios

Have you ever wished that you could just look at the top right corner of your Mac desktop and see a little icon and a number that indicated how your servers were doing?  And if something went wrong, get a little message in your notification center that says what happened?  Wish no more, my friend - IFICNagios is just that ~~and more~~!

Installation - Client
=====================

* Download the binary, links below.
* Unzip it and copy/move the application to your Applications folder.
* Create a macnagios-config.plist file in either your home directory or in /etc/
* Example config file:

		At first step customize your host using in the Status Menu the configuration option
		

Note that you'll need to add the statusJson.php file on the Nagios server, see below.

Server Setup
============

For status information, IFICNagios uses statusJson.php: https://github.com/lizell/php-nagios-json

A copy is provided in PHP directory

Installation is really simple:

* Find the folder that has your nagios index.php in it (generally something like /usr/share/nagios/) and download a copy of statusJson.php, like so:

		curl 'https://raw.githubusercontent.com/lizell/php-nagios-json/master/statusJson.php' > statusJson.php

* Edit the top of statusJson.php to have the correct path to your Nagios status.dat file


Downloads
=========
(MacOS X 10.9+ 64-bit)




FAQ
===


Credits
=======
IFICNagios was written by Kiko Albiol. Inspired in code from Brad Peabody MacNagios.  Inspired by NagiosDock (http://nagiosdock.sourceforge.net/), I needed something more up to date that just made it simple for me to get the feedback on multiple nagios instances easily from my Mac workstation.  Kudos to Volen Davidov who independently wrote NagBar (https://sites.google.com/site/nagbarapp/) and happened to release it the same weekend as I did this project (seriously crazy coincidence - neither of us had any prior knowledge of the other's project and they both showed up on Nagios Exchange on the same day) and was kind enough to contribute code and ideas regarding this project as well.
