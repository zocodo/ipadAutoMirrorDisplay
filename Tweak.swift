// Tweak.swift
import UIKit
import Foundation

// 私有接口声明
class SBExternalDisplayManager {
    static let sharedInstance = SBExternalDisplayManager()
    
    func setWantsExtendedDisplay(_ extend: Bool) {
        // 实现设置扩展显示的逻辑
    }
}

// 读取配置
func isMirrorModeEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "mirrorMode")
}

func isLoggingEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "logEnabled")
}

func logIfEnabled(_ format: String, _ args: CVarArg...) {
    guard isLoggingEnabled() else { return }
    let logMessage = String(format: "[AutoMirrorDisplay] \(format)", arguments: args)
    print(logMessage)
}

// Hook SpringBoard
class SpringBoard {
    func applicationDidFinishLaunching(_ application: Any) {
        // ... existing code ...
        
        let mirror = isMirrorModeEnabled()
        let mgr = SBExternalDisplayManager.sharedInstance
        // mirror==true 时要镜像，内部 API 用 setWantsExtendedDisplay(false)；mirror==false 时扩展，用 true
        mgr.setWantsExtendedDisplay(!mirror)

        logIfEnabled("Display mode set to %@", mirror ? "Mirror" : "Extend")
        
        // ... existing code ...
    }
}