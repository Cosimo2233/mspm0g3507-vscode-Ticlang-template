# MSPM0G3507 VS Code + TI Arm Clang 模板

本目录现在包含一套独立于 CCS 工程系统的 Windows 开发模板。根目录的
`Makefile`、`src/`、`include/`、`config/`、`tools/` 和 `.vscode/` 是新模板；
原来的 `gcc/`、`iar/`、`keil/`、`ticlang/` 文件夹仅作为 TI 示例参考，不参与新构建。

## 已配置工具

| 工具 | 默认路径 |
| --- | --- |
| MSPM0 SDK | `D:/ti/mspm0_sdk_2_04_00_06` |
| TI Arm Clang | `D:/ti/ccs/tools/compiler/ti-cgt-armllvm_4.0.4.LTS` |
| GNU Make | `D:/ti/ccs/utils/bin/gmake.exe` |
| SysConfig | `D:/ti/SYSCONFIG` |
| J-Link | `C:/Program Files/SEGGER/JLink_V930a` |
| DSLite | `D:/ti/ccs/ccs_base/DebugServer/bin` |

改变 SDK 或工具安装位置时，需要同步修改 `Makefile`、`.vscode/tasks.json` 和
`.vscode/c_cpp_properties.json` 中的路径。

## 使用方法

1. 在 VS Code 中打开本目录。
2. 首次打开后执行 `终端 -> 运行任务 -> MSPM0: Generate SysConfig`，或者直接按
   `Ctrl+Shift+B`；完整构建会自动生成 SysConfig 文件。
3. 应用源码放到 `src/*.c`，项目头文件放到 `include/`。
4. 修改引脚和外设时，执行 `MSPM0: Open SysConfig` 编辑 `config/app.syscfg`。
5. 构建产物位于 `build/firmware.out`，链接映射位于 `build/firmware.map`。

可用任务：

- `MSPM0: Build`
- `MSPM0: Clean`
- `MSPM0: Generate SysConfig`
- `MSPM0: Open SysConfig`
- `MSPM0: Build + Flash (J-Link)`
- `MSPM0: Build + Flash (DAPLink/OpenOCD)`
- `MSPM0: Build + Flash (XDS110/DSLite)`

## 烧录与接线

所有探针都使用 SWD。至少连接 `SWDIO -> PA19`、`SWCLK -> PA20`、`GND -> GND`；
建议同时连接 `nRESET`，并确保探针与目标板 I/O 电压一致。目标板必须可靠供电，
不要同时由多个接口互相反向供电。

### J-Link

J-Link 是默认烧录方式。任务调用 J-Link Commander，以 4 MHz SWD 下载
`build/firmware.out`，然后复位并运行。

### DAPLink / CMSIS-DAP

任务会依次查找：

1. 环境变量 `OPENOCD_EXE` 指定的程序；
2. `D:/ti/openocd-b56339c/bin/openocd.exe`；
3. TI Embedded Debug 扩展安装的 OpenOCD 1.3.1.50。

脚本同时兼容官方新布局 `target/ti/mspm0.cfg` 与 TI 扩展布局
`target/ti_mspm0.cfg`。它会执行编程、校验和复位。

### XDS110 / UniFlash CLI

备用任务使用 CCS 内置的 DSLite（与 UniFlash/CCS 共用调试服务器）和
`tools/mspm0g3507_xds110.ccxml` 完成编程、校验和运行。

## 命令行

```powershell
D:/ti/ccs/utils/bin/gmake.exe -f Makefile clean
D:/ti/ccs/utils/bin/gmake.exe -f Makefile all
```

可以在命令行覆盖模板变量，例如：

```powershell
D:/ti/ccs/utils/bin/gmake.exe -f Makefile PROJECT_NAME=my_app all
```

本模板暂不包含 `launch.json`，即暂不配置断点调试。
