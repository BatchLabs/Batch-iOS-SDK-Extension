# Batch SDK - iOS (Extension)

This repository contains Batch's iOS Extension SDK.

It is a light version that only uses Extension-safe APIs for extension-specific features.

The project is written in Swift, but can be used with Objective-C.

## Requirements

- iOS 10 and higher
- A Xcode version that supports Swift 5 and higher

## Integration

This extension should be added to your Notification Service Extension. If you don't have one, please see [our documentation](https://doc.batch.com/ios/sdk-integration/rich-notifications-setup).

You will also need to configure an app group shared by your extension and app. See our [tutorial here](https://doc.batch.com/ios/advanced/app-groups).

### Cocoapods

pod 'BatchExtension'

### Carthage

github "BatchLabs/Batch-iOS-SDK-Extension"

### Swift Package Manager

_Requires Xcode 15_

Add https://github.com/BatchLabs/Batch-iOS-SDK-Extension.git as a dependency, and add it to your Extension target.
You do not need to add this package to your main target.
