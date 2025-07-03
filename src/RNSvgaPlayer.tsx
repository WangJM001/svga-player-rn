import React, { useImperativeHandle, useRef } from 'react';
import type { ViewProps } from 'react-native';
import RNSvgaPlayerNative, {
  Commands,
  type ComponentType,
} from './RNSvgaPlayerNativeComponent';

export interface SvgaErrorEvent {
  error: string;
}

export interface RNSvgaPlayerProps extends ViewProps {
  ref?: React.Ref<RNSvgaPlayerRef>;
  source?: string;
  /**
   * 是否自动播放，默认 true
   */
  autoPlay?: boolean;
  /**
   * 循环播放次数，默认 1（播放一次）
   */
  loops?: number;
  /**
   * 动画停止后是否清空画布，默认 true
   */
  clearsAfterStop?: boolean;

  // 事件回调
  onError?: (event: SvgaErrorEvent) => void;
  onFinished?: () => void;
}

export interface RNSvgaPlayerRef {
  /**
   * 从第0帧开始播放动画
   */
  startAnimation: () => void;
  /**
   * 停止动画，如果 clearsAfterStop 为 true 则清空画布
   */
  stopAnimation: () => void;
}

const RNSvgaPlayer = ({
  ref,
  autoPlay = true,
  loops = 0,
  clearsAfterStop = false,
  source,
  onError,
  onFinished,
  ...restProps
}: RNSvgaPlayerProps) => {
  const nativeRef = useRef<React.ElementRef<ComponentType>>(null);

  useImperativeHandle(ref, () => ({
    startAnimation: () => {
      console.log('RNSvgaPlayer: startAnimation called from JS');
      if (nativeRef.current) {
        Commands.startAnimation(nativeRef.current);
      } else {
        console.log('RNSvgaPlayer: nativeRef.current is null');
      }
    },
    stopAnimation: () => {
      console.log('RNSvgaPlayer: stopAnimation called from JS');
      if (nativeRef.current) {
        Commands.stopAnimation(nativeRef.current);
      } else {
        console.log('RNSvgaPlayer: nativeRef.current is null');
      }
    },
  }));

  return (
    <RNSvgaPlayerNative
      ref={nativeRef}
      source={source}
      autoPlay={autoPlay}
      loops={loops}
      clearsAfterStop={clearsAfterStop}
      onError={(error) => onError?.(error.nativeEvent)}
      onFinished={onFinished}
      {...restProps}
    />
  );
};

RNSvgaPlayer.displayName = 'RNSvgaPlayer';

export default RNSvgaPlayer;
