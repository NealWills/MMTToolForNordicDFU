//
//  ViewController+Debug.swift
//  MMTToolForNordicDFU_Example
//
//  Debug extensions for ViewController
//

import Foundation
import CoreBluetooth

// MARK: - Debug Helper Extensions
extension ViewController {
    
    /// 获取蓝牙状态的字符串描述
    func debugBluetoothState(_ state: CBManagerState) -> String {
        switch state {
        case .unknown:
            return "unknown (0)"
        case .resetting:
            return "resetting (1)"
        case .unsupported:
            return "unsupported (2)"
        case .unauthorized:
            return "unauthorized (3)"
        case .poweredOff:
            return "poweredOff (4)"
        case .poweredOn:
            return "poweredOn (5)"
        @unknown default:
            return "unknown default (\(state.rawValue))"
        }
    }
    
    /// 打印当前蓝牙管理器状态（用于调试）
    func debugPrintCentralManagerState() {
        guard let central = self.value(forKey: "centralManager") as? CBCentralManager else {
            print("❌ [DEBUG] centralManager is nil!")
            return
        }
        
        print("📱 [DEBUG] ===== Central Manager State =====")
        print("📱 [DEBUG] State: \(debugBluetoothState(central.state))")
        print("📱 [DEBUG] isScanning: \(central.isScanning)")
        print("📱 [DEBUG] Delegate: \(central.delegate != nil ? "Set" : "Nil")")
        print("📱 [DEBUG] =================================")
        
        // 同时添加到 UI 日志
        addLog("🔍 [调试] 蓝牙状态: \(debugBluetoothState(central.state))")
        addLog("🔍 [调试] 是否扫描中: \(central.isScanning)")
    }
    
    /// 打印设备发现详情（用于调试）
    func debugPrintDiscoveredDevice(
        peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        print("📱 [DEBUG] ===== Device Discovered =====")
        print("📱 [DEBUG] Name: \(peripheral.name ?? "nil")")
        print("📱 [DEBUG] UUID: \(peripheral.identifier.uuidString)")
        print("📱 [DEBUG] RSSI: \(RSSI) dBm")
        
        // 打印广播数据
        print("📱 [DEBUG] --- Advertisement Data ---")
        for (key, value) in advertisementData {
            print("📱 [DEBUG] \(key): \(value)")
        }
        
        // 特别处理 MAC 地址
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let hexString = manufacturerData.map { String(format: "%02x", $0) }.joined(separator: ":")
            print("📱 [DEBUG] Manufacturer Data (Hex): \(hexString.uppercased())")
        }
        
        print("📱 [DEBUG] ==============================")
    }
}

// MARK: - Detailed Logging Extensions
extension ViewController {
    
    /// 检查并记录蓝牙权限状态
    func checkBluetoothAuthorization() {
        print("📱 [DEBUG] ===== Checking Bluetooth Authorization =====")
        
        // 检查蓝牙权限
        if #available(iOS 13.1, *) {
            CBManager.authorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .allowedAlways:
                        print("✅ [DEBUG] Bluetooth authorization: allowedAlways")
                        self.addLog("✅ 蓝牙权限: 已授权")
                    case .denied:
                        print("❌ [DEBUG] Bluetooth authorization: denied")
                        self.addLog("❌ 蓝牙权限: 被拒绝")
                    case .notDetermined:
                        print("⚠️ [DEBUG] Bluetooth authorization: notDetermined")
                        self.addLog("⚠️ 蓝牙权限: 未确定")
                    case .restricted:
                        print("⚠️ [DEBUG] Bluetooth authorization: restricted")
                        self.addLog("⚠️ 蓝牙权限: 受限制")
                    @unknown default:
                        print("❓ [DEBUG] Bluetooth authorization: unknown")
                        self.addLog("❓ 蓝牙权限: 未知")
                    }
                }
            }
        } else {
            print("📱 [DEBUG] iOS < 13.1, skipping authorization check")
        }
    }
    
    /// 记录扫描参数
    func logScanParameters() {
        print("📱 [DEBUG] ===== Scan Parameters =====")
        print("📱 [DEBUG] Services: nil (scan all)")
        print("📱 [DEBUG] Allow Duplicates: false")
        print("📱 [DEBUG] =============================")
    }
}
