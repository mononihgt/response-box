"""
串口工具模块
===========

提供串口查找、连接和检测功能
"""

import serial
import time
from serial.tools import list_ports


def list_all_ports():
    """
    列出所有可用的串口
    """
    print("=" * 60)
    print("扫描可用串口...")
    print("=" * 60)
    
    ports = list_ports.comports()
    
    if not ports:
        print("未找到任何串口设备！")
        return []
    
    for i, port in enumerate(ports, 1):
        print(f"\n串口 {i}:")
        print(f"  设备名: {port.device}")
        print(f"  描述: {port.description}")
        print(f"  硬件ID: {port.hwid}")
    
    print("=" * 60)
    return ports


def check_port(port, baud=115200):
    """
    检查指定串口是否可用
    
    参数:
        port: 串口名称（如 'COM3'）
        baud: 波特率
    
    返回:
        bool: 串口是否可用
    """
    try:
        with serial.Serial(port, baud, timeout=0.2) as ser:
            # 尝试读写测试
            ser.write(b'\x00')
            ser.read(1)
            return True
    except serial.SerialException:
        return False
    except Exception as e:
        print(f"检查串口时出错: {e}")
        return False


def check_reaction_box(port, baud=115200):
    """
    检查反应盒是否正常工作
    
    参数:
        port: 串口名称
        baud: 波特率
    
    返回:
        bool: 反应盒是否正常
        device_id: 设备ID（如果成功）
    """
    try:
        with serial.Serial(port, baud, timeout=1.0) as ser:
            # 清空缓冲区
            ser.reset_input_buffer()
            
            # 发送查询设备编号命令
            ser.write(b'\x5A\x00')
            
            # 读取响应
            start_time = time.time()
            frame = b''
            
            while time.time() - start_time < 1.0:
                if ser.in_waiting > 0:
                    chunk = ser.read(ser.in_waiting)
                    frame += chunk
                    if len(frame) > 0:
                        break
                time.sleep(0.01)
            
            # 检查响应
            if len(frame) == 0:
                print(f"  {port}: 无响应")
                return False, None
            
            if len(frame) < 1 or frame[0] != 0x5A:
                print(f"  {port}: 响应格式错误")
                return False, None
            
            # 解析设备ID
            if len(frame) >= 3:
                device_id = f"{frame[1]:02X}{frame[2]:02X}"
            elif len(frame) >= 2:
                device_id = f"{frame[1]:02X}"
            else:
                device_id = f"{frame[0]:02X}"
            
            print(f"  {port}: 找到反应盒，设备ID = {device_id}")
            return True, device_id
            
    except Exception as e:
        print(f"  {port}: 检查失败 - {e}")
        return False, None


def auto_find_reaction_box(baud=115200):
    """
    自动查找并连接反应盒
    
    参数:
        baud: 波特率
    
    返回:
        str: 反应盒所在的串口名称，如果未找到则返回 None
    """
    print("\n正在自动查找反应盒...")
    
    # 获取所有串口
    ports = list_ports.comports()
    
    if not ports:
        print("错误：未找到任何串口设备！")
        return None
    
    # 优先检查 CH340/CH341 或常见 wchusbserial/usbserial 设备
    def is_ch34x(p):
        desc = (p.description or "").upper()
        return ('CH340' in desc) or ('CH341' in desc) or ('WCHUSB' in desc)

    def is_usbserial_generic(p):
        # macOS 驱动通常是 usbserial-XXXX
        name = p.device.lower()
        desc = (p.description or "").lower()
        return ('usbserial' in name) or ('wchusbserial' in name) or ('usb serial' in desc)

    # 跳过蓝牙口/耳机等无关串口，加速扫描
    def is_bluetooth(p):
        name = p.device.lower()
        desc = (p.description or "").lower()
        return ('bluetooth' in name) or ('bluetooth' in desc)

    ch340_ports = [p for p in ports if is_ch34x(p) or is_usbserial_generic(p)]
    other_ports = [p for p in ports if p not in ch340_ports]
    
    # 先检查CH340端口
    for port in ch340_ports:
        print(f"  检查 {port.device} ({port.description})...")
        success, device_id = check_reaction_box(port.device, baud)
        if success:
            print(f"\n✓ 成功连接到反应盒：{port.device} (设备ID: {device_id})")
            return port.device
    
    # 如果CH340端口没找到，再检查其他端口（跳过蓝牙等无关端口）
    for port in other_ports:
        if is_bluetooth(port):
            print(f"  跳过蓝牙端口: {port.device}")
            continue
        # 常见耳机/未知设备 description 可能是 n/a，保持一次尝试即可
        print(f"  检查 {port.device} ({port.description})...")
        success, device_id = check_reaction_box(port.device, baud)
        if success:
            print(f"\n✓ 成功连接到反应盒：{port.device} (设备ID: {device_id})")
            return port.device
    
    print("\n✗ 未找到反应盒！")
    return None
