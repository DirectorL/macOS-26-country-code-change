#!/bin/bash

# 设置日志文件路径
LOG_FILE="$HOME/Library/Logs/CountryCodeModifier.log"

# 记录开始时间
echo "=== 国家代码修改脚本运行于 $(date) ===" >> "$LOG_FILE"
echo "开始执行国家代码切换操作" | tee -a "$LOG_FILE"

# 定义文件路径
FILE_PATH="/private/var/db/com.apple.countryd/countryCodeCache.plist"
BACKUP_PATH="/private/var/db/com.apple.countryd/countryCodeCache.plist.backup"

# 临时文件用于存储修改结果
TEMP_RESULT_FILE="/tmp/country_code_result.txt"

# 清空临时文件
rm -f "$TEMP_RESULT_FILE"

# 执行切换操作（只需一次sudo验证）
sudo bash -c '
    # 定义变量
    FILE_PATH='"'$FILE_PATH'"'
    BACKUP_PATH='"'$BACKUP_PATH'"'
    LOG_FILE='"'$LOG_FILE'"'
    TEMP_RESULT_FILE='"'$TEMP_RESULT_FILE'"'
    
    # 备份原文件
    echo "正在备份原文件..." >> "$LOG_FILE"
    cp "$FILE_PATH" "$BACKUP_PATH" 2>/dev/null || echo "警告: 备份可能失败" >> "$LOG_FILE"
    
    # 解锁文件
    echo "正在解锁文件..." >> "$LOG_FILE"
    chflags nouchg "$FILE_PATH" 2>/dev/null || echo "错误: 无法解锁文件" >> "$LOG_FILE"
    
    # 检测当前配置并确定目标配置
    echo "正在检测当前配置..." >> "$LOG_FILE"
    if grep -q "CN" "$FILE_PATH"; then
        CURRENT="CN"
        TARGET="US"
        echo "当前配置为CN，将修改为US" >> "$LOG_FILE"
    else
        CURRENT="US"
        TARGET="CN"
        echo "当前配置为US，将修改为CN" >> "$LOG_FILE"
    fi
    
    # 修改文件内容
    echo "正在修改文件内容..." >> "$LOG_FILE"
    sed -i "" "s/$CURRENT/$TARGET/g" "$FILE_PATH" && echo "已将$CURRENT替换为$TARGET" >> "$LOG_FILE"
    
    # 重新锁定文件
    echo "正在重新锁定文件..." >> "$LOG_FILE"
    chflags uchg "$FILE_PATH" 2>/dev/null || echo "警告: 无法重新锁定文件" >> "$LOG_FILE"
    
    # 验证修改
    echo "正在验证修改..." >> "$LOG_FILE"
    chflags nouchg "$FILE_PATH" 2>/dev/null
    if grep -q "$TARGET" "$FILE_PATH"; then
        echo "验证成功: 当前配置为$TARGET" >> "$LOG_FILE"
        echo "SUCCESS:$TARGET" > "$TEMP_RESULT_FILE"
    else
        echo "警告: 无法验证修改结果" >> "$LOG_FILE"
        echo "FAILED" > "$TEMP_RESULT_FILE"
    fi
    chflags uchg "$FILE_PATH" 2>/dev/null
    
    echo "操作完成!" >> "$LOG_FILE"
'

# 读取操作结果
RESULT=$(cat "$TEMP_RESULT_FILE" 2>/dev/null)
rm -f "$TEMP_RESULT_FILE"

# 根据结果显示不同的通知
if [[ "$RESULT" == SUCCESS:* ]]; then
    NEW_CODE=${RESULT#SUCCESS:}
    # 只显示一个成功通知
    osascript -e "display notification \"国家代码修改为 $NEW_CODE\" with title \"操作成功\""
    echo "脚本执行成功: 国家代码修改为 $NEW_CODE" | tee -a "$LOG_FILE"
else
    # 只显示一个失败通知，包含日志路径
    osascript -e "display notification \"修改失败\n详细日志: $LOG_FILE\" with title \"操作失败\""
    echo "脚本执行失败" | tee -a "$LOG_FILE"
fi