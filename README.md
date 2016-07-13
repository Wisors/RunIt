#RunIt

<p align="left">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Swift_2.2-compatible-4BC51D.svg?style=flat" alt="Swift 2.2 compatible" /></a>
<a href="https://cocoapods.org/pods/tablekit"><img src="https://img.shields.io/badge/pod-0.1.0-blue.svg" alt="CocoaPods compatible" /></a>
<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
<a href="https://raw.githubusercontent.com/maxsokolov/tablekit/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>

RunIt is a super lightweight yet powerful system components manager. It helps to clean your code from unesessary singletons usage. RunIt has easy to go interface and provides you an opportunity to extend it for your personal needs.

## Features

- [x] Thread-safe access for your components
- [x] Generic getters
- [x] Extensibility
- [ ] Remove components only by it type
- [ ] NSOperation as Compoents support


## Getting Started

An [example app](Demo) is included demonstrating RunIt's functionality.

#### Basic usage

As example, suppose you have an application that uses user location and handles push notifcation. You know that both components available only if user grant access to it. So, no need to lauch and store your location service in singleton if it unavailable.
```swift
// Somewhere in app initialization proccess
if locationIsAvailable {

	let locationService = LocationComponent()
	RunIt.add(locationService)
}
if APNSIsAvailable {
	
	let APNSService = APNSComponent()
	RunIt.add(APNSService)
	// or
	RunIt.add(component: APNSService, forKey: "APNSService")
}
```
Later, anywhere in your code you have access to your components with generic getters.
```swift
let apnsService: LocationComponent? = RunIt.get()
let apnsService: APNSComponent? = RunIt.get(componentForKey: "APNSService")
```
No need for component anymore? Easy 
```swift
RunIt.remove(component: component)
RunIt.remove(componentForKey: "APNSService")
```
All provided actions on RunIt are thread-safe. 

#### Run your components

Your component may conforms to protocol `Runnable` and RunIt will automaticaly runs and stops your component on `add` and `remove` operations. Furthermore, `run` will be executed separate queue (background by default). You can control this behavior through flags:
```swift
RunIt.runComponentsOnAdd = false
RunIt.stopComponentOnRemove = false
RunIt.syncQueue = dispatch_get_main_queue() //Make your compoents run in main thread
```

## Installation

#### CocoaPods
To integrate RunIt into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'RunIt'
```

#### Manual
Clone the repo and drag files from `Sources` folder into your Xcode project.

## Requirements

- iOS 8.0+
- Xcode 7.0+

## License

RunIt is available under the MIT license. See LICENSE for details.