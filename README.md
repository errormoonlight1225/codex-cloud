# codex-cloud

## DamaiPocket Rootless DEB

The repository now contains a Theos Rootless tweak build for Dopamine / ElleKit.

- Source: `DamaiPocketTweak/`
- Workflow: `.github/workflows/build-deb.yml`
- Output artifact: `DamaiPocket-Rootless-DEB`
- SDK: iPhoneOS 16.5
- Architectures: arm64 / arm64e
- Minimum firmware: iOS 14.0

The current tweak is a passive injection probe for the official Damai app bundle `cn.damai.iphone`. It only logs load and app activation. It does not bypass CAPTCHA, queueing, anti-abuse checks, or payment confirmation.

Open **Actions → Build Rootless DEB** to view the build and download the generated `.deb` artifact after a successful run.
