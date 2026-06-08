# Post-Setup: Manual Steps

Settings that `nix run .#build-switch` **cannot** apply (account sign-outs, iPhone-side
toggles, and notification flags). Do these once after a fresh setup.

> AirDrop = Contacts Only is handled by the Nix config — no manual step needed.

## On this Mac

1. **Messages — sign out**
   Messages → Settings → iMessage → **Sign Out**.

2. **FaceTime — sign out**
   FaceTime → Settings → **Sign Out** (next to your Apple Account).

3. **Notifications — turn off for chat/call apps**
   System Settings → Notifications → set **Allow Notifications = Off** for:
   - Messages
   - FaceTime
   - Phone

4. **Keep on (do nothing):** iCloud Drive, Handoff.

## On your iPhone

These live on the phone, not the Mac:

5. **Calls on Other Devices — off for this Mac**
   Settings → Apps → Phone → Calls on Other Devices → toggle **off** for this Mac
   (or turn off *Allow Calls on Other Devices* entirely).

6. **Text Message Forwarding — off for this Mac**
   Settings → Apps → Messages → Text Message Forwarding → toggle **off** for this Mac.

## Verify

- Send yourself an iMessage → it should **not** appear on the Mac.
- Place a call to your iPhone → the Mac should **not** ring.
