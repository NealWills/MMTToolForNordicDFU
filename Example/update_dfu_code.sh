#!/bin/bash

# DFU 功能更新脚本
# 用于自动修改 ViewController.swift 中的 TODO 和方法名

echo "================================"
echo "DFU 功能更新工具"
echo "================================"
echo ""

PROJECT_DIR="/Users/maxeye_neal/Documents/Github/NLPod/MMTToolForNordicDFU"
VIEWCONTROLLER="$PROJECT_DIR/Example/MMTToolForNordicDFU/ViewController.swift"

# 检查文件是否存在
if [ ! -f "$VIEWCONTROLLER" ]; then
    echo "❌ ViewController.swift 不存在"
    exit 1
fi

# 检查文件是否加密
if head -c 20 "$VIEWCONTROLLER" | grep -q "TSD-Header"; then
    echo "⚠️  检测到文件已加密（TSD 格式）"
    echo ""
    echo "选择操作方式："
    echo "1. 解密后修改（需要解密工具）"
    echo "2. 使用 git 原始版本修改"
    echo "3. 手动修改"
    echo ""
    read -p "请选择 [1-3]: " choice

    case $choice in
        1)
            echo "请先解密文件，然后重新运行此脚本"
            exit 0
            ;;
        2)
            echo ""
            echo "正在从 git 获取原始版本..."
            cd "$PROJECT_DIR"
            git show HEAD:Example/MMTToolForNordicDFU/ViewController.swift > /tmp/ViewController_original.swift
            
            if [ $? -eq 0 ]; then
                echo "✅ 原始文件已保存到: /tmp/ViewController_original.swift"
                echo ""
                echo "开始修改..."
                
                # 创建备份
                cp /tmp/ViewController_original.swift /tmp/ViewController_backup.swift
                
                # 修改 1: 移除 TODO 注释
                sed -i '' 's/\/\/ TODO: 实现 DFU 功能/\/\/ 执行 DFU 升级/g' /tmp/ViewController_original.swift
                
                # 修改 2: 更新注释
                sed -i '' 's/DFU按钮点击事件 - 预留功能/DFU按钮点击事件/g' /tmp/ViewController_original.swift
                
                # 修改 3: 重命名方法调用
                sed -i '' 's/showDFUAlert()/performDFUUpgrade()/g' /tmp/ViewController_original.swift
                
                # 修改 4: 重命名方法定义
                sed -i '' 's/private func showDFUAlert()/private func performDFUUpgrade()/g' /tmp/ViewController_original.swift
                
                # 修改 5: 添加注释
                sed -i '' 's/private func performDFUUpgrade() {/private func performDFUUpgrade() {\n        \/\/ - Description: 检查前置条件并启动 DFU 升级流程/g' /tmp/ViewController_original.swift
                
                echo "✅ 修改完成！"
                echo ""
                echo "修改内容："
                echo "  ✓ 移除 TODO 注释"
                echo "  ✓ 更新方法注释"
                echo "  ✓ 重命名 showDFUAlert -> performDFUUpgrade"
                echo ""
                echo "修改后的文件：/tmp/ViewController_original.swift"
                echo "备份文件：/tmp/ViewController_backup.swift"
                echo ""
                echo "下一步："
                echo "1. 检查修改后的文件"
                echo "2. 替换原文件: cp /tmp/ViewController_original.swift \"$VIEWCONTROLLER\""
                echo "3. 编译测试"
            else
                echo "❌ 获取原始文件失败"
                exit 1
            fi
            ;;
        3)
            echo ""
            echo "请手动修改以下内容："
            echo ""
            echo "1. 找到约第 420 行的 dfuButtonTapped 方法："
            echo "   - 删除: // TODO: 实现 DFU 功能"
            echo "   - 修改注释: 'DFU按钮点击事件 - 预留功能' -> 'DFU按钮点击事件'"
            echo "   - 修改调用: showDFUAlert() -> performDFUUpgrade()"
            echo ""
            echo "2. 找到约第 568 行的 showDFUAlert 方法："
            echo "   - 重命名: showDFUAlert -> performDFUUpgrade"
            echo "   - 添加注释: /// 执行 DFU 升级"
            echo ""
            echo "详细指南请查看: DFU_UPDATE_GUIDE.md"
            exit 0
            ;;
        *)
            echo "无效选择"
            exit 1
            ;;
    esac
else
    echo "✅ 文件未加密，可以直接修改"
    echo ""
    
    # 创建备份
    cp "$VIEWCONTROLLER" "${VIEWCONTROLLER}.backup"
    echo "✅ 备份已创建: ${VIEWCONTROLLER}.backup"
    
    # 执行修改
    echo "开始修改..."
    
    # macOS 的 sed 命令需要 -i '' 参数
    # 修改 1: 移除 TODO 注释
    sed -i '' 's/\/\/ TODO: 实现 DFU 功能/\/\/ 执行 DFU 升级/g' "$VIEWCONTROLLER"
    
    # 修改 2: 更新注释
    sed -i '' 's/DFU按钮点击事件 - 预留功能/DFU按钮点击事件/g' "$VIEWCONTROLLER"
    
    # 修改 3: 重命名方法调用
    sed -i '' 's/showDFUAlert()/performDFUUpgrade()/g' "$VIEWCONTROLLER"
    
    # 修改 4: 重命名方法定义
    sed -i '' 's/private func showDFUAlert()/private func performDFUUpgrade()/g' "$VIEWCONTROLLER"
    
    echo "✅ 修改完成！"
    echo ""
    echo "修改内容："
    echo "  ✓ 移除 TODO 注释"
    echo "  ✓ 更新方法注释"
    echo "  ✓ 重命名 showDFUAlert -> performDFUUpgrade"
    echo ""
    echo "下一步："
    echo "1. 检查修改是否正确"
    echo "2. 编译项目测试"
    echo "3. 如有问题，恢复备份: cp \"${VIEWCONTROLLER}.backup\" \"$VIEWCONTROLLER\""
fi

echo ""
echo "================================"
echo "更新完成"
echo "================================"
