#  Distribution

## Submission

Check: [Screenshot specifications](https://help.apple.com/app-store-connect/#/devd274dd925)

## Troubleshooting


```log
ERROR ITMS-90242: "The product archive is invalid. The Info.plist must contain a LSApplicationCategoryType key, whose value is the UTI for a valid category. For more details, see "Submitting your Mac apps to the App Store"."
```

Select project → General → Identity → App Category, and select from drop-down list. 
Also check [Catalyst app info.plist not being recognized](https://stackoverflow.com/a/63056516/1765629)



```log
ERROR ITMS-90296: "App sandbox not enabled. The following executables must include the "com.apple.security.app-sandbox" entitlement with a Boolean value of true in the entitlements property list: [( "com.endavid.harmonikr.pkg/Payload/Harmonikr.app/Contents/MacOS/Harmonikr" )] Refer to App Sandbox page at https://developer.apple.com/documentation/security/app_sandbox for more information on sandboxing your app."
```

> To distribute a macOS app through the Mac App Store, you must enable the App Sandbox capability.


Select project → App Signing & Capabilities, and click the `+` sign to add `App Sandbox`. Then, in the new App Sandbox section → File Access → User selected file → Read & Write. (I think we don't need any other permissions).

Read [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
Also check [this thread](https://developer.apple.com/forums/thread/99105)

```log
WARNING ITMS-90788: "Incomplete Document Type Configuration. The CFBundleDocumentTypes dictionary array in the 'com.endavid.harmonikr' Info.plist should contain an LSHandlerRank value for the CFBundleTypeName 'Harmonikr File' entry. Refer to https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-SW1 for more information on the LSHandlerRank key."
```

Check  [stackoverflow](https://stackoverflow.com/a/57185386/1765629)

```log
ITMS-90236: Missing required icon.
```

Check [Human Interface Guidelines: App Icon](https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/app-icon/)

