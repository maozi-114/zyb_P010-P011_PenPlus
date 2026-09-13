# Z03Plus

紫光展锐 Linux/Qt 词典笔 Z03（P010/P011 兼容环境）的扩展功能原型。

本项目通过外部 Qt RCC 资源覆盖，在原厂“设置”页面加入：

```text
设置 -> Z03Plus 扩展
```

## 重要提示

- 本项目仅面向具备相同软件环境的 Z03 / P010 / P011 设备，其他型号未经测试。
- 操作前请完整备份设备数据和启动配置。使用者须自行承担刷写、部署及启动失败的风险。
- 不要直接修改或覆盖原厂 `/usr/bin/Z03`；始终使用 `/home/user/z03plus/Z03Plus` 中的副本。
- 本仓库只提供源码，不包含原厂二进制、Qt 库、工具链、设备导出资源或编译产物。

## 已实现

1. ARMv7 动态库注入：将 `DT_NEEDED` 添加到 Z03 的副本，不覆盖原始 `/usr/bin/Z03`。
2. Hook `qRegisterResourceData()`，在原厂 QRC 注册前加载 Z03Plus overlay。
3. 从运行中的 Z03 导出完整 Qt 资源，设备端导出目录为 `/home/user/z03plus/qrc/`。
4. 使用兼容的外部 QRC 覆盖：`qrc:/ZybQmlFiles/ZybSet/SetMainPage.qml`。
5. 设置页新增“Z03Plus 扩展”入口。
6. Z03Plus 首页包含文件管理、文本阅读、存储空间、显示与灯光、ADB/SSH、播放器、录音/息屏等入口。“显示与灯光”会打开原厂 `SetLightPage.qml`；其余项目目前为稳定的功能占位入口。

## 设备环境

- 主程序：`/usr/bin/Z03`
- CPU：ARMv7 / 32-bit ARM EABI
- 系统：Linux 4.14，glibc 2.27
- Qt：Qt 5.10.1 / Qt Quick / Wayland
- 外部可写目录：`/home/user/z03plus/`

## 目录说明

- `z03plus_overlay/`：实际生效的 overlay。
  - `SetMainPage.qml`：原厂设置主页的覆盖版，添加入口。
  - `Z03PlusPage.qml`：扩展主页。
  - `z03plus.qrc`：QML 的外部资源清单。
  - `z03plus_overlay.cpp`：注入库，抢先注册外部 QRC。
- `z03plus_exporter/`：资源导出器源码。在 Z03 注册原始 QRC 后遍历 `:/` 并导出运行时资源。
- `z03plus_tools/`：离线提取 Z03 嵌入 QML 文本块的 Python 工具及设备侧辅助脚本。
- `z03mods_poc/`：初期 ARMv7 注入与 QRC Hook 的验证源码，仅供参考。

## 构建与部署

需要 ARMv7 Linux 交叉编译器、QtCore 开发头文件，以及与设备兼容的 `libstdc++` ABI。

1. 编译 `libZ03Plus.so`（ARMv7 shared object）。
2. 生成 RCC v2：

   ```sh
   rcc --binary --format-version 2 --no-compress z03plus.qrc -o z03plus.rcc
   ```

3. 从原始 Z03 创建副本并加入依赖：

   ```sh
   patchelf --add-needed /home/user/z03plus/libZ03Plus.so Z03Plus
   ```

4. 部署到设备：

   ```text
   /home/user/z03plus/Z03Plus
   /home/user/z03plus/libZ03Plus.so
   /home/user/z03plus/z03plus.rcc
   ```

5. 配置启动脚本，使其启动 `Z03Plus` 副本。

### RCC 格式

设备上的 Qt 5.10.1 无法加载 Qt 5.15 默认生成的 RCC v3，必须生成 RCC v2；否则 `QResource::registerResource()` 会返回 `false`，设置页不会覆盖。

## 回退

将启动脚本恢复为：

```sh
/usr/bin/Z03 -platform wayland > /dev/null &
```

然后重启 Z03 服务。

## 注意事项

- 修改 QML 或 RCC 后，删除 `/home/.cache/Z03Plus/` 并重启 Z03Plus，QML 改动才会重新加载。
- 原厂 `BasicButton` 默认 `checkable: true`。Z03Plus 功能入口必须显式设为 `checkable: false`，否则点击后会保持绿色选中状态。

## 致谢与许可

本项目的词典笔扩展思路及部分早期实现，参考并基于 [PenUniverse/PenMods](https://github.com/PenUniverse/PenMods) 演进而来。感谢 PenMods 项目及其贡献者。

本项目依照 GNU General Public License v3.0 或更高版本（GPL-3.0-or-later）发布。完整许可证见 [LICENSE](LICENSE)，上游来源及适配说明见 [NOTICE](NOTICE)。
