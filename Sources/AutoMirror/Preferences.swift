import UIKit
import Preferences

class AutoMirrorPreferencesListController: PSListController {
    private var logs: [String] = []
    private let logTextView = UITextView()
    private let logScrollView = UIScrollView()
    
    override var specifiers: NSMutableArray? {
        get {
            if let specifiers = value(forKey: "_specifiers") as? NSMutableArray {
                return specifiers
            } else {
                let specifiers = loadSpecifiers(fromPlistName: "AutoMirror", target: self)
                setValue(specifiers, forKey: "_specifiers")
                return specifiers
            }
        }
        set {
            super.specifiers = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题
        title = "AutoMirror"
        
        // 创建日志视图
        setupLogView()
        
        // 加载日志
        loadLogs()
    }
    
    private func setupLogView() {
        // 创建日志容器
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // 创建日志标题
        let logTitle = UILabel()
        logTitle.text = "日志"
        logTitle.font = .boldSystemFont(ofSize: 17)
        logTitle.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(logTitle)
        
        // 创建日志文本视图
        logTextView.isEditable = false
        logTextView.isScrollEnabled = true
        logTextView.font = .systemFont(ofSize: 12)
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(logTextView)
        
        // 创建清除按钮
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("清除日志", for: .normal)
        clearButton.addTarget(self, action: #selector(clearLogs), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(clearButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            logTitle.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            logTitle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            clearButton.centerYAnchor.constraint(equalTo: logTitle.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            logTextView.topAnchor.constraint(equalTo: logTitle.bottomAnchor, constant: 10),
            logTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadLogs() {
        // 从文件加载日志
        let logPath = "/var/mobile/Library/Preferences/com.zocodo.automirror.log"
        if let logData = try? Data(contentsOf: URL(fileURLWithPath: logPath)),
           let logString = String(data: logData, encoding: .utf8) {
            logs = logString.components(separatedBy: "\n")
            updateLogTextView()
        }
    }
    
    private func updateLogTextView() {
        logTextView.text = logs.joined(separator: "\n")
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: logTextView.contentSize.height - logTextView.bounds.size.height)
        if bottomOffset.y > 0 {
            logTextView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    @objc private func clearLogs() {
        logs.removeAll()
        updateLogTextView()
        // 清空日志文件
        let logPath = "/var/mobile/Library/Preferences/com.zocodo.automirror.log"
        try? "".write(toFile: logPath, atomically: true, encoding: .utf8)
    }
    
    // 保存设置
    override func setPreferenceValue(_ value: Any?, specifier: PSSpecifier?) {
        super.setPreferenceValue(value, specifier: specifier)
        // 通知插件设置已更改
        NotificationCenter.default.post(name: NSNotification.Name("AutoMirrorPreferencesChanged"), object: nil)
    }
} 