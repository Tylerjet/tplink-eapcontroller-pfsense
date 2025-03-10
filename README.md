Archived for now as i don't have the time and much has changed it seems again in 5.1.7 of the controller its just easier to run a VM via a distro they support

eapcontroller-pfsense
=============

*** Still Incomplete at this time ***

A script that installs the EAP Controller software on pfSense and other FreeBSD systems
Heavily based on UniFi-pfSense by Gozoinks (https://github.com/gozoinks/unifi-pfsense) and notes from @ArthurGay (https://medium.com/@arthurgay/eap-controller-software-on-a-raspberry-pi-9e93ecd1672e)
This README echos the same issues, so is practically verbatim.


Update
-------
Sept. 5th 2021
  
  Script is now grabing v4.4.4 of SDN
    
    Known Issues:
     - This is still very VERY much incomplete.
     - Starting the service can take a few minutes.
     - Upgrading is not tested.
     - Script is messy!
     - Mongodb is not connecting to the SDN so until that is fixed more debugging cannot be done or testing be done.

Purpose
-------

The objective of this project is to develop and maintain a script that installs [TP-Link's](http://www.tp-link.com/) EAP Controller software on FreeBSD-based systems, particularly the [pfSense](http://www.pfsense.org/) firewall.

Status
------

The project provides an rc script to start and stop the EAP controller, and an installation script to automatically download and install everything, including the rc script.

Challenges
----------

Because the EAP Controller software is proprietary, it cannot be built from source and cannot be included directly in a package. To work around this, we can download the EAP controller software directly from TP-Link during the installation process.

Licensing
---------

This project itself is licensed according to the two-clause BSD license.

The EAP Controller software is licensed as-is with no warranty, according to the README included with the software.

Upgrading
------------------

At this time - no idea...

Usage
------------

To install the controller software and the rc script:

1. Log in to the pfSense command line shell as root.
2. Run this one-line command, which downloads the install script from Github and executes it with sh:

  ```
    fetch -F -o - https://raw.githubusercontent.com/Tylerjet/tplink-eapcontroller-pfsense/master/install-eapcontroller/install-eapcontroller.sh | sh -s
  ```

The install script will install dependencies, download the EAP controller software, make some adjustments, and start the EAP controller.


Starting and Stopping
---------------------

To start and stop the controller, use the `service` command from the command line.

- To start the controller:

  ```
    service eapcontroller.sh start
  ```
  The EAP controller takes a few minutes to start. The 'start' command exits immediately while the startup continues in the background.

- To stop the controller:

  ```
    service eapcontroller.sh stop
  ```
  The the stop command takes a while to execute, and then the shutdown continues for several minutes in the background. The rc script will wait until the command received and the shutdown is finished. The idea is to hold up system shutdown until the EAP controller has a chance to exit cleanly.


Contributing
------------

### EAP controller updates

The main area of concern is keeping up with TP-Links's updates. I don't know of a way to automatically grab the URL to the current version; UBNT posts updates only to their blog and their forums, and they don't seem to have a link alias to the current release. That means we have to commit an update directly to the install.sh script with every release.

### Other enhancements

Other enhancements are most welcome. Much of the script's most intelligent behavior is the work of contributors, including the package dependency resolution and the java version spoofing. This project would not be alive without these efforts. I am excited by this support, and I can't wait to see what else develops.

Potential areas of improvement include but are not limited to:

- Error handling
- Automatic latest-version detection
- More robust backup and restore
- LTS/Latest branch selection options and defaults. Command line options? Prompts?
- What else?

### Issues and pull requests

Of course. That's why it's on github.

Roadmap
-------

This project may never reach its original goal of becoming a pfSense package. The packaging scheme for pfSense has changed. Doing this as a pfSense package requires doing it as a FreeBSD package first. Doing it as a FreeBSD package means we may as well make it portable to other FreeBSD systems. All of this changes how this would be implemented. Some of the concepts we can borrow, but it's substantially new work. Moreover, because the requirements of the EAP controller deviate from what's strictly available in the FreeBSD package repos, I'm not even sure it's possible.

As a helper script for installing the EAP controller, this tool remains effective and robust, which is great. I see no reason not to continue development here.

It is also less pfsense-specific than originally imagined. If you're here to run EAP on your NAS, welcome!

With all this in mind, the future of this project is clearly as an installation tool, and I envision enhancements to it as such. So let's just make it a smart and capable installer for EAP Controller on FreeBSD-type systems.

Resources
----------

https://github.com/gozoinks/unifi-pfsense
https://medium.com/@arthurgay/eap-controller-software-on-a-raspberry-pi-9e93ecd1672e
