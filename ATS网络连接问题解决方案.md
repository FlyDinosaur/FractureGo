# FractureGo ATS网络连接问题解决方案

## 问题描述

FractureGo应用尝试连接到HTTP服务器 `http://117.72.161.6:28974` 时被iOS的App Transport Security (ATS) 策略阻止，出现以下错误：

```
App Transport Security has blocked a cleartext HTTP connection to 117.72.161.6 since it is insecure. Use HTTPS instead or add this domain to Exception Domains in your Info.plist.
```

## 根本原因

iOS 9.0以后，Apple默认要求所有网络连接使用HTTPS协议。当应用尝试连接到HTTP服务器时，ATS会阻止这些连接以保护用户数据安全。

## 解决方案

### 方案一：使用自动修复脚本（推荐）

我们提供了一个自动修复脚本 `fix-ats-config.sh`，可以自动为编译后的应用添加ATS配置。

#### 使用步骤：

1. **编译项目**
   ```bash
   # 编译模拟器版本
   xcodebuild -workspace FractureGo.xcworkspace -scheme FractureGo -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   
   # 编译真机版本
   xcodebuild -workspace FractureGo.xcworkspace -scheme FractureGo -destination 'generic/platform=iOS' build
   ```

2. **运行修复脚本**
   ```bash
   ./fix-ats-config.sh
   ```

3. **重新安装应用**
   - **模拟器**：脚本会提供具体的重启命令
   - **真机**：在Xcode中按 `Cmd+R` 重新运行应用

### 方案二：手动修复

如果自动脚本不工作，可以手动添加ATS配置：

1. **找到编译输出的Info.plist文件**
   ```bash
   # 模拟器版本
   find ~/Library/Developer/Xcode/DerivedData/FractureGo-*/Build/Products/Debug-iphonesimulator/FractureGo.app/Info.plist
   
   # 真机版本
   find ~/Library/Developer/Xcode/DerivedData/FractureGo-*/Build/Products/Debug-iphoneos/FractureGo.app/Info.plist
   ```

2. **添加ATS配置**
   ```bash
   plutil -insert NSAppTransportSecurity -xml '<dict><key>NSAllowsArbitraryLoads</key><true/></dict>' [Info.plist文件路径]
   ```

3. **验证配置**
   ```bash
   plutil -p [Info.plist文件路径] | grep -A 3 "NSAppTransportSecurity"
   ```

### 方案三：项目级配置（长期解决方案）

为了避免每次编译后都需要手动修复，可以在项目的Build Settings中添加ATS配置：

1. 在Xcode中打开项目
2. 选择`FractureGo`目标
3. 进入`Build Settings`标签
4. 搜索`Info.plist`
5. 在`Info.plist Values`部分添加：
   ```
   INFOPLIST_KEY_NSAppTransportSecurity_NSAllowsArbitraryLoads = YES
   ```

## ATS配置说明

添加的配置内容：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

这个配置的含义：
- `NSAppTransportSecurity`：ATS配置的根键
- `NSAllowsArbitraryLoads`：允许加载任意HTTP连接（包括不安全的连接）

## 安全考虑

⚠️ **重要安全提醒**：

1. **生产环境建议**：在生产环境中，建议服务器配置SSL证书，使用HTTPS协议
2. **更精确的配置**：可以使用更精确的ATS异常配置，只允许特定域名的HTTP连接
3. **数据保护**：HTTP连接不加密，可能导致数据泄露

### 更安全的ATS配置示例

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>117.72.161.6</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## 故障排除

### 问题1：修复脚本找不到Info.plist文件
**解决方案**：确保已经编译了项目
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/FractureGo*
xcodebuild -workspace FractureGo.xcworkspace -scheme FractureGo -destination 'generic/platform=iOS' build
```

### 问题2：真机上仍然出现ATS错误
**解决方案**：
1. 删除设备上的应用
2. 重新从Xcode安装应用
3. 确保使用的是修复后的版本

### 问题3：模拟器上仍然出现ATS错误
**解决方案**：
```bash
xcrun simctl terminate booted net.appcontest.FractureGo
xcrun simctl launch booted net.appcontest.FractureGo
```

## 验证解决方案

成功解决后，应该能看到：
1. 应用可以正常连接到 `http://117.72.161.6:28974/health`
2. 登录功能可以正常工作
3. 不再出现ATS相关的错误信息

## 相关文件

- `fix-ats-config.sh`：自动修复脚本
- `FractureGo/Models/DatabaseConfig.swift`：网络配置文件
- `FractureGo/Models/NetworkService.swift`：网络服务文件

## 测试命令

手动测试服务器连接：
```bash
curl -v "http://117.72.161.6:28974/health" -H "Accept: application/json" -H "User-Agent: FractureGo-iOS/1.0"
```

期望响应：
```json
{"success":true,"message":"FractureGo服务器运行正常","timestamp":"...","version":"1.0.0"}
``` 