Celechron 1.3.1 — Windows x64 便携版

这是根据 Celechron 1.3.1 源码制作的非官方 Windows 兼容构建。

使用方法
1. 在 Windows 10/11 64 位系统上，将 ZIP 完整解压到一个可写文件夹。
2. 双击 Celechron.exe。请保留旁边的所有 DLL 和 data 文件夹。
3. 无需安装 Flutter、Visual Studio 或 Python。
4. 首次登录和学校数据查询需要联网及你自己的校园账号。

功能范围
Windows 构建保留原程序的日程、任务、课表和成绩界面。
手机桌面小组件、Apple Watch、手机后台调度、系统日历同步和本地通知
在本 Windows 兼容构建中不可用。
已完成的启动检查只确认应用可以显示主窗口且不会立即退出，
不等于已验证校园账号登录、学校接口或全部业务功能。

如果启动失败，请保留完整文件夹，并提供 Windows 版本及错误提示。
不要仅复制 Celechron.exe，也不要把自己的账号或密码发送给他人。

构建记录
build-info.json：构建时间、源代码哈希、依赖哈希与验证范围。
flutter-version.json：编译使用的 Flutter/Dart 版本。
pubspec.lock：本次构建解析得到的依赖版本。
smoke-test.txt：启动检查结果。

源代码与许可
同批交付的 Celechron-1.3.1-Windows-source.zip 包含本构建对应的
应用源码、修改和构建脚本；请在重新分发应用时一并提供该源码。
应用许可证见 LICENSE-Celechron.txt。第三方组件依各自许可证发布；
Flutter 生成的第三方许可记录保留在 data/flutter_assets/NOTICES.Z。
随包 Visual C++ DLL 来自 Visual Studio 的可再分发 CRT 目录，
其许可归 Microsoft 所有，不属于 Celechron 的 GPL 源代码。

上游项目：https://github.com/Celechron/Celechron
本构建不代表上游项目官方发布。
