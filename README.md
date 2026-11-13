# DamaiPocket

DamaiPocket is a standalone, non-invasive iOS ticket-sale preparation utility. It does not inject into, automate, or modify the official Damai app.

## Device target

- iPad 8
- iOS 16.3
- Dopamine rootless jailbreak
- Package format: rootless DEB
- Minimum iOS version: 14.0

## Features

- Save an event name, city / venue, session, price, and planned ticket quantity.
- Live sale countdown using the device's local clock.
- Schedule local notifications for 10 minutes before, 1 minute before, and the sale time.
- Open a pasted HTTPS event link on the official damai.cn domain. If no link is supplied, open the official Damai website.
- Keep the plan locally in the app sandbox.

## Boundaries

This is a reminder and quick-launch utility, not an auto-purchaser. It does not connect to Damai APIs, inspect app internals, inject code, tap purchase controls, bypass queues or verification, store account credentials, submit orders, or make payments. After the reminder, complete the transaction yourself in the official Damai app.

## GitHub Actions build

1. Open the repository's **Actions** tab.
2. Choose **Build DamaiPocket Rootless App**.
3. Run the workflow, or push a change under **DamaiPocketApp/**.
4. Download the **DamaiPocket-Rootless-DEB** artifact from the newest successful run of that workflow.

**Important:** Older workflow runs contain an obsolete injection-based prototype. Do not install artifacts from those older runs. Only use the artifact produced by **Build DamaiPocket Rootless App** after it succeeds.

The workflow builds with Theos and the iPhoneOS 16.5 SDK. The app deployment target is iOS 14.0, and the package is built with Theos' rootless scheme.

## Install

Download the DEB artifact to the iPad and install it using Sileo or Zebra. After installation, DamaiPocket appears as a normal standalone app. Launch it, save the event plan, grant notification permission, and paste the official event URL.

No ElleKit tweak injection or changes to the Damai app are required.
