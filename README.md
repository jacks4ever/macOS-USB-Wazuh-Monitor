# macOS USB Monitoring with Wazuh Integration

This repository contains a custom solution for monitoring USB drive activity on macOS systems with integration into Wazuh for enhanced security monitoring.

## Overview

A Swift script-based tool that monitors and logs USB connection and disconnection events on macOS. The logs are formatted in JSON and can be integrated with Wazuh, a powerful open-source security monitoring tool, to provide real-time alerts and monitoring.

## Prerequisites

- A Wazuh Manager server running the latest version of Wazuh.
- A macOS endpoint with `USBMonitor` executable and `usb.ids` file in the same directory.
- Wazuh Agent installed and configured on the macOS endpoint.
- Xcode or Xcode Command Line Tools installed on macOS.

## Installation

### Compiling the Swift Script

Update the `/path/to/usb.ids` in the script to the actual location of your `usb.ids` file before compiling.

```sh
xcode-select --install
swiftc USBMonitor.swift -o USBMonitor
```

### Preparing USB IDs Data

Download the `usb.ids` file from the [Linux USB ID Repository](http://www.linux-usb.org/usb-ids.html) and ensure it is placed in the same directory as the `USBMonitor` executable.

### Setting Permissions

Set the necessary permissions using the following commands:

```sh
chmod +x /path/to/USBMonitor
chmod 644 /path/to/usb.ids
touch /var/log/usb_monitor.log
chmod 640 /var/log/usb_monitor.log

## Usage

Execute the `USBMonitor` to start monitoring USB events:

```sh
/path/to/USBMonitor

The script logs events to `/var/log/usb_monitor.log`. Ensure the path to the `usb.ids` file is correct in the Swift script before executing the monitor.

## Wazuh Integration

Configure the Wazuh Agent and Manager using the provided XML configuration snippets in this repository. For detailed setup instructions, refer to the `config` directory.

## macOS Startup Script

To run the `USBMonitor` at startup, use the `com.user.usbmonitor.plist` file provided in the `startup` directory. Follow the instructions there to set up the startup script on your macOS system.

## Contributing

If you're interested in contributing to this project, please fork the repository and submit a pull request. For substantial changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This guide is for educational purposes only. It is recommended to review and test the code thoroughly before deploying it in a production environment.
