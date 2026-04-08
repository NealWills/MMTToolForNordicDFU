#!/bin/bash

# 蓝牙扫描问题诊断脚本
# 用于快速检查项目配置

echo "================================"
echo "蓝牙扫描问题诊断工具"
echo "================================"
echo ""

PROJECT_DIR="/Users/maxeye_neal/Documents/Github/NLPod/MMTToolForNordicDFU/Example"

# 1. 检查 Info.plist 中的蓝牙权限
echo "1️⃣  检查蓝牙权限配置..."
INFO_PLIST="$PROJECT_DIR/MMTToolForNordicDFU/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    echo "   ✅ Info.plist 存在"
    
    # 检查蓝牙权限描述
    if grep -q "NSBluetoothAlwaysUsageDescription" "$INFO_PLIST"; then
        echo "   ✅ NSBluetoothAlwaysUsageDescription 已配置"
    else
        echo "   ❌ 缺少 NSBluetoothAlwaysUsageDescription"
    fi
    
    if grep -q "NSBluetoothPeripheralUsageDescription" "$INFO_PLIST"; then
        echo "   ✅ NSBluetoothPeripheralUsageDescription 已配置"
    else
        echo "   ⚠️  缺少 NSBluetoothPeripheralUsageDescription (iOS 13 以下需要)"
    fi
else
    echo "   ❌ Info.plist 不存在"
fi

echo ""

# 2. 检查 ViewController.swift
echo "2️⃣  检查 ViewController.swift..."
VIEWCONTROLLER="$PROJECT_DIR/MMTToolForNordicDFU/ViewController.swift"

if [ -f "$VIEWCONTROLLER" ]; then
    echo "   ✅ ViewController.swift 存在"
    
    # 检查文件大小
    SIZE=$(stat -f%z "$VIEWCONTROLLER" 2>/dev/null || stat -c%s "$VIEWCONTROLLER" 2>/dev/null)
    echo "   📄 文件大小: $SIZE bytes"
    
    # 检查是否为加密文件
    if head -c 20 "$VIEWCONTROLLER" | grep -q "TSD-Header"; then
        echo "   ⚠️  文件已加密（TSD 格式）"
        echo "   💡 建议: 需要解密后才能查看和修改代码"
    else
        echo "   ✅ 文件未加密"
        
        # 检查关键代码
        if grep -q "CBCentralManager" "$VIEWCONTROLLER"; then
            echo "   ✅ 包含 CBCentralManager 代码"
        else
            echo "   ❌ 未找到 CBCentralManager"
        fi
        
        if grep -q "CBCentralManagerDelegate" "$VIEWCONTROLLER"; then
            echo "   ✅ 实现了 CBCentralManagerDelegate"
        else
            echo "   ❌ 未实现 CBCentralManagerDelegate"
        fi
    fi
else
    echo "   ❌ ViewController.swift 不存在"
fi

echo ""

# 3. 检查调试辅助文件
echo "3️⃣  检查调试文件..."
DEBUG_FILE="$PROJECT_DIR/MMTToolForNordicDFU/ViewController+Debug.swift"

if [ -f "$DEBUG_FILE" ]; then
    echo "   ✅ ViewController+Debug.swift 已创建"
else
    echo "   ⚠️  ViewController+Debug.swift 未创建"
fi

DEBUG_GUIDE="$PROJECT_DIR/DEBUG_GUIDE.md"
if [ -f "$DEBUG_GUIDE" ]; then
    echo "   ✅ DEBUG_GUIDE.md 已创建"
else
    echo "   ⚠️  DEBUG_GUIDE.md 未创建"
fi

echo ""

# 4. 检查 Podfile 配置
echo "4️⃣  检查依赖配置..."
PODFILE="$PROJECT_DIR/Podfile"

if [ -f "$PODFILE" ]; then
    echo "   ✅ Podfile 存在"
    
    if grep -q "MMTToolForNordicDFU" "$PODFILE"; then
        echo "   ✅ MMTToolForNordicDFU 依赖已配置"
    fi
    
    if grep -q "CoreBluetooth" "$PODFILE"; then
        echo "   ⚠️  CoreBluetooth 是系统框架，不需要在 Podfile 中添加"
    fi
else
    echo "   ❌ Podfile 不存在"
fi

echo ""

# 5. 检查 Xcode 项目
echo "5️⃣  检查 Xcode 项目..."
XCWORKSPACE="$PROJECT_DIR/MMTToolForNordicDFU.xcworkspace"

if [ -d "$XCWORKSPACE" ]; then
    echo "   ✅ .xcworkspace 存在（使用 CocoaPods）"
    echo "   💡 请打开 .xcworkspace 而不是 .xcodeproj"
else
    echo "   ⚠️  .xcworkspace 不存在"
    echo "   💡 可能需要运行: cd Example && pod install"
fi

echo ""
echo "================================"
echo "诊断完成"
echo "================================"
echo ""
echo "下一步操作："
echo "1. 如果文件已加密，需要先解密"
echo "2. 按照 DEBUG_GUIDE.md 修改代码添加调试日志"
echo "3. 在真机上运行（模拟器不支持蓝牙）"
echo "4. 查看 Xcode 控制台的 [DEBUG] 日志"
echo ""
