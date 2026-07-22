# MSPM0G3507 VS Code + TI Arm Clang 开发模板

当前 SysConfig 目标为立创·地猛星使用的 MSPM0G3507 48Pin `LQFP-48(PT)` 封装。

本工程是一套独立于 CCS 工程管理系统的 MSPM0G3507 Windows 开发模板，覆盖以下流程：

```text
编写 C 代码
    ↓
使用 SysConfig 配置时钟、引脚和外设
    ↓
TI Arm Clang 编译、链接
    ↓
生成 build/firmware.out
    ↓
J-Link / DAPLink(OpenOCD) / XDS110(DSLite) 烧录
    ↓
Cortex-Debug + GDB 断点调试
```

原始 MSPM0 SDK 保持不变。本工程位于：

```text
D:\ti\mspm0g3507-vscode-template
```

## 1. 工程结构

```text
mspm0g3507-vscode-template/
├─ .vscode/
│  ├─ c_cpp_properties.json    TI Clang 代码补全配置
│  ├─ extensions.json          推荐的 VS Code 扩展
│  ├─ settings.json            工程级编辑器设置
│  └─ tasks.json               SysConfig、编译、清理和烧录任务
├─ config/
│  └─ app.syscfg               时钟、引脚和外设配置
├─ include/                    用户头文件
├─ src/
│  └─ main.c                   主程序及用户源文件
├─ tools/
│  ├─ clean.ps1                安全清理 build 目录
│  ├─ flash-jlink.ps1          J-Link 烧录脚本
│  ├─ flash-openocd.ps1        DAPLink/OpenOCD 烧录脚本
│  ├─ flash-xds110.ps1         XDS110/DSLite 烧录脚本
│  └─ mspm0g3507_xds110.ccxml  XDS110 目标配置
├─ build/                      自动生成的构建目录
├─ Makefile                    编译和链接规则
└─ README.md                   本文档
```

需要长期维护的内容主要是：

```text
src/
include/
config/app.syscfg
```

以下内容由工具自动生成，不要手工修改：

```text
build/obj/
build/syscfg/
build/firmware.out
build/firmware.map
```

## 2. 已配置的工具

| 工具 | 默认路径 | 用途 |
| --- | --- | --- |
| MSPM0 SDK 2.04 | `D:/ti/mspm0_sdk_2_04_00_06` | DriverLib、CMSIS、启动文件和芯片支持 |
| TI Arm Clang 4.0.4 LTS | `D:/ti/ccs/tools/compiler/ti-cgt-armllvm_4.0.4.LTS` | 编译和链接 |
| GNU Make 4.4.1 | `D:/ti/ccs/utils/bin/gmake.exe` | 执行 Makefile |
| SysConfig 1.23 | `D:/ti/SYSCONFIG` | 生成时钟、引脚和外设初始化代码 |
| J-Link 9.30a | `C:/Program Files/SEGGER/JLink_V930a` | J-Link 烧录和调试服务器 |
| OpenOCD b56339c | `D:/ti/openocd-b56339c` | DAPLink/XDS110 烧录和调试 |
| DSLite 20.5 | `D:/ti/ccs/ccs_base/DebugServer/bin` | XDS110 命令行烧录 |
| TI Embedded Debug | VS Code 扩展 | OpenOCD、GDB 和 MSPM0 调试支持 |

更换 SDK 或工具版本时，需要同步检查：

- `Makefile`
- `.vscode/tasks.json`
- `.vscode/c_cpp_properties.json`
- `.vscode/launch.json`

## 3. 第一次打开工程

1. 在 VS Code 中选择“文件 → 打开文件夹”。
2. 打开：

   ```text
   D:\ti\mspm0g3507-vscode-template
   ```

3. 按 `Ctrl+Shift+P`，执行 `Tasks: Run Task`。
4. 运行：

   ```text
   MSPM0: Generate SysConfig
   ```

5. 按 `Ctrl+Shift+B` 完整编译。

首次生成后，`build/syscfg/` 中应出现：

```text
ti_msp_dl_config.c
ti_msp_dl_config.h
device.opt
device_linker.cmd
device.cmd.genlibs
```

如果代码补全提示找不到 `ti_msp_dl_config.h`，通常是尚未生成 `build/syscfg`。先运行一次 SysConfig 或完整编译即可。

## 4. 编写代码

### 4.1 主程序结构

主程序位于 `src/main.c`，基本结构如下：

```c
#include "ti_msp_dl_config.h"

int main(void)
{
    SYSCFG_DL_init();

    while (1) {
        /* 用户应用程序 */
    }
}
```

`SYSCFG_DL_init()` 通常只调用一次。它负责初始化 SysConfig 中配置的系统时钟、GPIO、UART、SPI、I2C、ADC、定时器、DMA 等外设，不要在主循环中重复调用。

### 4.2 添加源文件

应用源文件直接放到 `src/` 第一层：

```text
src/main.c
src/led.c
src/uart.c
src/app.c
```

Makefile 会自动扫描 `src/*.c`。当前不会递归扫描 `src` 子目录，因此暂时不要使用 `src/drivers/uart.c` 这样的结构，除非同步扩展 Makefile。

### 4.3 添加头文件

用户头文件放入 `include/`：

```text
include/led.h
include/uart.h
include/app.h
```

源文件中可以直接引用：

```c
#include "led.h"
#include "uart.h"
```

### 4.4 模块化示例

`include/led.h`：

```c
#ifndef LED_H
#define LED_H

void LED_init(void);
void LED_toggle(void);

#endif
```

`src/led.c`：

```c
#include "ti_msp_dl_config.h"
#include "led.h"

void LED_init(void)
{
    DL_GPIO_clearPins(LED_PORT, LED_PIN_0_PIN);
}

void LED_toggle(void)
{
    DL_GPIO_togglePins(LED_PORT, LED_PIN_0_PIN);
}
```

`src/main.c`：

```c
#include "ti_msp_dl_config.h"
#include "led.h"

int main(void)
{
    SYSCFG_DL_init();
    LED_init();

    while (1) {
        LED_toggle();
        delay_cycles(16000000);
    }
}
```

## 5. 代码补全与跳转

代码补全由 Microsoft C/C++ 扩展提供，工程配置已经包含：

- TI Arm Clang 编译器路径
- MSPM0 SDK 和 DriverLib 头文件
- CMSIS 头文件
- `include/`
- `build/syscfg/`
- MSPM0G3507 预处理宏

输入：

```c
DL_GPIO_
```

应显示 `DL_GPIO_setPins`、`DL_GPIO_clearPins`、`DL_GPIO_togglePins` 等补全。

常用操作：

| 功能 | 操作 |
| --- | --- |
| 手动触发补全 | `Ctrl+Space` |
| 跳转到定义 | `F12` 或 `Ctrl+单击` |
| 查看定义 | `Alt+F12` |
| 查看引用 | `Shift+F12` |

补全异常时依次执行：

1. 完整编译一次，确保 `build/syscfg` 已生成。
2. `Ctrl+Shift+P` → `C/C++: Select IntelliSense Configuration`。
3. 选择 `MSPM0G3507 TI Clang`。
4. 仍有问题时执行 `C/C++: Reset IntelliSense Database`。

## 6. 使用 SysConfig 配置外设

不要直接修改 `build/syscfg/ti_msp_dl_config.c` 或 `.h`。修改引脚、时钟和外设时：

1. `Ctrl+Shift+P` → `Tasks: Run Task`。
2. 运行：

   ```text
   MSPM0: Open SysConfig
   ```

3. 在图形界面中修改 GPIO、UART、SPI、ADC、定时器等配置。
4. 保存 `config/app.syscfg`。
5. 回到 VS Code 按 `Ctrl+Shift+B`。

构建系统检测到 `.syscfg` 变化后会自动重新生成相关文件。

当前模板的主要引脚是：

```text
LED_PIN_0 → PA14
SWDIO     → PA19
SWCLK     → PA20
```

## 7. 编译程序

### 7.1 VS Code 快捷编译

按：

```text
Ctrl+Shift+B
```

默认执行 `MSPM0: Build`。

完整构建过程：

```text
config/app.syscfg
    ↓
SysConfig 生成外设、启动和链接配置
    ↓
tiarmclang 编译 src/*.c
    ↓
编译 SysConfig 生成代码和 MSPM0 启动文件
    ↓
tiarmclang 链接
    ↓
build/firmware.out
```

### 7.2 从任务面板编译

`Ctrl+Shift+P` → `Tasks: Run Task` → `MSPM0: Build`。

### 7.3 命令行编译

```powershell
D:/ti/ccs/utils/bin/gmake.exe -f Makefile all
```

### 7.4 清理后重新编译

VS Code 任务：

```text
MSPM0: Clean
MSPM0: Build
```

命令行：

```powershell
D:/ti/ccs/utils/bin/gmake.exe -f Makefile clean
D:/ti/ccs/utils/bin/gmake.exe -f Makefile all
```

Clean 只会删除当前工程的 `build/`，不会修改 SDK、`src/`、`include/` 或 `config/`。

### 7.5 构建结果

成功时终端最后应显示：

```text
Linking build/firmware.out
```

主要产物：

| 文件 | 用途 |
| --- | --- |
| `build/firmware.out` | 可烧录且包含调试符号的 ELF 固件 |
| `build/firmware.hex` | Intel HEX 固件，可用于串口 BSL 或其他支持 HEX 的烧录工具 |
| `build/firmware.map` | 链接映射、段大小和符号地址 |
| `build/obj/*.obj` | 目标文件 |
| `build/obj/*.d` | 自动依赖文件 |

只修改一个 `.c` 后，Makefile 只会重新编译受影响文件并重新链接。

默认输出名称为 `firmware.out`。如果通过 `PROJECT_NAME` 修改输出名称，还必须同步调整烧录和调试配置中的固件路径。

## 8. 烧录器接线

所有方案都使用 SWD：

| 调试器信号 | MSPM0G3507 |
| --- | --- |
| SWDIO | PA19 |
| SWCLK | PA20 |
| GND | GND |
| nRESET | NRST，建议连接 |
| VTref | 目标板 I/O 电压参考 |
| 3.3V | 仅在确定由调试器供电时连接 |

注意事项：

- 调试器和目标板必须共地。
- VTref 必须检测到正确电压。
- 不要让 USB、调试器和外部电源互相反向供电。
- 同一时间只能让一个程序占用探针。
- 烧录前关闭可能占用探针的 CCS、Keil、J-Flash 或其他 OpenOCD 实例。

## 9. 使用 J-Link 烧录

推荐日常开发优先使用 J-Link。

1. 连接 J-Link 和目标板并上电。
2. `Ctrl+Shift+P` → `Tasks: Run Task`。
3. 选择：

   ```text
   MSPM0: Build + Flash (J-Link)
   ```

任务会依次执行：

```text
编译 → 检查 firmware.out → SWD 4 MHz 连接 → 下载 → 复位 → 运行
```

正常输出应包含 `Downloading file`、`Flash download` 和 `O.K.`。

连接不稳定时，编辑 `tools/flash-jlink.ps1`，把：

```powershell
[int]$SpeedKHz = 4000
```

降低为 `1000`，必要时降低为 `100`。

## 10. 使用 DAPLink/OpenOCD 烧录

1. 连接 DAPLink 的 SWDIO、SWCLK、GND、VTref，建议连接 NRST。
2. 运行：

   ```text
   MSPM0: Build + Flash (DAPLink/OpenOCD)
   ```

脚本优先使用：

```text
D:\ti\openocd-b56339c\bin\openocd.exe
```

并加载：

```text
interface/cmsis-dap.cfg
target/ti/mspm0.cfg
```

默认 SWD 速度为 1 MHz。正常输出应包含：

```text
CMSIS-DAP: Interface Initialised
Cortex-M0+ processor detected
Programming Finished
Verified OK
```

也可以通过环境变量覆盖 OpenOCD：

```powershell
$env:OPENOCD_EXE = "D:/path/to/openocd.exe"
```

## 11. 使用 XDS110/DSLite 烧录

连接 LP-MSPM0G3507 板载 XDS110 或外置 XDS110，然后运行：

```text
MSPM0: Build + Flash (XDS110/DSLite)
```

任务调用：

```text
D:\ti\ccs\ccs_base\DebugServer\bin\DSLite.exe
```

并使用 `tools/mspm0g3507_xds110.ccxml` 完成编程、校验和运行。这是与 CCS/UniFlash 同源的 TI 官方命令行烧录路径。

三种方式建议优先级：

| 顺序 | 方式 | 适用场景 |
| --- | --- | --- |
| 1 | J-Link | 日常开发，稳定且速度快 |
| 2 | DAPLink/OpenOCD | 使用 CMSIS-DAP 探针 |
| 3 | XDS110/DSLite | LaunchPad、TI 官方备用路径和恢复排障 |

## 12. 使用 DAPLink 断点调试

工程已经在 `.vscode/launch.json` 中配置好 DAPLink + OpenOCD 调试，不需要手工创建配置。调试使用 Cortex-Debug、Arm GDB 和 MSPM0G350X SVD 外设描述文件。

调试构建与日常构建相互独立：

| 用途 | 优化等级 | 输出文件 |
| --- | --- | --- |
| 日常编译和烧录 | `-O2` | `build/firmware.out` |
| DAPLink 断点调试 | `-O0` | `build/debug/firmware.out` |

`MSPM0: Build (Debug)` 会自动传入 `BUILD_DIR=build/debug OPT_LEVEL=-O0`，因此不会覆盖日常烧录使用的固件。

### 12.1 启动调试

1. 打开 `src/main.c`。
2. 单击行号左侧设置断点。
3. 按 `F5`。
4. 如果 VS Code 要求选择配置，选择 `MSPM0G3507: Debug with DAPLink`。
5. `preLaunchTask` 会自动执行 `MSPM0: Build (Debug)`。
6. OpenOCD 连接 DAPLink，下载 `build/debug/firmware.out`，并停在 `main()`。

启动调试前通常不需要单独执行烧录任务，因为 Cortex-Debug 会自动下载 ELF。

### 12.2 调试快捷键

| 功能 | 快捷键 |
| --- | --- |
| 启动或继续 | `F5` |
| 设置/取消断点 | `F9` |
| 单步跳过 | `F10` |
| 单步进入 | `F11` |
| 单步跳出 | `Shift+F11` |
| 停止调试 | `Shift+F5` |
| 重启调试 | `Ctrl+Shift+F5` |

调试侧栏可以查看局部变量、Watch 表达式、调用栈、CPU 寄存器、内存和 MSPM0 外设寄存器。

### 12.3 调试优化等级

Makefile 的默认优化等级仍是 `-O2`。按 `F5` 时，调试构建任务会单独使用 `-O0`，使变量、源码行和单步执行更容易观察。无需手工修改 Makefile，也无需在调试结束后恢复优化选项。

当前 TI Clang 为 4.0.4 LTS，不需要旧版 TI Clang 的 `.TI.phattrs` 修复步骤。

## 13. 日常开发标准流程

### 13.1 只修改应用代码

```text
修改 src/*.c 或 include/*.h
    ↓
Ctrl+Shift+B
    ↓
运行对应的 Build + Flash 任务
    ↓
观察程序运行
```

### 13.2 修改引脚或外设

```text
MSPM0: Open SysConfig
    ↓
修改并保存 config/app.syscfg
    ↓
Ctrl+Shift+B
    ↓
Build + Flash
```

### 13.3 调试问题

```text
设置断点
    ↓
F5
    ↓
自动执行 MSPM0: Build (Debug)，以 -O0 构建并下载
    ↓
单步、查看变量和寄存器
```

### 13.4 生成发布固件

```text
MSPM0: Clean
    ↓
MSPM0: Build
    ↓
保存 build/firmware.out
    ↓
检查并归档 build/firmware.map
```

## 14. 常见问题

### 14.1 `ti_msp_dl_config.h` 找不到

运行 `MSPM0: Generate SysConfig` 或完整编译，然后重置 IntelliSense 数据库。

### 14.2 编译成功但 LED 不亮

检查：

- SysConfig 中 LED 是否仍配置为 PA14。
- LED 是高电平还是低电平点亮。
- 系统时钟是否与 `delay_cycles()` 参数匹配。
- 修改的是本工程的 `src/main.c`。

### 14.3 J-Link 无法连接

依次检查 VTref、GND、SWDIO、SWCLK、NRST、目标供电，并关闭其他占用探针的软件。然后降低 SWD 速度并重新给目标板上电。

### 14.4 OpenOCD 找不到 CMSIS-DAP

检查设备管理器、DAPLink 固件和 USB 数据线，并确认没有其他 OpenOCD、pyOCD 或 IDE 占用探针。

### 14.5 可以烧录但断点不命中

检查：

- 调试使用的是最新 `build/debug/firmware.out`。
- `MSPM0: Build (Debug)` 是否成功完成。
- `launch.json` 中的 `preLaunchTask` 是否仍为 `MSPM0: Build (Debug)`。
- 断点所在代码是否确实会执行。
- 是否设置了过多硬件断点。

MSPM0G3507 的硬件断点资源有限，不应同时设置大量断点。

### 14.6 芯片进入低功耗或无法连接

先尝试重新上电、连接 NRST、降低 SWD 速度和换用 XDS110。Mass erase 或 factory reset 会擦除程序，其中 factory reset 还可能恢复 NONMAIN 配置，只应作为最后的恢复手段。

## 15. 推荐工具组合

日常开发建议固定使用：

```text
编辑器：VS Code
外设配置：SysConfig
代码补全：Microsoft C/C++
编译：TI Arm Clang + GNU Make
日常烧录：DAPLink + OpenOCD
断点调试：Cortex-Debug + DAPLink + OpenOCD
备用烧录：J-Link
TI 官方备用：XDS110 + DSLite
```

这样既不依赖 CCS 工程管理，又可以继续使用 TI 官方 SDK、SysConfig 和 DriverLib，并能将整个模板复制到其他工作目录中使用。
