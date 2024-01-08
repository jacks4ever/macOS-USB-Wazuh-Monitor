# macOS USB Monitoring with Wazuh Integration

	This repository contains a custom solution for monitoring USB drive activity on macOS systems with integration into Wazuh for enhanced security monitoring.

# Description

	A Swift script-based tool that monitors and logs USB connection and disconnection events on macOS. The logs are formatted in JSON and can be integrated with Wazuh, a powerful open-source security monitoring tool, to provide real-time alerts and monitoring.

# Setup

# Prerequisites

	A Wazuh Manager server running the latest version of Wazuh.
	A macOS endpoint with USBMonitor executable and usb.ids file in the same directory.
	Wazuh Agent installed and configured on the macOS endpoint.
	Xcode or Xcode Command Line Tools installed on macOS.
	Swift Script for USB Event Logging
	The USBMonitor.swift script logs USB connection and disconnection events using the IOKit and Foundation frameworks. The script outputs the logs in a structured JSON format.

# Compiling the Swift Script

	Before compiling, ensure the /path/to/usb.ids is updated in the script to the actual location of your usb.ids file.

		xcode-select --install
		swiftc USBMonitor.swift -o USBMonitor

	This command compiles the Swift script and produces an executable named USBMonitor.

# Preparing USB IDs Data

	Download the usb.ids file from the Linux USB ID Repository and ensure it is placed in the same directory as the USBMonitor executable.

# Setting Permissions

	Permissions and ownership for the files used in the USB monitoring setup can be set using the chmod and chown commands.

		chmod +x /path/to/USBMonitor
		chmod 644 /path/to/usb.ids
		touch /var/log/usb_monitor.log
		chmod 640 /var/log/usb_monitor.log

# Running the USB Monitor

	Execute the USBMonitor to start monitoring USB events:

		/path/to/USBMonitor

# Integrating with Wazuh

	Configure the Wazuh Agent and Manager as per the provided XML configuration snippets in this repository.

# macOS Startup Script

	To run the USBMonitor at startup, use the provided com.user.usbmonitor.plist file and load it with launchctl.

# Conclusion

	The provided code and configuration steps offer a solid foundation for integrating USB event monitoring into a security infrastructure focused on macOS endpoints.

# Disclaimer

	This guide is intended for educational purposes. The code and configurations should be reviewed and tested before deploying in a production environment.
