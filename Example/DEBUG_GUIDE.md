# 蓝牙扫描调试指南

## 问题诊断

当点击"开始扫描"无法发现设备时，需要添加调试日志来定位问题。

## 需要修改的代码位置

### 1. 在 `setupBluetooth()` 方法中添加调试（约第 328 行）

**原代码：**
```swift
private func setupBluetooth() {
    centralManager = CBCentralManager(delegate: self, queue: nil)
}
```

**修改为：**
```swift
private func setupBluetooth() {
    print("📱 [DEBUG] setupBluetooth() called")
    centralManager = CBCentralManager(delegate: self, queue: nil)
    print("📱 [DEBUG] Central manager created: \(centralManager != nil ? "Success" : "Failed")")
    print("📱 [DEBUG] Delegate set: \(centralManager?.delegate != nil ? "Yes" : "No")")
    
    // 检查蓝牙权限
    checkBluetoothAuthorization()
    
    addLog("🔧 蓝牙管理器已初始化")
}
```

---

### 2. 增强 `centralManagerDidUpdateState` 方法（约第 630 行）

**原代码：**
```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
        updateStatus("蓝牙已就绪")
    case .poweredOff:
        updateStatus("蓝牙已关闭")
    case .unauthorized:
        updateStatus("蓝牙权限未授权")
    case .unsupported:
        updateStatus("此设备不支持蓝牙")
    default:
        updateStatus("蓝牙状态未知")
    }
}
```

**修改为：**
```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let stateString = debugBluetoothState(central.state)
    print("📱 [DEBUG] centralManagerDidUpdateState: \(stateString)")
    
    // 详细状态日志
    switch central.state {
    case .poweredOn:
        print("✅ [DEBUG] Bluetooth is ON - Ready to scan")
        updateStatus("蓝牙已就绪")
        addLog("✅ 蓝牙已开启，准备就绪")
        
    case .poweredOff:
        print("❌ [DEBUG] Bluetooth is OFF")
        updateStatus("蓝牙已关闭")
        addLog("❌ 蓝牙已关闭，请在设置中开启")
        
    case .unauthorized:
        print("❌ [DEBUG] Bluetooth is UNAUTHORIZED")
        updateStatus("蓝牙权限未授权")
        addLog("❌ 蓝牙权限被拒绝，请在设置中授权")
        
    case .unsupported:
        print("❌ [DEBUG] Bluetooth is UNSUPPORTED on this device")
        updateStatus("此设备不支持蓝牙")
        addLog("❌ 此设备不支持蓝牙")
        
    case .resetting:
        print("🔄 [DEBUG] Bluetooth is RESETTING")
        updateStatus("蓝牙重置中")
        addLog("🔄 蓝牙正在重置")
        
    case .unknown:
        print("❓ [DEBUG] Bluetooth state is UNKNOWN")
        updateStatus("蓝牙状态未知")
        addLog("❓ 蓝牙状态未知")
        
    @unknown default:
        print("❓ [DEBUG] Bluetooth state is UNKNOWN DEFAULT")
        updateStatus("蓝牙状态未知")
        addLog("❓ 蓝牙状态未知")
    }
    
    // 打印详细状态
    debugPrintCentralManagerState()
}
```

---

### 3. 增强 `startScanning()` 方法（约第 445 行）

**原代码：**
```swift
private func startScanning() {
    guard centralManager.state == .poweredOn else {
        updateStatus("蓝牙未开启")
        return
    }
    
    discoveredDevices.removeAll()
    deviceMACMap.removeAll()
    deviceNameMap.removeAll()
    deviceRSSIMap.removeAll()
    macToDeviceMap.removeAll()
    deviceTableView.reloadData()
    deviceTableView.isHidden = false
    
    centralManager.scanForPeripherals(withServices: nil, options: [
        CBCentralManagerScanOptionAllowDuplicatesKey: false
    ])
    
    scanButton.setTitle("停止扫描", for: .normal)
    scanButton.backgroundColor = .systemRed
    updateStatus("正在扫描设备...")
    addLog("开始扫描蓝牙设备")
}
```

**修改为：**
```swift
private func startScanning() {
    print("📱 [DEBUG] ===== startScanning() called =====")
    
    // 详细的蓝牙状态检查
    print("📱 [DEBUG] Checking central manager...")
    print("📱 [DEBUG] centralManager: \(centralManager != nil ? "Not nil" : "NIL!")")
    print("📱 [DEBUG] State: \(debugBluetoothState(centralManager.state))")
    
    // 打印详细状态到 UI
    debugPrintCentralManagerState()
    
    guard centralManager.state == .poweredOn else {
        print("❌ [DEBUG] Bluetooth not powered on! State: \(centralManager.state.rawValue)")
        updateStatus("蓝牙未开启 (状态: \(centralManager.state.rawValue))")
        addLog("❌ 无法扫描: 蓝牙状态 = \(debugBluetoothState(centralManager.state))")
        
        // 提供解决建议
        if centralManager.state == .unauthorized {
            addLog("💡 建议: 请在 设置 > 隐私 > 蓝牙 中授权此应用")
        } else if centralManager.state == .poweredOff {
            addLog("💡 建议: 请在控制中心或设置中开启蓝牙")
        }
        
        return
    }
    
    print("✅ [DEBUG] Bluetooth is powered on, starting scan...")
    
    // 清空旧数据
    discoveredDevices.removeAll()
    deviceMACMap.removeAll()
    deviceNameMap.removeAll()
    deviceRSSIMap.removeAll()
    macToDeviceMap.removeAll()
    deviceTableView.reloadData()
    deviceTableView.isHidden = false
    
    print("📱 [DEBUG] Cleared old device data")
    
    // 记录扫描参数
    logScanParameters()
    
    // 开始扫描
    centralManager.scanForPeripherals(withServices: nil, options: [
        CBCentralManagerScanOptionAllowDuplicatesKey: false
    ])
    
    print("📱 [DEBUG] Scan started")
    print("📱 [DEBUG] isScanning: \(centralManager.isScanning)")
    
    scanButton.setTitle("停止扫描", for: .normal)
    scanButton.backgroundColor = .systemRed
    updateStatus("正在扫描设备...")
    addLog("🔍 开始扫描蓝牙设备")
    addLog("   扫描参数: 所有设备, 不允许重复")
}
```

---

### 4. 增强 `didDiscover` 回调方法（约第 646 行）

**在方法开始处添加：**

```swift
func centralManager(_ central: CBCentralManager, 
                   didDiscover peripheral: CBPeripheral,
                   advertisementData: [String: Any], 
                   rssi RSSI: NSNumber) {
    
    // 添加详细的设备发现日志
    debugPrintDiscoveredDevice(
        peripheral: peripheral,
        advertisementData: advertisementData,
        rssi: RSSI
    )
    
    // 原有代码继续...
    let localName = peripheral.name ?? ""
    // ...
}
```

---

## 测试步骤

1. **编译运行** 确保 `ViewController+Debug.swift` 文件被添加到项目中

2. **查看控制台输出** 在 Xcode 控制台中查找 `[DEBUG]` 标记的日志

3. **检查关键信息**：
   - 蓝牙管理器是否正确初始化
   - 蓝牙状态是否为 `.poweredOn` (5)
   - 扫描是否真正启动 (`isScanning = true`)
   - 是否有设备被发现（查看 `didDiscover` 回调）

## 常见问题

### 问题 1: 状态为 `.unauthorized` (3)
**原因**: 用户拒绝了蓝牙权限  
**解决**: 引导用户到 设置 > 隐私 > 蓝牙 中授权

### 问题 2: 状态为 `.poweredOff` (4)
**原因**: 蓝牙未开启  
**解决**: 引导用户开启蓝牙

### 问题 3: 状态一直为 `.unknown` (0)
**原因**: 蓝牙管理器初始化问题  
**解决**: 
- 检查 `CBCentralManager` 初始化时机
- 确保 delegate 正确设置
- 在真机上测试（模拟器不支持蓝牙）

### 问题 4: 状态为 `.poweredOn` 但扫描不到设备
**可能原因**:
1. 没有附近的蓝牙设备
2. 设备没有在广播
3. iOS 系统缓存问题

**解决方法**:
- 重启手机蓝牙
- 重启测试设备
- 检查目标设备是否正常工作

## 日志示例

正常工作的日志应该类似：

```
📱 [DEBUG] setupBluetooth() called
📱 [DEBUG] Central manager created: Success
📱 [DEBUG] Delegate set: Yes
✅ [DEBUG] Bluetooth authorization: allowedAlways
📱 [DEBUG] centralManagerDidUpdateState: poweredOn (5)
✅ [DEBUG] Bluetooth is ON - Ready to scan
📱 [DEBUG] ===== Central Manager State =====
📱 [DEBUG] State: poweredOn (5)
📱 [DEBUG] isScanning: false
📱 [DEBUG] Delegate: Set
📱 [DEBUG] =================================
📱 [DEBUG] ===== startScanning() called =====
📱 [DEBUG] Checking central manager...
📱 [DEBUG] centralManager: Not nil
📱 [DEBUG] State: poweredOn (5)
✅ [DEBUG] Bluetooth is powered on, starting scan...
📱 [DEBUG] ===== Device Discovered =====
📱 [DEBUG] Name: NordicDevice
📱 [DEBUG] UUID: B9407F30-F5F8-466E-AFF9-25556B57FE6D
📱 [DEBUG] RSSI: -65 dBm
```

## 注意事项

1. **真机测试**: 必须在真机上测试，模拟器不支持蓝牙
2. **权限**: 确保 Info.plist 中配置了蓝牙权限描述
3. **隐私设置**: 检查 iOS 设置中的蓝牙权限
4. **系统蓝牙**: 确保系统蓝牙已开启
5. **设备状态**: 确保目标蓝牙设备正在广播
