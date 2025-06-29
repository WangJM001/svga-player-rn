# 国内镜像源配置

为了提高在中国大陆地区的依赖下载速度，本项目已配置了国内镜像源。

## 已配置的镜像源

### 1. Yarn/NPM 镜像

- **配置文件**: `.yarnrc.yml`
- **镜像源**: 淘宝 NPM 镜像 (`https://registry.npmmirror.com`)
- **用途**: 下载 Node.js 依赖包

### 2. CocoaPods 镜像 (iOS)

- **配置文件**: `example/ios/Podfile`
- **镜像源**: 清华大学镜像 (`https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git`)
- **用途**: 下载 iOS 原生依赖库

### 3. Android Gradle 镜像

- **配置文件**:
  - `android/build.gradle`
  - `example/android/build.gradle`
- **镜像源**: 阿里云 Maven 镜像
  - Google: `https://maven.aliyun.com/repository/google`
  - Central: `https://maven.aliyun.com/repository/central`
  - JCenter: `https://maven.aliyun.com/repository/jcenter`
  - Gradle Plugin: `https://maven.aliyun.com/repository/gradle-plugin`
- **用途**: 下载 Android 原生依赖库和 Gradle 插件

## 验证镜像配置

### 检查 Yarn 镜像

```bash
yarn config get npmRegistryServer
# 应该输出: https://registry.npmmirror.com
```

### 检查 CocoaPods 镜像

```bash
cd example/ios
pod repo list
# 应该看到清华大学镜像源
```

### 检查 Android Gradle 配置

```bash
cd example/android
./gradlew --version
# 应该能正常输出版本信息
```

## 安装和构建

使用这些镜像源后，正常的安装和构建命令应该更快：

```bash
# 安装依赖
yarn install

# iOS 依赖安装
cd example/ios
pod install

# Android 构建测试
cd ../android
./gradlew assembleDebug --dry-run
```

## 恢复默认源

如果需要恢复使用默认的官方源，可以进行以下操作：

### 恢复 Yarn 默认源

```bash
# 编辑 .yarnrc.yml，删除或注释 npmRegistryServer 行
```

### 恢复 CocoaPods 默认源

```bash
# 编辑 example/ios/Podfile，删除或注释 source 行
```

### 恢复 Android 默认源

```bash
# 编辑 build.gradle 文件，将阿里云镜像配置移除，只保留 google() 和 mavenCentral()
```

## 注意事项

1. **镜像同步延迟**: 国内镜像可能会有 1-2 小时的同步延迟，最新发布的包可能需要等待
2. **网络环境**: 某些企业网络环境可能需要配置代理才能访问这些镜像
3. **镜像稳定性**: 如果某个镜像源出现问题，可以临时切换到其他镜像或官方源

## 其他常用镜像源

### NPM 镜像选择

- 淘宝镜像: `https://registry.npmmirror.com` (推荐)
- 华为镜像: `https://repo.huaweicloud.com/repository/npm/`
- 腾讯镜像: `https://mirrors.cloud.tencent.com/npm/`

### Maven 镜像选择

- 阿里云: `https://maven.aliyun.com/repository/` (推荐)
- 华为镜像: `https://repo.huaweicloud.com/repository/maven/`
- 腾讯镜像: `https://mirrors.cloud.tencent.com/maven/`

### CocoaPods 镜像选择

- 清华大学: `https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git` (推荐)
- 码云镜像: `https://gitee.com/mirrors/CocoaPods-Specs.git`
