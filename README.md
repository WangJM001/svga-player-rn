# svga-player-rn

一个 React Native SVGA 播放器库，支持播放 SVGA 动画文件。

## 安装

```sh
npm install svga-player-rn
```

## 使用方法

### 基础用法

```js
import { SvgaPlayerView } from 'svga-player-rn';

// 基础使用
<SvgaPlayerView
  source="https://example.com/animation.svga"
  style={{ width: 200, height: 200 }}
/>;
```

### 高级用法

```js
import React, { useRef, useState } from 'react';
import { SvgaPlayerView, type SvgaPlayerViewRef, type SvgaSource } from "svga-player-rn";

function App() {
  const svgaRef = useRef<SvgaPlayerViewRef>(null);
  const [source, setSource] = useState<SvgaSource>(
    'https://example.com/animation.svga'
  );

  const handleStart = () => {
    svgaRef.current?.start();
  };

  const handleStop = () => {
    svgaRef.current?.stop();
  };

  // 不同的 source 类型示例
  const loadRemoteFile = () => {
    setSource('https://example.com/animation.svga');
  };

  const loadDownloadedFile = () => {
    // 加载已下载到本地的文件
    setSource({
      path: '/var/mobile/Containers/Data/Application/xxxx/Documents/downloaded.svga'
    });
  };

  const loadBundleFile = () => {
    // 加载打包在 app 中的文件
    setSource({
      bundle: 'animation.svga'
    });
  };

  const loadFileURI = () => {
    // 使用 file:// 协议
    setSource({
      uri: 'file:///path/to/cached/animation.svga'
    });
  };

  return (
    <SvgaPlayerView
      ref={svgaRef}
      source={source}                             // 支持多种 source 类型
      autoPlay={true}                             // 自动播放，默认 true
      loops={0}                                   // 循环次数，默认 0（无限循环）
      clearsAfterStop={true}                      // 停止后清空画布，默认 true
      fillMode="Forward"                          // 填充模式，默认 'Forward'
      style={{ width: 200, height: 200 }}
      onFinished={() => console.log('播放完成')}   // 播放完成回调
      onFrame={(event) => {                       // 帧变化回调
        console.log('当前帧:', event.nativeEvent.frame);
      }}
      onPercentage={(event) => {                  // 播放进度回调
        console.log('播放进度:', event.nativeEvent.percentage);
      }}
    />
  );
}
```

### Source 类型

`source` 属性支持多种类型，以适应不同的使用场景：

```typescript
// 直接字符串路径或 URL
source="https://example.com/animation.svga"
source="/path/to/local/file.svga"
source="bundle_file.svga"

// 对象格式 - 远程 URL 或本地文件路径
source={{ uri: "https://example.com/animation.svga" }}
source={{ uri: "file:///path/to/local/file.svga" }}

// 对象格式 - bundle 中的文件
source={{ bundle: "animation.svga" }}

// 对象格式 - 绝对路径（常用于下载的文件）
source={{ path: "/var/mobile/Containers/Data/Application/xxxx/Documents/downloaded.svga" }}
```

### 使用场景

1. **远程加载**：直接从网络加载 SVGA 文件

   ```js
   source = 'https://example.com/animation.svga';
   ```

2. **预下载缓存**：应用预先下载文件到本地，然后加载本地文件

   ```js
   // 下载文件到本地后
   source={{ path: downloadedFilePath }}
   ```

3. **Bundle 资源**：使用打包在应用中的 SVGA 文件

   ```js
   source={{ bundle: "animation.svga" }}
   ```

4. **动态切换**：根据业务需求动态切换 source，播放器会自动重置并加载新文件

   ```js
   const [currentSource, setCurrentSource] = useState(source1);

   // 切换到新的 source 时，播放器自动重置并加载新文件
   setCurrentSource(source2);
   ```

## API 参考

### Props

| 属性              | 类型                      | 默认值      | 描述                                                  |
| ----------------- | ------------------------- | ----------- | ----------------------------------------------------- |
| `source`          | `SvgaSource`              | -           | SVGA 文件源，支持多种格式（详见下方 Source 类型说明） |
| `autoPlay`        | `boolean`                 | `true`      | 是否自动播放                                          |
| `loops`           | `number`                  | `0`         | 循环播放次数，0 表示无限循环                          |
| `clearsAfterStop` | `boolean`                 | `true`      | 动画停止后是否清空画布                                |
| `fillMode`        | `'Forward' \| 'Backward'` | `'Forward'` | 填充模式：Forward 停留在最后一帧，Backward 回到第一帧 |
| `onFinished`      | `function`                | -           | 播放完成时的回调函数                                  |
| `onFrame`         | `function`                | -           | 帧变化时的回调函数                                    |
| `onPercentage`    | `function`                | -           | 播放进度变化时的回调函数                              |

### SvgaSource 类型

```typescript
type SvgaSource =
  | string // 直接的字符串路径或 URL
  | { uri: string } // 远程 URL 或本地文件路径
  | { bundle: string } // bundle 中的文件名
  | { path: string }; // 绝对路径
```

### Ref 方法使用示例

```js
const svgaRef = useRef < SvgaPlayerViewRef > null;

// 基本播放控制
svgaRef.current?.startAnimation(); // 从头开始播放
svgaRef.current?.pauseAnimation(); // 暂停
svgaRef.current?.stopAnimation(); // 停止

// 范围播放
svgaRef.current?.startAnimationWithRange(10, 30, false); // 从第10帧播放30帧，正向
svgaRef.current?.startAnimationWithRange(10, 30, true); // 从第10帧播放30帧，反向

// 精确跳转
svgaRef.current?.stepToFrame(25, true); // 跳到第25帧并播放
svgaRef.current?.stepToFrame(25, false); // 跳到第25帧但不播放
svgaRef.current?.stepToPercentage(0.5, true); // 跳到50%位置并播放
```

### Ref 方法

| 方法                                                 | 描述                                            |
| ---------------------------------------------------- | ----------------------------------------------- |
| `startAnimation()`                                   | 从第0帧开始播放动画                             |
| `startAnimationWithRange(location, length, reverse)` | 在指定范围内播放动画，可选择反向播放            |
| `pauseAnimation()`                                   | 暂停动画，停留在当前帧                          |
| `stopAnimation()`                                    | 停止动画，根据 clearsAfterStop 决定是否清空画布 |
| `stepToFrame(frame, andPlay)`                        | 跳转到指定帧，可选择是否从该帧开始播放          |
| `stepToPercentage(percentage, andPlay)`              | 跳转到指定百分比位置 (0.0-1.0)，可选择是否播放  |

### 事件回调

```typescript
// onFinished 事件
onFinished: (event: { nativeEvent: { finished: boolean } }) => void

// onFrame 事件
onFrame: (event: { nativeEvent: { frame: number; percentage: number } }) => void

// onPercentage 事件
onPercentage: (event: { nativeEvent: { frame: number; percentage: number } }) => void
```

## 支持的平台

- ✅ iOS
- ✅ Android

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
