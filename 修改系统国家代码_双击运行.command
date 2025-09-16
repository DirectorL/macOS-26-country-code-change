#!/bin/bash

# 定义文件路径
FILE_PATH="/private/var/db/com.apple.countryd/countryCodeCache.plist"

# 函数：记录日志
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查是否是以修改模式启动
if [ "$1" = "--modify" ]; then
    CURRENT="$2"
    
    log_message "开始修改配置，当前值: $CURRENT"
    
    # 确定目标配置
    if [ "$CURRENT" = "CN" ]; then
        TARGET="US"
        log_message "将把配置从 CN 改为 US"
    elif [ "$CURRENT" = "US" ]; then
        TARGET="CN"
        log_message "将把配置从 US 改为 CN"
    else
        log_message "错误: 无法确定当前配置，无法继续"
        exit 1
    fi
    
    # 定义备份路径
    BACKUP_PATH="/private/var/db/com.apple.countryd/countryCodeCache.plist.backup"
    
    # 备份原文件
    log_message "正在备份原文件..."
    cp "$FILE_PATH" "$BACKUP_PATH"
    if [ $? -ne 0 ]; then
        log_message "错误: 无法创建备份文件"
        exit 1
    fi
    
    # 解锁文件
    log_message "正在解锁文件..."
    chflags nouchg "$FILE_PATH"
    if [ $? -ne 0 ]; then
        log_message "错误: 无法解锁文件"
        exit 1
    fi
    
    # 修改文件内容
    log_message "正在修改文件内容..."
    sed -i '' "101s/$CURRENT/$TARGET/g" "$FILE_PATH"
    if [ $? -ne 0 ]; then
        log_message "错误: 无法修改文件内容"
        # 尝试恢复备份
        mv "$BACKUP_PATH" "$FILE_PATH"
        chflags uchg "$FILE_PATH"
        exit 1
    fi
    
    # 重新锁定文件
    log_message "正在重新锁定文件..."
    chflags uchg "$FILE_PATH"
    if [ $? -ne 0 ]; then
        log_message "警告: 无法重新锁定文件，但修改已完成"
    fi
    
    # 验证修改
    log_message "正在验证修改..."
    chflags nouchg "$FILE_PATH" 2>/dev/null
    new_content=$(sed -n '101p' "$FILE_PATH" 2>/dev/null)
    chflags uchg "$FILE_PATH" 2>/dev/null
    
    if echo "$new_content" | grep -q "$TARGET"; then
        log_message "修改成功! 当前配置已改为 $TARGET"
    else
        log_message "警告: 修改可能未成功，文件内容: $new_content"
        exit 1
    fi
    
    # 删除备份文件
    rm -f "$BACKUP_PATH"
    
    log_message "操作完成!"
    exit 0
fi

# 函数：显示当前配置
show_current_config() {
    log_message "正在检查当前配置..."
    
    # 尝试直接读取文件内容
    if [ -f "$FILE_PATH" ]; then
        # 使用sed尝试读取第101行
        line_content=$(sed -n '101p' "$FILE_PATH" 2>/dev/null)
        
        if [ -n "$line_content" ]; then
            # 检查是否包含CN或US
            if echo "$line_content" | grep -q "CN"; then
                log_message "当前配置: CN (中国)"
                CURRENT="CN"
                return 0
            elif echo "$line_content" | grep -q "US"; then
                log_message "当前配置: US (美国)"
                CURRENT="US"
                return 0
            else
                log_message "检测到文件，但无法确定国家代码"
                log_message "文件内容: $line_content"
                CURRENT="UNKNOWN"
                return 1
            fi
        else
            log_message "无法读取文件内容，可能需要管理员权限"
            CURRENT="UNKNOWN"
            return 1
        fi
    else
        log_message "错误: 文件不存在 - $FILE_PATH"
        CURRENT="UNKNOWN"
        return 1
    fi
}

# 主程序
log_message "========================================"
log_message "    Mac系统国家代码配置修改工具"
log_message "========================================"

# 显示当前配置
if show_current_config; then
    log_message ""
    read -p "是否要切换配置? (y/n): " -n 1 -r
    log_message ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_message "开始修改配置..."
        log_message "需要管理员权限来修改系统配置..."
        # 使用sudo重新调用脚本，并传递参数
        sudo "$0" --modify "$CURRENT"
    else
        log_message "已取消操作"
    fi
else
    log_message "无法确定当前配置，可能需要管理员权限查看"
    read -p "是否尝试使用管理员权限查看? (y/n): " -n 1 -r
    log_message ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 使用sudo尝试查看
        sudo -p "请输入管理员密码以查看配置: " sed -n '101p' "$FILE_PATH" 2>/dev/null
    else
        log_message "已取消操作"
    fi
fi

log_message ""
log_message "========================================"