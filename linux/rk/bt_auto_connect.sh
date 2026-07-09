#!/bin/bash
# 瑞芯微盒子，蓝牙长时间连接，重启之后无法再次无法连接上蓝牙设备问题
# 目标设备 MAC（确认无误）
TARGET_MAC="00:00:00:00:00:00"
# 扫描时长（秒）：经典蓝牙一次完整 inquiry 约 10.24s，建议 ≥12s
SCAN_TIMEOUT=15

echo "==================== 蓝牙自动修复连接脚本 ===================="
echo "目标MAC: ${TARGET_MAC}  (UHF-BT4.0)"
echo "运行时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================================="

# 1. 重启蓝牙服务，清空卡死状态
echo "[步骤1] 重启 bluetooth 服务"
sudo systemctl restart bluetooth
sleep 3
# 解除射频锁定：被 rfkill 阻塞时适配器会报 org.bluez.Error.NotReady
sudo rfkill unblock bluetooth 2>/dev/null

# 2. 适配器上电 + 注册代理
echo "[步骤2] 适配器上电、注册代理"
{
  echo "power on"
  sleep 2              # 等待上电完成，否则 scan 会报 NotReady
  echo "agent on"      # 注册自动配对代理，处理 SSP/PIN
  echo "default-agent"
  sleep 1
  echo "quit"
} | bluetoothctl

# 3. 删除旧配对记录（若有）并扫描发现设备
echo "[步骤3] 清除旧配对记录，扫描 ${SCAN_TIMEOUT} 秒..."
{
  echo "remove ${TARGET_MAC}"   # 无旧记录时提示 not available，不影响
  sleep 1
  echo "scan on"
  sleep ${SCAN_TIMEOUT}         # 经典蓝牙需 ≥10s 才能完整发现设备
  echo "scan off"
  sleep 1
  echo "quit"
} | bluetoothctl

# 4. 校验目标设备是否被发现（未发现直接退出，避免盲目 pair/connect 报 not available）
if ! bluetoothctl devices | grep -qF "$TARGET_MAC"; then
  echo "[错误] ${SCAN_TIMEOUT} 秒内未发现 $TARGET_MAC (UHF-BT4.0)"
  echo "       请确认：1) UHF-BT4.0 已开机并进入配对/可发现模式（通常长按电源键或配对键）"
  echo "               2) 设备在通信范围内"
  echo "               3) MAC 地址正确（当前: $TARGET_MAC）"
  echo "==== 执行失败 ===="
  exit 1
fi
echo "[步骤3] 已发现目标设备，开始配对"

# 5. 配对、信任、连接
echo "[步骤4] 配对 / 信任 / 连接"
{
  echo "pair ${TARGET_MAC}"
  sleep 3
  echo "trust ${TARGET_MAC}"
  sleep 1
  echo "connect ${TARGET_MAC}"
  sleep 3              # 留出音频 profile 协商时间
  echo "quit"
} | bluetoothctl

# 6. 校验最终连接状态
echo "[步骤5] 连接状态校验"
sleep 1
bluetoothctl info "$TARGET_MAC" | grep -E "Name|Connected|Paired|Trusted"

echo -e "\n==== 执行完成 ===="
echo "若音频仍报 Permission denied，确认设备进入配对模式后重新运行脚本重建密钥"
