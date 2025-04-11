import Foundation
import UIKit
import Preferences
import notify

// 使用 Objective-C 运行时来访问 IOKit 功能
@_silgen_name("IOHIDEventSystemClientCreate")
func IOHIDEventSystemClientCreate(_ allocator: CFAllocator?) -> Unmanaged<AnyObject>?

@_silgen_name("IOHIDEventSystemClientSetMatching")
func IOHIDEventSystemClientSetMatching(_ client: AnyObject, _ matching: CFDictionary?)

class Tweak {
    private var displayNotificationPort: IONotificationPortRef?
    private var displayIterator: io_iterator_t = 0
    private let defaults = UserDefaults(suiteName: "com.zocodo.automirror")
    
    init() {
        // 插件初始化时输出日志
        log("AutoMirror 插件已加载")
        
        // 监听设置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: NSNotification.Name("AutoMirrorPreferencesChanged"),
            object: nil
        )
        
        // 检查是否启用
        if isEnabled() {
            setupDisplayNotification()
        }
    }
    
    private func isEnabled() -> Bool {
        return defaults?.bool(forKey: "enabled") ?? true
    }
    
    private func isLoggingEnabled() -> Bool {
        return defaults?.bool(forKey: "enableLogging") ?? true
    }
    
    @objc private func settingsChanged() {
        if isEnabled() {
            setupDisplayNotification()
            log("插件已启用")
        } else {
            if let port = displayNotificationPort {
                IONotificationPortDestroy(port)
                displayNotificationPort = nil
            }
            log("插件已禁用")
        }
    }
    
    private func log(_ message: String) {
        if isLoggingEnabled() {
            print(message)
            // 写入日志文件
            let logPath = "/var/mobile/Library/Preferences/com.zocodo.automirror.log"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = dateFormatter.string(from: Date())
            let logMessage = "[\(timestamp)] \(message)\n"
            
            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logMessage.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try? logMessage.write(toFile: logPath, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func setupDisplayNotification() {
        let matchingDict = IOServiceMatching("IODisplayConnect")
        displayNotificationPort = IONotificationPortCreate(kIOMasterPortDefault)
        
        IONotificationPortSetDispatchQueue(displayNotificationPort, DispatchQueue.main)
        
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        IOServiceAddMatchingNotification(
            displayNotificationPort,
            kIOMatchedNotification,
            matchingDict,
            displayCallback,
            selfPtr,
            &displayIterator
        )
        
        // 处理已存在的显示器
        processExistingDisplays()
    }
    
    private func processExistingDisplays() {
        var displayService: io_service_t
        while displayIterator != 0 {
            displayService = IOIteratorNext(displayIterator)
            if displayService != 0 {
                handleDisplayConnection(displayService)
                IOObjectRelease(displayService)
            }
        }
    }
    
    private func handleDisplayConnection(_ service: io_service_t) {
        // 获取显示器信息
        var displayID: CGDirectDisplayID = 0
        var displayCount: UInt32 = 0
        
        if CGGetDisplaysWithPoint(CGPoint(x: 0, y: 0), 1, &displayID, &displayCount) == .success {
            if displayCount > 1 {
                // 检测到外接显示器
                log("检测到外接显示器")
                setMirrorMode()
            }
        }
    }
    
    private func showMirrorModeNotification() {
        // 使用 Theos 的标准通知
        let notification = CPNotificationCenter.sharedInstance()
        notification.postNotificationName("AutoMirror_MirrorModeEnabled",
                                        object: nil,
                                        userInfo: nil)
    }
    
    private func setMirrorMode() {
        // 获取所有显示器
        var displayCount: UInt32 = 0
        var onlineDisplays: [CGDirectDisplayID] = Array(repeating: 0, count: Int(16))
        
        if CGGetOnlineDisplayList(16, &onlineDisplays, &displayCount) == .success {
            if displayCount > 1 {
                // 设置镜像模式
                let mainDisplay = onlineDisplays[0]
                let externalDisplay = onlineDisplays[1]
                
                var config: CGDisplayConfigRef?
                if CGBeginDisplayConfiguration(&config) == .success {
                    CGConfigureDisplayMirrorOfDisplay(config, externalDisplay, mainDisplay)
                    if CGCompleteDisplayConfiguration(config, .permanently) == .success {
                        log("已成功设置为镜像模式")
                        // 显示通知
                        showMirrorModeNotification()
                    } else {
                        log("设置镜像模式失败")
                    }
                }
            }
        }
    }
}

// 回调函数
private func displayCallback(_ userData: UnsafeMutableRawPointer?,
                           _ service: io_service_t,
                           _ messageType: natural_t) {
    guard let userData = userData else { return }
    let tweak = Unmanaged<Tweak>.fromOpaque(userData).takeUnretainedValue()
    
    if messageType == kIOMatchedNotification {
        tweak.handleDisplayConnection(service)
    }
}

// 初始化插件
let tweak = Tweak()
