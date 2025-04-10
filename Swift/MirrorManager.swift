import UIKit
import IOKit
import IOKit.graphics

// 定义匹配 IOKit 显示器属性的键（注意大小写需与实际匹配）
let kDisplayVendorIDKey = "DisplayVendorID"
let kDisplayProductIDKey = "DisplayProductID"

@objc class MirrorManager: NSObject {
    @objc static let shared = MirrorManager()
    
    private override init() {
        super.init()
    }
    
    @objc func startObserving() {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(screenDidConnect(notification:)),
                           name: UIScreen.didConnectNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(screenDidDisconnect(notification:)),
                           name: UIScreen.didDisconnectNotification,
                           object: nil)
        
        // 如设备已连接多个屏幕，初始化时也可尝试开启镜像
        if UIScreen.screens.count >= 2 {
            activateMirroring(for: UIScreen.screens)
        }
    }
    
    @objc private func screenDidConnect(notification: Notification) {
        guard let newScreen = notification.object as? UIScreen else { return }
        NSLog("[ThunderMirror] 屏幕连接: \(newScreen)")
        // 当屏幕连接后，如果有两个或更多屏幕，检测是否为雷电接口设备
        let screens = UIScreen.screens
        if screens.count >= 2,
           isThunderboltDisplay(screen: newScreen) {
            activateMirroring(for: screens)
        }
    }
    
    @objc private func screenDidDisconnect(notification: Notification) {
        NSLog("[ThunderMirror] 屏幕断开")
        // 根据需求可以关闭或恢复镜像模式
    }
    
    /// 检测该 UIScreen 是否通过雷电接口连接（依赖 _displayID 与 IOKit 查询）
    private func isThunderboltDisplay(screen: UIScreen) -> Bool {
        // 获取屏幕内部 _displayID（私有属性）
        guard let displayIDNumber = screen.value(forKey: "_displayID") as? NSNumber else {
            NSLog("[ThunderMirror] 无法获取 _displayID")
            return false
        }
        let displayID = CGDirectDisplayID(displayIDNumber.uint32Value)
        // 通过 IOKit 查找该显示器的服务句柄
        guard let service = servicePort(forDisplayID: displayID) else {
            NSLog("[ThunderMirror] 未匹配到 IOKit 服务")
            return false
        }
        // 获取显示器信息字典（使用 kIODisplayOnlyPreferredName 只返回首选名称信息）
        let infoDict = IODisplayCreateInfoDictionary(service, kIODisplayOnlyPreferredName).takeRetainedValue() as NSDictionary
        
        if let transport = infoDict["Transport"] as? String {
            NSLog("[ThunderMirror] Transport 属性: \(transport)")
            if transport.contains("Thunderbolt") {
                return true
            }
        }
        return false
    }
    
    /// 利用 IOKit 获取与给定 displayID 对应的 service 句柄
    private func servicePort(forDisplayID displayID: CGDirectDisplayID) -> io_service_t? {
        guard let matching = IOServiceMatching("IODisplayConnect") else { return nil }
        var iter: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iter)
        if kr != KERN_SUCCESS {
            return nil
        }
        var service: io_service_t? = nil
        repeat {
            let currentService = IOIteratorNext(iter)
            if currentService == 0 { break }
            // 通过 IODisplayCreateInfoDictionary 获取该服务的信息字典，检查是否包含有效的 VendorID 与 ProductID
            if let info = IODisplayCreateInfoDictionary(currentService, 0)?.takeRetainedValue() as? [String: Any] {
                if let vendor = info[kDisplayVendorIDKey] as? Int,
                   let product = info[kDisplayProductIDKey] as? Int {
                    // 此处的匹配条件仅作示例，实际应根据 displayID 对应的 vendor/product 判断
                    service = currentService
                    break
                }
            }
            IOObjectRelease(currentService)
        } while true
        IOObjectRelease(iter)
        return service
    }
    
    /// 开启镜像模式：调用 UIScreen 的私有方法 setMirroredScreen:
    private func activateMirroring(for screens: [UIScreen]) {
        guard let primaryScreen = screens.first, screens.count >= 2 else {
            NSLog("[ThunderMirror] 屏幕数量不足")
            return
        }
        let secondaryScreen = screens[1]
        let selector = Selector(("setMirroredScreen:"))
        if primaryScreen.responds(to: selector) {
            primaryScreen.perform(selector, with: secondaryScreen)
            NSLog("[ThunderMirror] 开启镜像模式：主屏 \(primaryScreen) 镜像至外接屏 \(secondaryScreen)")
        } else {
            NSLog("[ThunderMirror] 主屏幕不支持 setMirroredScreen:")
        }
    }
}
