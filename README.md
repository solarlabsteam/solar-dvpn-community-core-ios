# SOLAR dVPN Community Core for iOS

This project contains an application for iOS, which is made as a server with a webView.  
API documentation is [here](https://github.com/solarlabsteam/solar-dvpn-community-core-docs).

## Building:

- Clone this repo.
- Open project in Xcode.

### Target set up:

- In `SOLARdVPNCommunityCoreiOS` target:
    - Set `Developer Team`.
    - Set your Bundle Identifier.
- In `SOLARAPI` target:
    - Set `Developer Team`.
    - Set your Bundle Identifier as `{your_bundle_id}.SOLARAPI`.
- In `WireGuardNetworkExtension` target:
    - Set `Developer Team`.
    - Set your Bundle Identifier as `{your_bundle_id}.network-extension`.

### Network extension set up:

- Open `Keychain.swift`, set `appGroupId` as `group.{your_bundle_id}`.
- Open `SecurityService.swift`, set `accessGroup` as `group.{your_bundle_id}`.

<details>
  <summary>Make sure your team supports Network Extensions. Make the following steps if it does not.</summary> 

- Go to your [account page](https://developer.apple.com/account/) on the developer web site.
- Click Identifiers.
- Click on your app’s App ID.
- Click Edit.
- Enable the Network Extensions checkbox.
- Rebuild your distribution profile so that it picks up the entitlement change from your App ID.

</details>

### Additional:

- Set your backend endpoint in `ClientConstants.swift` file.

## UI integration:

- Write your own UI.
- Add it to the project.
- Set main file name in `ViewController.swift`.

## In-App Purchase:

<details>
  <summary>If you wish to use In-App Purchase in your application, make the following steps.</summary>

- Set up your [RevenueCat](https://www.revenuecat.com/docs/getting-started) project.
- Set your purchase API key in `ClientConstants.swift` file.
- Use our [Purchase API](https://github.com/solarlabsteam/solar-dvpn-community-core-docs/tree/main/api/purchases).

</details>

---

## Troubleshooting:

Do not hesitate to create an issue for our team.
