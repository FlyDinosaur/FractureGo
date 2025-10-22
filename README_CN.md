<div align="center">
  <a href="https://github.com/FlyDinosaur/FractureGo/tree/main/docs/">
    <img src="docs/icon.svg" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">FractureGo</h3>

  <p align="center">
    儿童骨折术后康复综合助手
    <br />
    <a href="https://github.com/FlyDinosaur/FractureGo"><strong>查看文档 »</strong></a>
    <br />
    <br />
    <a href="https://github.com/FlyDinosaur/FractureGo">查看演示</a>
    ·
    <a href="https://github.com/FlyDinosaur/FractureGo/issues">报告问题</a>
    ·
    <a href="https://github.com/FlyDinosaur/FractureGo/issues">功能请求</a>
  </p>
</div>

<!-- 语言切换 -->
<div align="center">
  
[![English](https://img.shields.io/badge/Language-English-blue)](README.md)
[![中文](https://img.shields.io/badge/语言-中文-red)](README_CN.md)

</div>

<!-- 目录 -->
<details>
  <summary>目录</summary>
  <ol>
    <li>
      <a href="#关于项目">关于项目</a>
      <ul>
        <li><a href="#技术栈">技术栈</a></li>
      </ul>
    </li>
    <li>
      <a href="#开始使用">开始使用</a>
      <ul>
        <li><a href="#前置要求">前置要求</a></li>
        <li><a href="#安装">安装</a></li>
      </ul>
    </li>
    <li><a href="#使用方法">使用方法</a></li>
    <li><a href="#功能特色">功能特色</a></li>
    <li><a href="#开发路线图">开发路线图</a></li>
    <li><a href="#贡献">贡献</a></li>
    <li><a href="#许可证">许可证</a></li>
    <li><a href="#联系方式">联系方式</a></li>
    <li><a href="#致谢">致谢</a></li>
  </ol>
</details>

<!-- 关于项目 -->
## 关于项目

FractureGo 是一款专为儿童骨折术后康复设计的创新iOS应用程序。这个综合医疗解决方案将医学专业知识与引人入胜的儿童友好界面相结合，使康复过程既有效又愉快。

FractureGo 的突出特点：
* **以儿童为中心的设计**: 专门为年轻患者设计的直观界面
* **医学准确性**: 由骨科专家开发的循证康复方案
* **进度追踪**: 实时监控康复里程碑和成就
* **游戏化体验**: 互动元素让康复锻炼变得有趣且引人入胜
* **家庭支持**: 为父母和护理者提供参与康复过程的工具

我们的使命是将具有挑战性的儿科骨折康复体验转化为一段充满力量的治愈和成长之旅。

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

### 技术栈

本项目使用现代iOS开发技术和框架构建：

* [![Swift][Swift.org]][Swift-url]
* [![iOS][iOS.apple]][iOS-url]
* [![Xcode][Xcode.apple]][Xcode-url]
* [![UIKit][UIKit.apple]][UIKit-url]
* [![Core Data][CoreData.apple]][CoreData-url]
* [![HealthKit][HealthKit.apple]][HealthKit-url]

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 开始使用 -->
## 开始使用

要获取本地副本并运行，请按照以下简单步骤操作。

### 前置要求

开始之前，请确保已安装以下软件：

* **Xcode 14.0+**
  ```sh
  # 从 Mac App Store 或 Apple Developer Portal 下载
  ```
* **iOS 15.0+** 部署目标
* **CocoaPods** (用于依赖管理)
  ```sh
  sudo gem install cocoapods
  ```

### 安装

1. 克隆仓库
   ```sh
   git clone https://github.com/FlyDinosaur/FractureGo.git
   ```
2. 导航到项目目录
   ```sh
   cd FractureGo
   ```
3. 使用 CocoaPods 安装依赖
   ```sh
   pod install
   ```
4. 打开工作空间文件
   ```sh
   open FractureGo.xcworkspace
   ```
5. 在 Xcode 中构建并运行项目

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 使用示例 -->
## 使用方法

FractureGo 通过几个关键模块提供全面的康复体验：

### 患者仪表板
- 查看当前康复进度
- 访问每日锻炼计划
- 跟踪疼痛水平和康复里程碑

### 锻炼库
- 互动康复锻炼
- 视频演示和分步指南
- 基于康复阶段的自适应难度

### 进度追踪
- 可视化进度图表和分析
- 成就徽章和奖励
- 医疗预约提醒

### 家庭门户
- 护理者访问患者进度
- 与医疗保健提供者的沟通工具
- 关于骨折护理的教育资源

_有关更详细的文档，请参考 [文档](https://github.com/FlyDinosaur/FractureGo/wiki)_

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 功能特色 -->
## 功能特色

- **🎯 个性化康复计划**: 基于骨折类型和愈合阶段的定制锻炼方案
- **📊 进度分析**: 康复指标和里程碑的全面跟踪
- **🎮 游戏化体验**: 成就系统和互动元素鼓励参与
- **📱 用户友好界面**: 儿童友好的设计，导航直观
- **🏥 医疗集成**: 与医疗保健提供者的无缝沟通
- **👨‍👩‍👧‍👦 家庭支持**: 为父母和护理者提供参与护理的工具
- **🔒 隐私与安全**: 符合HIPAA标准的数据保护和隐私措施
- **📚 教育内容**: 适合年龄的骨折愈合信息

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 开发路线图 -->
## 开发路线图

- [x] 基础康复锻炼库
- [x] 进度追踪系统
- [x] 用户认证和个人资料
- [ ] AI驱动的锻炼推荐
- [ ] 远程医疗集成
- [ ] 多语言支持
    - [ ] 西班牙语
    - [x] 中文
- [ ] Apple Watch 兼容性
- [ ] 高级分析仪表板
- [ ] 同伴支持的社交功能

查看 [开放问题](https://github.com/FlyDinosaur/FractureGo/issues) 获取建议功能的完整列表（和已知问题）。

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 贡献 -->
## 贡献

贡献使开源社区成为一个学习、启发和创造的绝佳场所。您的任何贡献都**非常感谢**。

如果您有改进建议，请fork仓库并创建pull request。您也可以简单地打开一个带有"enhancement"标签的问题。
不要忘记给项目点个星！再次感谢！

1. Fork 项目
2. 创建您的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 许可证 -->
## 许可证

根据 GNU AFFERO GENERAL PUBLIC LICENSE V3.0许可证分发。查看 `LICENSE` 了解更多信息。

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 联系方式 -->
## 联系方式

项目链接: [https://github.com/FlyDinosaur/FractureGo](https://github.com/FlyDinosaur/FractureGo)

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- 致谢 -->
## 致谢

我们要感谢以下使这个项目成为可能的资源和贡献者：

* [选择开源许可证](https://choosealicense.com)
* [Img Shields](https://shields.io)
* [Font Awesome](https://fontawesome.com)
* [React Icons](https://react-icons.github.io/react-icons/search)
* [Best-README-Template](https://github.com/othneildrew/Best-README-Template)

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[Swift.org]: https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white
[Swift-url]: https://swift.org/
[iOS.apple]: https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white
[iOS-url]: https://developer.apple.com/ios/
[Xcode.apple]: https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=Xcode&logoColor=white
[Xcode-url]: https://developer.apple.com/xcode/
[UIKit.apple]: https://img.shields.io/badge/UIKit-2396F3?style=for-the-badge&logo=UIKit&logoColor=white
[UIKit-url]: https://developer.apple.com/documentation/uikit
[CoreData.apple]: https://img.shields.io/badge/Core%20Data-FC3D39?style=for-the-badge&logo=CoreData&logoColor=white
[CoreData-url]: https://developer.apple.com/documentation/coredata
[HealthKit.apple]: https://img.shields.io/badge/HealthKit-FF2D92?style=for-the-badge&logo=HealthKit&logoColor=white
[HealthKit-url]: https://developer.apple.com/documentation/healthkit 