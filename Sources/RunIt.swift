//
//    Copyright (c) 2015 Nikishin Alexander https://twitter.com/wisdors
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

public class RunIt: Manager, Component {
    
    public static let manager: RunIt = RunIt()
    
    /** 
    `Runnable` components will scheduled to run in runOperationQueue on add operation if flag is `true`.
     
    - Warning: If component will be removed before it started to run than it will canceled to run and will never be started or stoped.
     */
    public var runComponentOnAdd: Bool = true
    /// `Runnable` components will scheduled to stop in runOperationQueue on remove operation if flag is `true`
    public var stopComponentOnRemove: Bool = true
    /// Dispatch queue where access is synced. Custom concurrent queue by default. Usually no need to change it.
    lazy public var syncQueue: dispatch_queue_t = dispatch_queue_create("RunIt.SyncQueue", DISPATCH_QUEUE_CONCURRENT)
    /**
    This queue is intended to run/stop components or custom user NSOperation objects. It's possible to change any property of this queue, but with a respect to NSOperationQueue properties change rules (for example, you can't change underlyingQueue while there are operations in queue).
    
    - Warning: It's not recommended to use same underlyingQueue with RunIt.syncQueue for thread-safety.
    */
    lazy public private(set) var runOperationQueue: NSOperationQueue = { return self.createRunQueue() }()
    
    private var components: [String: Component] = [:]
    private var componentsKeysInRunProgress: Set<String> = []
    
    #if DEBUG
    public var suppressAssert: Bool = false
    #endif
    
    private func createRunQueue() -> NSOperationQueue {
        
        let queue = NSOperationQueue()
        queue.underlyingQueue = dispatch_queue_create("RunIt.RunQueue", DISPATCH_QUEUE_CONCURRENT)
        return queue
    }
    
    // MARK: - Add methods -
    public func add(component component: Component) {
        
        let key = String(component.dynamicType)
        add(component: component, forKey: key)
    }
    
    public func add(component component: Component, forKey key: String) {
        
        #if DEBUG
        assert(suppressAssert == false && components[key] != nil, "WARNING! Trying to reassign component with new one! Possible data loss situation.")
        #endif
        dispatch_barrier_async(syncQueue) {
            
            self.components[key] = component
            self.postNotification(RunItDidAddComponentNotification, component: component, key: key)
            
            if self.runComponentOnAdd, let runnable = component as? Runnable where runnable.isRunning == false {
                self.scheduleRunOperation(forRunnableComponent: runnable, andKey: key)
            }
        }
    }
    
    private func scheduleRunOperation(forRunnableComponent component: Runnable, andKey key: String) {
        
        let operation = NSBlockOperation { 
            
            func run() {
                
                var componentStillExists: Bool = false
                dispatch_sync(self.syncQueue, {
                    
                    if let _ = self.components[key] {
                        
                        componentStillExists = true
                        self.componentsKeysInRunProgress.insert(key)
                    } else {
                        
                    }
                })
                if componentStillExists {
                    
                    component.run()
                    dispatch_async(self.syncQueue, {
                        self.componentsKeysInRunProgress.remove(key)
                    })
                    self.postNotification(RunItDidRunComponentNotification, component: component, key: key)
                }
            }
            
            if let runQueue = component.runQueue {
                
                let semaphore = dispatch_semaphore_create(0)
                dispatch_async(runQueue, {
                    
                    run()
                    dispatch_semaphore_signal(semaphore)
                })
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            } else {
                run()
            }
        }
        operation.queuePriority = component.priority
        runOperationQueue.addOperation(operation)
    }
    
    // MARK: - Get methods -
    public func get<T: Component>() -> T? {
        
        let key = String(T.Type)
        return get(componentForKey: key)
    }
        
    public func get<T: Component>(comoponentType: T.Type) -> T? {
        return get(componentForKey: String(comoponentType))
    }
    
    public func get<T : Component>(componentForKey key: String) -> T? {
        
        var component: T? = nil
        dispatch_sync(syncQueue) {
            component = self.components[key] as? T
        }
        return component
    }
    
    // MARK - Remove methods -
    public func remove<T: Component>(component component: T) -> Bool {

        let key = String(component.dynamicType)
        return remove(componentForKey: key)
    }
    
    public func remove<T: Component>(comoponentType: T.Type) -> Bool {
        return remove(componentForKey: String(comoponentType))
    }
    
    public func remove(componentForKey key: String) -> Bool {
        
        var result: Component? = nil
        dispatch_sync(syncQueue) {
            result = self.components.removeValueForKey(key)
        }
        if let component = result {
            
            NSNotificationCenter.defaultCenter().postNotificationName(RunItDidRemoveComponentNotification,
                                                                      object: component,
                                                                      userInfo: [RunItDidRemoveComponentNotification : key])
            if self.stopComponentOnRemove, let runnable = result as? Runnable {
                
                if runnable.isRunning {
                    scheduleStopOperation(forRunnableComponent: runnable, andKey: key)
                } else {
                    
                    var scheduledToRun: Bool = false
                    dispatch_sync(syncQueue, { 
                        scheduledToRun = self.componentsKeysInRunProgress.contains(key) || runnable.isRunning
                    })
                    if scheduledToRun {
                        scheduleStopOperation(forRunnableComponent: runnable, andKey: key)
                    }
                }
            }
            return true
        }
        return false
    }
    
    private func scheduleStopOperation(forRunnableComponent component: Runnable, andKey key: String) {
        
        let operation = NSBlockOperation {
            
            func stop() {

                component.stop()
                self.postNotification(RunItDidStopComponentNotification, component: component, key: key)
            }
            
            if let runQueue = component.runQueue {
                
                let semaphore = dispatch_semaphore_create(0)
                dispatch_async(runQueue, {
                    
                    stop()
                    dispatch_semaphore_signal(semaphore)
                })
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            } else {
                stop()
            }
        }
        operation.queuePriority = component.priority
        runOperationQueue.addOperation(operation)
    }
    
    // MARK: - Post events - 
    private func postNotification(name: String, component: AnyObject, key: String) {
        
        dispatch_async(dispatch_get_main_queue(), {
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: component, userInfo: [RunItNotificaionComponentKeyKey : key])
        })
    }
}
