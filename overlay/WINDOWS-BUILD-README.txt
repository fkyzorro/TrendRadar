Celechron 1.3.1 — Windows 构建说明

用途与构建状态
本目录保存 Windows 兼容源码及可复用的构建、打包和启动检查流程。
源码目录本身不等于可执行应用。请以实际构建产物中的 build-info.json、
flutter-version.json 和 smoke-test.txt，以及对应的构建日志判断构建状态。
脚本只有在编译、文件完整性检查和启动检查均通过后才生成最终发布 ZIP。
本文档不单独证明某一次构建已经成功，也不证明所有业务功能已经验证。

Windows 兼容修改
1. 将原先无条件执行的 iOS 钥匙串迁移限制在 iOS。
2. Windows/Linux 跳过当前插件不支持的通知初始化。
3. 桌面版禁用系统日历直接同步，并提示使用 iCal 导出。
4. 将 workmanager 的 Git 依赖锁定到提交 d7e6ba5ef3796fafe54d9739e481f01058751b4d。
5. 增加 Windows x64 发布编译、完整目录打包、运行库携带、启动检查及源码归档流程。

构建环境
使用 Windows x64 主机、Flutter 及 Visual Studio 2022 C++ 桌面开发工具。
Visual Studio 需要包含 MSVC、CMake 和 Windows SDK；Flutter 应加入 PATH。
本目录的独立工作流使用 GitHub Actions windows-2022 和 Flutter 3.35.7。
具体版本以 .github/workflows/windows-build.yml 和实际产物记录为准。
Flutter 3.35.7 官方标签对应提交 adc901062556672b4138e18a4dc62a4be8f4b3c2。
依赖解析生成的 pubspec.lock 会随本次构建产物与对应源码归档。

本机构建
完整解压源码，打开 64 位 PowerShell，进入含 pubspec.yaml 的项目根目录，执行：
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-windows.ps1

脚本使用已安装的工具，不会自动安装 Flutter 或 Visual Studio。
首次构建需要联网下载依赖。若 Flutter 提示插件需要符号链接支持，
请按提示在 Windows 设置中启用开发者模式，再重新运行。
构建过程及错误日志保存在 dist/logs。

在自己的 GitHub 仓库中构建
1. 将完整源码放在专门用于该项目的仓库根目录，确认 pubspec.yaml、
   scripts 和 .github/workflows/windows-build.yml 均已上传。
   本源码中的工作流直接编译当前目录，不依赖 overlay 或另一份源码下载。
2. 确认仓库已启用 GitHub Actions，并允许所使用的 actions。
3. 推送到名称符合 codex/celechron-windows-* 的分支会触发构建。
   也可在工作流文件已存在于默认分支时，从 Actions 页面手动运行并选择分支。
   不要为构建而覆盖其他项目的默认分支。
4. 构建成功后，下载 Actions Artifacts 中的 Celechron-1.3.1-Windows-x64。
   该产物内包括以下文件；失败时查看 Celechron-Windows-build-logs。

产物
- Celechron-1.3.1-Windows-x64.zip：完整便携程序目录。
- Celechron-1.3.1-Windows-source.zip：对应应用源码、构建脚本及依赖锁定文件。
- SHA256SUMS.txt：两个 ZIP 的 SHA-256 校验值。

运行程序
将便携版 ZIP 完整解压，再双击 Celechron.exe。
必须保留同目录中的 DLL 和 data 文件夹，不能只复制 exe。
运行便携版无需安装 Flutter、Visual Studio 或 Python。

检查范围与限制
启动检查验证进程持续运行 20 秒并创建主窗口，不代表全部业务功能通过。
需要校园账号的登录、课表、成绩和校园卡接口需要另行验证。
原有移动端的后台任务、小组件、Apple Watch 与通知功能不能视为 Windows 已支持。
系统日历直接同步在桌面端禁用，保留 iCal 导出入口。
这是非官方 Windows 兼容修改；保留项目原有 GPL-3.0 LICENSE。
重新分发程序时，请同时提供与该构建匹配的源码归档和许可证。
