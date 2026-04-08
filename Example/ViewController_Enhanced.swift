//
//  ViewController_Test.swift
//  MMTToolForNordicDFU_Example
//
//  快速测试版本 - 包含详细调试日志
//  用法：将此文件内容替换到 ViewController.swift 中
//

import UIKit
import CoreBluetooth
import MMTToolForNordicDFU

class ViewController: UIViewController {

    // MARK: - UI Components

    private lazy var scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始扫描", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备就绪"
        label.textAlignment = .center
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    private lazy var deviceTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.isHidden = true
        return tableView
    }()

    private lazy var debugTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.isEditable = false
        textView.text = "调试日志:\n"
        return textView
    }()

    // MARK: - Properties

    private var centralManager: CBCentralManager!
    private var discoveredDevices: [CBPeripheral] = []
    private var deviceNames: [UUID: String] = [:]
    private var isScanning = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBluetooth()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scanButton)
        view.addSubview(statusLabel)
        view.addSubview(deviceTableView)
        view.addSubview(debugTextView)

        scanButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceTableView.translatesAutoresizingMaskIntoConstraints = false
        debugTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scanButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 200),
            scanButton.heightAnchor.constraint(equalToConstant: 44),

            statusLabel.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            deviceTableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            deviceTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            deviceTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deviceTableView.heightAnchor.constraint(equalToConstant: 200),

            debugTextView.topAnchor.constraint(equalTo: deviceTableView.bottomAnchor, constant: 20),
            debugTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            debugTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupBluetooth() {
        logDebug("🔧 初始化蓝牙管理器...")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        logDebug("✅ 蓝牙管理器创建: \(centralManager != nil ? "成功" : "失败")")
        logDebug("   Delegate: \(centralManager.delegate != nil ? "已设置" : "未设置")")
    }

    // MARK: - Actions

    @objc private func scanButtonTapped() {
        logDebug("")
        logDebug("=== 按钮点击 ===")

        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }

    private func startScanning() {
        logDebug("🔍 准备开始扫描...")

        // 1. 检查 centralManager
        logDebug("   CentralManager: \(centralManager != nil ? "存在" : "NIL!")")

        // 2. 检查蓝牙状态
        let state = centralManager.state
        logDebug("   蓝牙状态: \(state.rawValue) (\(stateDescription(state)))")

        // 3. 状态判断
        guard centralManager.state == .poweredOn else {
            logDebug("❌ 无法扫描: 蓝牙未开启")
            statusLabel.text = "蓝牙未开启 (状态: \(state.rawValue))"
            showErrorAlert()
            return
        }

        // 4. 开始扫描
        logDebug("✅ 蓝牙已开启，开始扫描...")
        discoveredDevices.removeAll()
        deviceNames.removeAll()
        deviceTableView.reloadData()
        deviceTableView.isHidden = false

        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])

        logDebug("   isScanning: \(centralManager.isScanning)")

        isScanning = true
        scanButton.setTitle("停止扫描", for: .normal)
        scanButton.backgroundColor = .systemRed
        statusLabel.text = "正在扫描设备..."
    }

    private func stopScanning() {
        logDebug("⏹️ 停止扫描")
        centralManager.stopScan()
        isScanning = false
        scanButton.setTitle("开始扫描", for: .normal)
        scanButton.backgroundColor = .systemBlue
        statusLabel.text = "已停止扫描，发现 \(discoveredDevices.count) 个设备"
    }

    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "蓝牙问题",
            message: "蓝牙状态: \(stateDescription(centralManager.state))\n请检查:\n1. 蓝牙是否开启\n2. 应用是否有蓝牙权限",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .unknown: return "未知"
        case .resetting: return "重置中"
        case .unsupported: return "不支持"
        case .unauthorized: return "未授权"
        case .poweredOff: return "已关闭"
        case .poweredOn: return "已开启"
        @unknown default: return "未知"
        }
    }

    private func logDebug(_ message: String) {
        print("📱 \(message)")

        DispatchQueue.main.async {
            self.debugTextView.text += message + "\n"

            // 滚动到底部
            let range = NSRange(location: self.debugTextView.text.count - 1, length: 1)
            self.debugTextView.scrollRangeToVisible(range)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        logDebug("")
        logDebug("=== 蓝牙状态更新 ===")
        logDebug("   新状态: \(state.rawValue) (\(stateDescription(state)))")

        switch state {
        case .poweredOn:
            logDebug("✅ 蓝牙已就绪")
            statusLabel.text = "蓝牙已就绪"

        case .poweredOff:
            logDebug("❌ 蓝牙已关闭")
            statusLabel.text = "蓝牙已关闭，请开启蓝牙"

        case .unauthorized:
            logDebug("❌ 蓝牙权限被拒绝")
            statusLabel.text = "蓝牙权限被拒绝"

        case .unsupported:
            logDebug("❌ 设备不支持蓝牙")
            statusLabel.text = "此设备不支持蓝牙"

        default:
            logDebug("⚠️ 其他状态: \(state.rawValue)")
            statusLabel.text = "蓝牙状态: \(stateDescription(state))"
        }
    }

    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any],
                       rssi RSSI: NSNumber) {

        logDebug("")
        logDebug("=== 发现设备 ===")
        logDebug("   名称: \(peripheral.name ?? "未知")")
        logDebug("   UUID: \(peripheral.identifier.uuidString)")
        logDebug("   RSSI: \(RSSI) dBm")

        // 打印广播数据
        logDebug("   广播数据:")
        for (key, value) in advertisementData {
            logDebug("     \(key): \(value)")
        }

        // 添加到列表
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
            deviceNames[peripheral.identifier] = peripheral.name ?? "未知设备"
            deviceTableView.reloadData()
            statusLabel.text = "发现 \(discoveredDevices.count) 个设备"
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let device = discoveredDevices[indexPath.row]
        let name = deviceNames[device.identifier] ?? "未知"
        cell.textLabel?.text = "\(name) - \(device.identifier.uuidString.prefix(8))"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let device = discoveredDevices[indexPath.row]
        logDebug("选中设备: \(device.name ?? "未知")")
    }
}
