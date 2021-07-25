# Harmoniker

Tool to computer Spherical Harmonics out from pictures.

Based on [Harmoniker](https://github.com/endavid/Harmoniker), and re-written in Swift.


## Installation

* Use the latest Xcode to compile it.
* It requires Mac OS X 10.10 at least.

## Troubleshooting

### App Store submission

```log
ERROR ITMS-90242: "The product archive is invalid. The Info.plist must contain a LSApplicationCategoryType key, whose value is the UTI for a valid category. For more details, see "Submitting your Mac apps to the App Store"."
```

Solution: https://stackoverflow.com/a/63056516/1765629

```log
ERROR ITMS-90296: "App sandbox not enabled. The following executables must include the "com.apple.security.app-sandbox" entitlement with a Boolean value of true in the entitlements property list: [( "com.endavid.harmonikr.pkg/Payload/Harmonikr.app/Contents/MacOS/Harmonikr" )] Refer to App Sandbox page at https://developer.apple.com/documentation/security/app_sandbox for more information on sandboxing your app."
```

Solution: https://developer.apple.com/forums/thread/99105

```log
WARNING ITMS-90788: "Incomplete Document Type Configuration. The CFBundleDocumentTypes dictionary array in the 'com.endavid.harmonikr' Info.plist should contain an LSHandlerRank value for the CFBundleTypeName 'Harmonikr File' entry. Refer to https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-SW1 for more information on the LSHandlerRank key."
```

Solution:  https://stackoverflow.com/a/57185386/1765629


