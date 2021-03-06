#RunIt

<p align="left">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Swift_3.1-compatible-4BC51D.svg?style=flat" alt="Swift 2.2 compatible" /></a>
<a href="https://cocoapods.org/pods/tablekit"><img src="https://img.shields.io/badge/pod-0.3.1-blue.svg" alt="CocoaPods compatible" /></a>
<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
<a href="https://raw.githubusercontent.com/Wisors/RunIt/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>

RunIt is a super lightweight yet powerful system components manager. It helps to clean your code from unesessary singletons usage. RunIt has an easy to go interface and provides you an opportunity to extend it for your personal needs.

## Features

- [x] Thread-safe access for your components
- [x] Generic getters
- [x] Extensibility
- [x] Remove components only by it type
- [x] NSOperation support (see NSOperation support)
- [ ] Remove components by component object itself


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

Your component may conforms to protocol `Runnable` and RunIt will automaticaly runs and stops your component on `add` and `remove` operations. Furthermore, `run` will be executed on separate queue (background by default). You can control this behavior through flags and by customization of runOperationQueue:
```swift
RunIt.runComponentsOnAdd = false
RunIt.stopComponentOnRemove = false
RunIt.syncQueue = dispatch_get_main_queue() //Make your compoents run in main thread
RunIt.runOperationQueue.maxConcurrentOperationCount = 2
```

It's easy to control component's run queue or it priority, just create a custom queue in your component:
```swift
class SomeComponent: Runnable {
    
    private(set) public var isRunning: Bool
    public var runQueue: dispatch_queue_t? = dispatch_queue_create("YourQueue", DISPATCH_QUEUE_CONCURRENT)
    public var priority: NSOperationQueuePriority = .High

    ...
}
```

#### NSOperation support

You are always welcome to add custom NSOperation(s) to RunIt.runOperationQueue, but you have to be aware that these operations will not cannibalize a run progress of your components. So, in case of large amount of NSOperation objects it's wise to add them with lower priority than your components used.

## Installation

#### CocoaPods
To integrate RunIt into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'RunIt'
```

#### Manual
Clone the repo and drag files from `Sources` folder into your Xcode project.

## Requirements

- Swift 3.0
- iOS 8.0+
- Xcode 7.0+

## License

RunIt is available under the MIT license. See LICENSE for details.
