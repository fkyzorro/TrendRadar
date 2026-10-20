Celechron 1.3.1 — Windows 构建准备包

状态：这是已做兼容性修正的源码和自动构建配置，不是安装包，也不包含已编译的 exe。
尚未完成 Windows 编译、Flutter 分析或实际运行验证。只有 GitHub Actions 构建和启动检查通过后，才可交付可运行版本。

已做修改
1. 将原先无条件执行的 iOS 钥匙串迁移限制在 iOS，避免 Windows 执行无关迁移。
2. Windows/Linux 跳过当前插件不支持的通知初始化。
3. 桌面版禁用系统日历直接同步，并明确提示使用 iCal 导出。
4. 将 workmanager 的 Git 依赖锁定到已核实的提交 d7e6ba5ef3796fafe54d9739e481f01058751b4d。
5. 新增 Windows x64 发布编译、完整目录打包、运行库携带、启动检查及源码归档脚本。

构建环境
GitHub Actions 的 windows-2022；Flutter 3.35.7；Visual Studio 2022 C++ 桌面开发工具。
Flutter 3.35.7 的官方标签对应提交 adc901062556672b4138e18a4dc62a4be8f4b3c2。
首次依赖解析将生成 pubspec.lock，并随构建结果归档。尚未验证这些依赖的最终解析与编译结果。

本机构建（仅供已经安装上述环境的 Windows 使用）
在项目根目录执行：
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-windows.ps1

云端构建
将项目完整文件放在有权限使用的 GitHub 仓库分支根目录。
.github/workflows/windows-build.yml 在 codex/celechron-windows-* 分支推送时触发，也支持手动运行。
只有使用专门的构建分支时才替换该分支文件树；不要覆盖原仓库的默认分支。
构建成功后 Actions Artifacts 中提供：
- Celechron-1.3.1-Windows-x64.zip：完整免安装程序目录。
- Celechron-1.3.1-Windows-source.zip：对应源码和依赖锁定文件。
- SHA256SUMS.txt：校验值。
失败时下载 Celechron-Windows-build-logs 排查，不会把失败结果标为成品。

检查范围与限制
启动检查只验证进程能持续运行 20 秒并创建主窗口，不代表全部业务功能通过。
需要校园账号的登录、课表、成绩和校园卡接口尚未测试。
原有移动端的后台任务、小组件、Apple Watch 与通知功能不能视为 Windows 已支持。
系统日历直接同步在桌面端禁用，保留 iCal 导出入口。
这是非官方 Windows 兼容修改；保留项目原有 GPL-3.0 LICENSE。
