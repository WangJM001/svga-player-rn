import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import codegenNativeCommands from 'react-native/Libraries/Utilities/codegenNativeCommands';
import type { ViewProps, HostComponent } from 'react-native';
import type {
  DirectEventHandler,
  Int32,
  Double,
} from 'react-native/Libraries/Types/CodegenTypes';

interface FrameEvent {
  frame: Int32;
  percentage: Double;
}

interface FinishedEvent {
  finished: boolean;
}

interface LoadEvent {
  loaded: boolean;
}

interface ErrorEvent {
  error: string;
}

interface PauseEvent {
  paused: boolean;
}

interface RepeatEvent {
  repeat: boolean;
}

interface NativeProps extends ViewProps {
  source?: string;
  autoPlay?: boolean;
  loops?: Int32;
  clearsAfterStop?: boolean;
  onLoad?: DirectEventHandler<LoadEvent>;
  onError?: DirectEventHandler<ErrorEvent>;
  onFinished?: DirectEventHandler<FinishedEvent>;
  onFrame?: DirectEventHandler<FrameEvent>;
  onPercentage?: DirectEventHandler<FrameEvent>;
  onPause?: DirectEventHandler<PauseEvent>;
  onRepeat?: DirectEventHandler<RepeatEvent>;
}

export type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  startAnimation: (viewRef: React.ElementRef<ComponentType>) => void;
  startAnimationWithRange: (
    viewRef: React.ElementRef<ComponentType>,
    location: Int32,
    length: Int32,
    reverse: boolean
  ) => void;
  pauseAnimation: (viewRef: React.ElementRef<ComponentType>) => void;
  stopAnimation: (viewRef: React.ElementRef<ComponentType>) => void;
  stepToFrame: (
    viewRef: React.ElementRef<ComponentType>,
    frame: Int32,
    andPlay: boolean
  ) => void;
  stepToPercentage: (
    viewRef: React.ElementRef<ComponentType>,
    percentage: Double,
    andPlay: boolean
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    'startAnimation',
    'startAnimationWithRange',
    'pauseAnimation',
    'stopAnimation',
    'stepToFrame',
    'stepToPercentage',
  ],
});

export default codegenNativeComponent<NativeProps>('SvgaPlayerView');
