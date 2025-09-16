#!/bin/bash

# 定义文件路径
FILE_PATH="/private/var/db/com.apple.countryd/countryCodeCache.plist"

# 尝试读取文件内容
if [ -f "$FILE_PATH" ]; then
    # 临时解锁文件以读取内容（可能需要密码，但查看配置通常不需修改权限，这里先尝试读取）
    line_content=$(sudo sed -n '101p' "$FILE_PATH" 2>/dev/null | grep -oE '(CN|US)' || sed -n '101p' "$FILE_PATH" 2>/dev/null | grep -oE '(CN|US)')
    
    if echo "$line_content" | grep -q "CN"; then
        echo "CN"
    elif echo "$line_content" | grep -q "US"; then
        echo "US"
    else
        echo "UNKNOWN"
    fi
else
    echo "FILE_NOT_FOUND"
fi