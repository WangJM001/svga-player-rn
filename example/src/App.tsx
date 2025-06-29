import { useRef, useState } from 'react';
import { View, StyleSheet, Button, Alert } from 'react-native';
import {
  SvgaPlayerView,
  type SvgaPlayerViewRef,
  type SvgaSource,
} from 'svga-player-rn';

export default function App() {
  const svgaRef = useRef<SvgaPlayerViewRef>(null);
  const [currentSource, setCurrentSource] = useState<SvgaSource>(
    'https://raw.githubusercontent.com/yyued/SVGAPlayer-iOS/master/SVGAPlayer/Samples/Goddess.svga'
  );

  // 事件处理函数
  const handleLoad = () => {
    console.log('SVGA loaded successfully');
  };

  const handleError = (event: any) => {
    console.error('SVGA load error:', event.nativeEvent.error);
    Alert.alert('Error', event.nativeEvent.error);
  };

  const handleFinished = () => {
    console.log('SVGA playback finished');
  };

  const handleFrame = (event: any) => {
    const { frame, percentage } = event.nativeEvent;
    console.log(`Frame: ${frame}, Percentage: ${percentage.toFixed(1)}%`);
  };

  const handlePauseEvent = () => {
    console.log('SVGA paused');
  };

  const handleRepeat = () => {
    console.log('SVGA repeat');
  };

  const handleStart = () => {
    svgaRef.current?.startAnimation();
  };

  const handleStop = () => {
    svgaRef.current?.stopAnimation();
  };

  const handlePause = () => {
    svgaRef.current?.pauseAnimation();
  };

  const handleReset = () => {
    svgaRef.current?.stepToFrame(0, false);
  };

  const handlePlayRange = () => {
    // 播放第10帧到第50帧，正向播放
    svgaRef.current?.startAnimationWithRange(10, 40, false);
  };

  const handlePlayReverse = () => {
    // 播放第10帧到第50帧，反向播放
    svgaRef.current?.startAnimationWithRange(10, 40, true);
  };

  const handleJumpToFrame = () => {
    // 跳到第30帧并播放
    svgaRef.current?.stepToFrame(30, true);
  };

  const handleJumpToPercentage = () => {
    // 跳到50%位置并播放
    svgaRef.current?.stepToPercentage(0.5, true);
  };

  // 测试不同的 source 类型
  const switchToRemoteURL = () => {
    setCurrentSource(
      'https://github.com/yyued/SVGAPlayer-Android/raw/master/app/src/main/assets/posche.svga'
    );
  };

  const switchToLocalPath = () => {
    // 假设这是从远程下载到本地的文件路径
    setCurrentSource({
      path: '/var/mobile/Containers/Data/Application/xxxx/Documents/downloaded_animation.svga',
    });
  };

  const switchToBundleFile = () => {
    setCurrentSource({
      bundle: 'sample_animation.svga',
    });
  };

  const switchToFileURI = () => {
    setCurrentSource({
      uri: 'file:///var/mobile/Containers/Data/Application/xxxx/Documents/cached_animation.svga',
    });
  };

  return (
    <View style={styles.container}>
      <SvgaPlayerView
        ref={svgaRef}
        source={currentSource}
        autoPlay={true}
        loops={1}
        clearsAfterStop={true}
        style={{
          width: 500,
          height: 500,
          borderWidth: 2,
          borderColor: 'red',
        }}
        onLoad={handleLoad}
        onError={handleError}
        onFinished={handleFinished}
        onFrame={handleFrame}
        onPause={handlePauseEvent}
        onRepeat={handleRepeat}
      />

      <View style={styles.buttonContainer}>
        <Button title="播放" onPress={handleStart} />
        <Button title="暂停" onPress={handlePause} />
        <Button title="停止" onPress={handleStop} />
        <Button title="重置" onPress={handleReset} />
      </View>

      <View style={styles.buttonContainer}>
        <Button title="范围播放" onPress={handlePlayRange} />
        <Button title="反向播放" onPress={handlePlayReverse} />
        <Button title="跳到帧" onPress={handleJumpToFrame} />
        <Button title="跳到50%" onPress={handleJumpToPercentage} />
      </View>

      <View style={styles.sourceButtonContainer}>
        <Button title="远程URL" onPress={switchToRemoteURL} />
        <Button title="本地路径" onPress={switchToLocalPath} />
        <Button title="Bundle文件" onPress={switchToBundleFile} />
        <Button title="File URI" onPress={switchToFileURI} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  box: {
    width: 200,
    height: 200,
    marginVertical: 20,
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 10,
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginBottom: 20,
  },
  sourceButtonContainer: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
    justifyContent: 'center',
  },
});
