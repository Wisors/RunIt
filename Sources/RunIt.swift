//
//    Copyright (c) 2015-2017 Nikishin Alexander https://twitter.com/wisdors
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//    the Software, and to permit persons to whom the Software is furnished to do so,
//    subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

open class RunIt: Manager, Component {
    
    open static let manager: RunIt = RunIt()
    
    /** 
    `Runnable` components will scheduled to run in runOperationQueue on add operation if flag is `true`.
     
    - Warning: If component will be removed before it started to run than it will canceled to run and will never be started or stoped.
     */
    open var runComponentOnAdd: Bool = true
    /// `Runnable` components will scheduled to stop in runOperationQueue on remove operation if flag is `true`
    open var stopComponentOnRemove: Bool = true
    /// Dispatch queue where access is synced. Custom concurrent queue by default. Usually no need to change it.
    open var syncQueue: DispatchQueue
    /**
    This queue is intended to run/stop components or custom user NSOperation objects. It's possible to change any property of this queue, but with a respect to NSOperationQueue properties change rules (for example, you can't change underlyingQueue while there are operations in queue).
    
    - Warning: It's not recommended to use same underlyingQueue with RunIt.syncQueue for thread-safety.
    */
    open private(set) var runOperationQueue: OperationQueue
    
    private var components: [String: Component] = [:]
    private var componentsKeysInRunProgress: Set<String> = []
    
    #if DEBUG
    public var suppressAssert: Bool = false
    #endif
    
    private func createRunQueue() -> OperationQueue {
        
        let queue = OperationQueue()
        return queue
    }
    
    public init() {
        
        syncQueue = DispatchQueue(label: "RunIt.SyncQueue", attributes: DispatchQueue.Attributes.concurrent)
        runOperationQueue = OperationQueue()
        runOperationQueue.underlyingQueue = DispatchQueue(label: "RunIt.RunQueue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    // MARK: - Add methods -
    open func add(component: Component) {
        
        let key = String(describing: type(of: component))
        add(component: component, forKey: key)
    }
    
    open func add(component: Component, forKey key: String) {
        
        #if DEBUG
        assert(!suppressAssert || components[key] == nil, "WARNING! Trying to reassign component with new one! Possible data loss situation.")
        #endif
        syncQueue.async(flags: .barrier, execute: {
            
            self.components[key] = component
            self.postNotification(name: .RunItDidAddComponent, component: component, key: key)
            
            if self.runComponentOnAdd, let runnable = component as? Runnable, runnable.isRunning == false {
                self.scheduleRunOperation(forRunnableComponent: runnable, andKey: key)
            }
        }) 
    }
    
    private func scheduleRunOperation(forRunnableComponent component: Runnable, andKey key: String) {
        
        let operation = BlockOperation { 
            
            func run() {
                
                var componentStillExists: Bool = false
                self.syncQueue.sync(execute: {
                    guard self.components[key] != nil else { return }
                    
                    componentStillExists = true
                    self.componentsKeysInRunProgress.insert(key)
                })
                guard componentStillExists else { return }
                
                component.run()
                self.syncQueue.async(execute: {
                    self.componentsKeysInRunProgress.remove(key)
                })
                self.postNotification(name: .RunItDidRunComponent, component: component, key: key)
            }
            
            if let runQueue = component.runQueue {
                
                let semaphore = DispatchSemaphore(value: 0)
                runQueue.async(execute: {
                    
                    run()
                    semaphore.signal()
                })
                let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            } else {
                run()
            }
        }
        operation.queuePriority = component.priority
        runOperationQueue.addOperation(operation)
    }
    
    // MARK: - Get methods -
    open func get<T: Component>() -> T? {
        
        let key = String(describing: T.self)
        return get(componentForKey: key)
    }
        
    open func get<T: Component>(_ comoponentType: T.Type) -> T? {
        return get(componentForKey: String(describing: comoponentType))
    }
    
    open func get<T : Component>(componentForKey key: String) -> T? {
        
        var component: T? = nil
        syncQueue.sync {
            component = self.components[key] as? T
        }
        return component
    }
    
    // MARK - Remove methods -
    open func remove<T: Component>(component: T) -> Bool {

        let key = String(describing: type(of: component))
        return remove(componentForKey: key)
    }
    
    open func remove<T: Component>(_ comoponentType: T.Type) -> Bool {
        return remove(componentForKey: String(describing: comoponentType))
    }
    
    open func remove(componentForKey key: String) -> Bool {
        
        var storedComponent: Component? = nil
        syncQueue.sync {
            storedComponent = self.components.removeValue(forKey: key)
        }
        
        guard let component = storedComponent else { return false }
        NotificationCenter.default.post(name: .RunItDidRemoveComponent, object: component, userInfo: [RunItNotificationComponentKey : key])
        
        guard self.stopComponentOnRemove, let runnable = component as? Runnable else { return true }
        
        if runnable.isRunning {
            scheduleStopOperation(forRunnableComponent: runnable, andKey: key)
        } else {
            
            var scheduledToRun: Bool = false
            syncQueue.sync(execute: {
                scheduledToRun = self.componentsKeysInRunProgress.contains(key) || runnable.isRunning
            })
            if scheduledToRun {
                scheduleStopOperation(forRunnableComponent: runnable, andKey: key)
            }
        }
        return true
    }
    
    private func scheduleStopOperation(forRunnableComponent component: Runnable, andKey key: String) {
        
        let operation = BlockOperation {
            
            func stop() {

                component.stop()
                self.postNotification(name: .RunItDidStopComponent, component: component, key: key)
            }
            
            if let runQueue = component.runQueue {
                
                let semaphore = DispatchSemaphore(value: 0)
                runQueue.async(execute: {
                    
                    stop()
                    semaphore.signal()
                })
                let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            } else {
                stop()
            }
        }
        operation.queuePriority = component.priority
        runOperationQueue.addOperation(operation)
    }
    
    // MARK: - Post events - 
    private func postNotification(name: Notification.Name, component: AnyObject, key: String) {
        
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: name, object: component, userInfo: [RunItNotificationComponentKey : key])
        })
    }
}
