import Orion
import UIKit

class DisplayManager: NSObject {
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidConnect), name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidDisconnect), name: UIScreen.didDisconnectNotification, object: nil)
    }

    @objc func screenDidConnect(notification: Notification) {
        setDisplayToMirrorMode()
    }

    @objc func screenDidDisconnect(notification: Notification) {
        // 处理显示器断开连接的逻辑
    }

    func setDisplayToMirrorMode() {
        guard let displayManagerClass = NSClassFromString("SBExternalDisplayManager") as? NSObject.Type,
              let sharedInstance = displayManagerClass.perform(NSSelectorFromString("sharedInstance"))?.takeUnretainedValue() else {
            return
        }

        let selector = NSSelectorFromString("setWantsExtendedDisplay:")
        if sharedInstance.responds(to: selector) {
            sharedInstance.perform(selector, with: false)
        }
    }
}
