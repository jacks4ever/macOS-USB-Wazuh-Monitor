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

### Preparing USB IDs Data

Download the `usb.ids` file from the [Linux USB ID Repository](http://www.linux-usb.org/usb-ids.html) and ensure it is placed in the same directory as the `USBMonitor` executable.

### Setting Permissions

Set the necessary permissions using the following commands:

```sh
chmod +x /path/to/USBMonitor
chmod 644 /path/to/usb.ids
touch /var/log/usb_monitor.log
chmod 640 /var/log/usb_monitor.log
```

### Ensuring UTF-8 Encoding for `usb.ids`

It's important to ensure that the `usb.ids` file is using UTF-8 encoding. Run the following command in the terminal:

```sh
iconv -f iso-8859-1 -t utf-8 usb.ids > usb-utf8.ids && mv usb-utf8.ids usb.ids
```

This command converts the encoding of the usb.ids file from ISO-8859-1 to UTF-8 and then replaces the original file with the converted one.

### Compiling the Swift Script

Download the `USBMonitor.swift` file from this repository.  Update the `/path/to/usb.ids` in the script to the actual location of your `usb.ids` file before compiling.

```sh
xcode-select --install
swiftc USBMonitor.swift -o USBMonitor
```

## Usage

Execute the `USBMonitor` to start monitoring USB events:

```sh
/path/to/USBMonitor
```

The script logs events to `/var/log/usb_monitor.log`. Ensure the path to the `usb.ids` file is correct in the Swift script before executing the monitor.

## Wazuh Integration

To integrate the USB monitoring solution with Wazuh, follow these steps:

### Setting Up Wazuh Agent on macOS

1. Install the Wazuh Agent on the macOS system if it's not already installed.

2. Configure the agent by editing the configuration file located at `/Library/Ossec/etc/ossec.conf`. Add the following block to the configuration:

```xml
<localfile>
    <log_format>json</log_format>
    <location>/var/log/usb_monitor.log</location>
</localfile>
```

This will direct the Wazuh Agent to monitor the log file generated by the `USBMonitor`.

### Configuring Wazuh Manager

On the Wazuh Manager server, update the `/var/ossec/etc/rules/local_rules.xml` file to include rules for processing macOS USB event logs. Add a new group for macOS USB-related rules:

```xml
<group name="macos,usb,">
    <rule id="100010" level="7">
        <decoded_as>json</decoded_as>
        <field name="eventType">^USBConnected$</field>
        <description>macOS: USB device connected</description>
        <options>no_full_log</options>
    </rule>
    <rule id="100011" level="7">
        <decoded_as>json</decoded_as>
        <field name="eventType">^USBDisconnected$</field>
        <description>macOS: USB device disconnected</description>
        <options>no_full_log</options>
    </rule>
</group>
```
Replace the `id` attribute values with the appropriate rule IDs as per your Wazuh Manager configuration.  For example, if you are already using these ids, then choose different ones.

### Restarting Services

After updating the configurations, restart both the Wazuh Agent and Manager services for the changes to take effect.

For the macOS endpoint, run:

```sh
sudo /Library/Ossec/bin/wazuh-control restart
```

For the Wazuh Manager:

```sh
sudo systemctl restart wazuh-manager
```
### Testing the Integration

To test the integration, monitor the `usb_monitor.log` for new entries and check the Wazuh Manager dashboard for alerts corresponding to the USB device events.

tail -f /var/log/usb_monitor.log

When a USB device is connected or disconnected, you should see JSON-formatted log entries in the `usb_monitor.log` file and corresponding alerts in the Wazuh Manager. This real-time monitoring allows for quick detection and response to USB device activities on macOS systems.

## macOS Startup Script

To ensure the `USBMonitor` script runs automatically at every startup of your macOS machine, follow these steps to create a startup script:

### Creating the Launch Daemon

1. Create a Launch Daemon `.plist` file. This file will instruct macOS to run the `USBMonitor` script at startup.

2. Use the provided `com.user.usbmonitor.plist` file as a template by downloading it and placing it in your `/Library/LaunchDaemons` folder.

    Edit the file and replace `/path/to/USBMonitor` with the actual file path of your `USBMonitor` executable.

### Installing the Launch Daemon

3. Save the `.plist` file to `/Library/LaunchDaemons/com.user.usbmonitor.plist`.

4. Set the correct ownership and permissions for the file:

    ```sh
    sudo chown root:wheel /Library/LaunchDaemons/com.user.usbmonitor.plist
    sudo chmod 644 /Library/LaunchDaemons/com.user.usbmonitor.plist
    ```

### Loading the Daemon

5. Load the daemon to register it with the system:

    ```sh
    sudo launchctl bootout system /Library/LaunchDaemons/com.user.usbmonitor.plist
    sudo launchctl bootstrap system /Library/LaunchDaemons/com.user.usbmonitor.plist
    ```

## Testing the Startup Script

After setting up the launch daemon, reboot your system. Once macOS starts up, check if the `USBMonitor` script is running and logging events as expected:

    tail -f /var/log/usb_monitor.log

You should see log entries corresponding to USB events if any USB devices are connected or disconnected after the reboot.

## Contributing

If you're interested in contributing to this project, please fork the repository and submit a pull request. For substantial changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This guide is for educational purposes only. It is recommended to review and test the code thoroughly before deploying it in a production environment.
