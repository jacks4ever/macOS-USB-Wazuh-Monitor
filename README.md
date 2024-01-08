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

