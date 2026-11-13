# DamaiPocket

DamaiPocket is a rootless on-device UI assistant for the official Damai iOS app. It targets the Dopamine / ElleKit jailbreak environment and is built as a Theos DEB package.

## Target device

- iPad 8 (A12, arm64e-capable)
- iOS 16.3
- Dopamine rootless jailbreak / ElleKit
- Damai app bundle filter: **cn.damai.iphone**

## What 0.2.0 does

- Injects only into the official Damai app.
- Adds an on-screen DamaiPocket control panel.
- Saves sale time, session keyword, and ticket-price keyword locally in the app sandbox.
- Starts a local countdown and scans the current visible UIKit view tree.
- Can tap a visible purchase entry or a visible option matching the user's configured session / price text.
- Stops when it detects queueing, CAPTCHA, identity/security verification, rate-limit warnings, or an order/payment submission step.
- Does not send ticketing network requests, reverse private endpoints, replay traffic, auto-solve CAPTCHA, bypass queues, or submit/pay an order.

## Important limits

This build is a UI-assisted prototype, not a guarantee of ticket availability or purchase success. Damai can change its view hierarchy and labels at any time; some controls may not expose accessible text, so automatic selection may not work on every app version. The user must remain in the official app, check quantity and attendee details, and manually confirm the order and payment. Do not use it for bulk purchasing or resale.

## Build with GitHub Actions

1. Open **Actions** in the repository.
2. Select **Build Rootless DEB**.
3. Run the workflow manually, or push changes under **DamaiPocketTweak/**.
4. Download the **DamaiPocket-Rootless-DEB** artifact from the successful run.

The build uses Theos, the iPhoneOS 16.5 SDK, and the rootless package scheme. The 16.5 SDK is used to compile; the deployment target remains iOS 14.0, so the package is intended to run on iOS 16.3.

## Install

Transfer the generated DEB to the jailbroken iPad and install it with a rootless-compatible package manager (Sileo/Zebra) or dpkg -i. Then respring or restart the Damai app. Open Damai and tap the floating **DamaiPocket** button.

Remove the package from your package manager to uninstall it.
