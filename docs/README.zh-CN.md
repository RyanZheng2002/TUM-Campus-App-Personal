# Campus Personal V5

[English](../README.md) | **简体中文** | [Deutsch](README.de.md)

基于 [TUM-Dev/campus_flutter](https://github.com/TUM-Dev/campus_flutter) 的个人安卓版本，通过 TUMonline 课程网页的公开数据接口恢复从日历查看课程详情。

版本 **5.3.1+5** · **Android 10+** · 包名 `de.tum.in.tumcampus.personal` · 名称 **Campus Personal**。

## 主要修改

- 读取真实课程名称、学期、教学团队、教学内容、学习目标等实际提供的资料。
- 支持早期个人版遗漏的日历链接 `lv.detail?cLvNr=...`。
- 加载、成功、错误分别显示；失败时仅显示错误和重试，缺失字段不补写。
- 按完整房间编码链接到 NavigaTUM 搜索。
- 使用用户提供的蓝色启动图标，独立包名可与原版共存。

## 问题分析：选择语言

[English](lecture-data.en.md) · [简体中文](lecture-data.zh-CN.md) · [Deutsch](lecture-data.de.md)

分析区分了原软件的旧接口停用问题和早期个人版的 cLvNr 解析回归，并解释当前请求流程、XML 字段映射、页面组织与验证范围。

## 构建

V5 使用 Flutter **3.47.7**、Dart **3.13.5**、JDK **21**、Android SDK **36**、build-tools **35.0.0**、NDK **28.2.13676358**。

```powershell
flutter pub get
flutter test
$env:CAMPUS_PERSONAL_BUILD='true'
flutter build apk --release --target lib/main.dart --dart-define=PERSONAL_BUILD=true
```

两个个人构建开关均需启用。输出文件为 `build/app/outputs/flutter-apk/app-release.apk`。未配置发布密钥时使用本地 Android debug 签名；覆盖升级需要保留同一签名密钥。此前交付 APK 的本机私钥不上传。

完整构建和 Android 集成测试命令见 [README_PERSONAL.md](../README_PERSONAL.md)。仓库包含手动触发的 [Android 构建工作流](../.github/workflows/build_personal.yml)，此次上传不会触发它。

## V5 验证结果

**2026-10-20** 完成：141 项 Flutter 测试、相关静态检查、Android 15 模拟器两门课程的真实联网读取和教学内容滚动显示。发布 APK 的签名、覆盖安装、冷启动检查也通过。此处记录当时的 V5 结果，不代表上传当天重新检查了服务器状态。

[Android 截图](images/) · [验证记录](validation/) · [详细范围](lecture-data.zh-CN.md#验证与边界)

私人选课列表仍使用另一套旧服务，因此权限页的 Lectures 停用提示可能保留；从日历进入公开课程详情使用本版新通道。

## 来源与许可

应用源码、资产、测试和脚本来自已交付的 V5 源码快照，基于上游提交 `9b10141dc53b9552945245a9a978a0b8405a7153`。保留 [GPL-3.0](../LICENSE) 许可和[上游 README](upstream-README.md)。这是非官方个人分支。

**2026-10-21** 补充仓库文档及语言导航。[来源记录](source-provenance.md)列出快照校验值与仅用于上传整理的变更。Git 不包含 APK、SDK、缓存或签名密钥。
