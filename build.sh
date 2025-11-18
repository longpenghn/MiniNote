#!/bin/bash

# 极简笔记应用构建脚本

echo "🚀 极简笔记应用构建工具"
echo "=========================="

# 检查参数
if [ $# -eq 0 ]; then
    echo "使用方法:"
    echo "  $0 debug    - 构建 Debug 版本"
    echo "  $0 release  - 构建 Release 版本"
    echo "  $0 clean    - 清理构建文件"
    exit 1
fi

case $1 in
    "debug")
        echo "📱 构建 Debug 版本..."
        hvigorw assembleHap
        if [ $? -eq 0 ]; then
            echo "✅ Debug 版本构建成功！"
            echo "📦 输出文件: build/outputs/default/entry-default-unsigned.hap"
        else
            echo "❌ Debug 版本构建失败！"
            exit 1
        fi
        ;;
    "release")
        echo "🏭 构建 Release 版本..."
        hvigorw assembleHap --mode release
        if [ $? -eq 0 ]; then
            echo "✅ Release 版本构建成功！"
            echo "📦 输出文件: build/outputs/release/entry-release-signed.hap"
        else
            echo "❌ Release 版本构建失败！"
            echo "💡 请检查证书配置是否正确"
            exit 1
        fi
        ;;
    "clean")
        echo "🧹 清理构建文件..."
        hvigorw clean
        if [ $? -eq 0 ]; then
            echo "✅ 清理完成！"
        else
            echo "❌ 清理失败！"
            exit 1
        fi
        ;;
    *)
        echo "❌ 未知参数: $1"
        echo "支持的参数: debug, release, clean"
        exit 1
        ;;
esac