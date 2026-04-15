"""
反应盒主程序
==========

命令行调试和测试界面
"""

from src import auto_find_reaction_box
from src.test_utils import (
    test_basic_connection,
    test_key_detection,
    test_reaction_time,
    calibrate_system_delay,
    test_detailed_parameters,
    demo_simple_experiment
)


def show_menu():
    """显示主菜单"""
    print("\n" + "=" * 60)
    print("反应盒测试系统")
    print("=" * 60)
    print("\n请选择测试项目：")
    print("  1. 基础连接测试")
    print("  2. 按键检测测试")
    print("  3. 反应时测量测试")
    print("  4. 系统延迟校准（手动版，推荐）")
    print("  5. 详细参数测试（显示所有时间参数）")
    print("  6. 简单实验演示")
    print("  0. 退出")
    print("=" * 60)


def main():
    """主函数"""
    print("\n欢迎使用反应盒测试系统！")
    
    # 首先查找反应盒
    PORT = auto_find_reaction_box()
    
    if PORT is None:
        print("\n错误：未找到反应盒，请检查：")
        print("  1. USB线是否连接")
        print("  2. 驱动是否安装")
        print("  3. 反应盒是否通电")
        return
    
    # 主循环
    while True:
        show_menu()
        
        choice = input("\n请输入选项 (0-6): ").strip()
        
        if choice == '1':
            test_basic_connection(PORT)
        elif choice == '2':
            test_key_detection(PORT)
        elif choice == '3':
            test_reaction_time(PORT)
        elif choice == '4':
            calibrate_system_delay(PORT)
        elif choice == '5':
            test_detailed_parameters(PORT)
        elif choice == '6':
            demo_simple_experiment(PORT)
        elif choice == '0':
            print("\n感谢使用，再见！")
            break
        else:
            print("\n无效选项，请重新选择")
        
        input("\n按 Enter 继续...")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n程序被用户中断")
    except Exception as e:
        print(f"\n程序出错: {e}")
        import traceback
        traceback.print_exc()
