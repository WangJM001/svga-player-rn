import { useRef, useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  Button,
  Alert,
  Text,
  ScrollView,
  TextInput,
  Switch,
} from 'react-native';
import {
  RNSvgaPlayer,
  type RNSvgaPlayerRef,
  type SvgaErrorEvent,
} from '@jayming/svga-player-rn';

export default function App() {
  const svgaRef = useRef<RNSvgaPlayerRef>(null);
  const [currentSource, setCurrentSource] = useState<string>('angel.svga');
  const [logs, setLogs] = useState<string[]>([]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [customUrl, setCustomUrl] = useState('');
  const [autoPlay, setAutoPlay] = useState(true);
  const [loops, setLoops] = useState(0);
  const [clearsAfterStop, setClearsAfterStop] = useState(true);
  const [showPlayer, setShowPlayer] = useState(true); // 用于测试组件生命周期

  // 添加日志的辅助函数
  const addLog = (message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    const logMessage = `[${timestamp}] ${message}`;
    console.log(logMessage);
    setLogs((prevLogs) => [...prevLogs.slice(-19), logMessage]); // 保持最新20条日志
  };

  // 初始化时添加欢迎日志
  useEffect(() => {
    addLog('🚀 SVGA Player Test App initialized');
  }, []);

  // 监控播放器组件的挂载/卸载
  useEffect(() => {
    if (showPlayer) {
      addLog('📱 SVGA Player component mounted');
    } else {
      addLog('🗑️ SVGA Player component unmounted');
    }
  }, [showPlayer]);

  // 事件处理函数
  const handleError = (event: SvgaErrorEvent) => {
    const errorMsg = event.error || 'Unknown error';
    addLog(`❌ SVGA load error: ${errorMsg}`);
    setIsPlaying(false);
    Alert.alert('Error', errorMsg);
  };

  const handleFinished = () => {
    addLog('🏁 SVGA animation finished - event received');
    setIsPlaying(false);
  };

  // 控制函数
  const handleStart = () => {
    addLog(`▶️ Starting animation... (loops: ${loops === 0 ? '∞' : loops})`);
    setIsPlaying(true);
    svgaRef.current?.startAnimation();
  };

  const handleStop = () => {
    addLog('⏹️ Stopping animation...');
    setIsPlaying(false);
    svgaRef.current?.stopAnimation();
  };

  // 源切换函数
  const switchToRemoteURL = () => {
    const newSource =
      'https://raw.githubusercontent.com/yyued/SVGAPlayer-iOS/master/SVGAPlayer/Samples/Goddess.svga';
    addLog(`🔄 Switching to remote URL: ${newSource}`);
    setCurrentSource(newSource);
  };

  const switchToAsset = () => {
    const newSource = 'angel.svga';
    addLog(`🔄 Switching to asset file: ${newSource}`);
    setCurrentSource(newSource);
  };

  const useCustomUrl = () => {
    if (customUrl.trim()) {
      addLog(`🔄 Switching to custom URL: ${customUrl}`);
      setCurrentSource(customUrl.trim());
    } else {
      Alert.alert('Error', 'Please enter a valid URL');
    }
  };

  const clearLogs = () => {
    setLogs([]);
    addLog('🧹 Logs cleared');
  };

  return (
    <ScrollView style={styles.container}>
      {/* 状态信息区域 */}
      <View style={styles.statusContainer}>
        <Text style={styles.statusTitle}>🎬 SVGA Player Status</Text>
        <Text style={styles.statusText}>
          Status: {isPlaying ? '🎵 Playing' : '⏸️ Stopped'}
        </Text>
        <Text style={styles.statusText} numberOfLines={2}>
          Source: {currentSource}
        </Text>
      </View>

      {/* 播放器设置 */}
      <View style={styles.settingsContainer}>
        <Text style={styles.sectionTitle}>⚙️ Settings</Text>

        <View style={styles.settingRow}>
          <Text style={styles.settingLabel}>Auto Play:</Text>
          <Switch value={autoPlay} onValueChange={setAutoPlay} />
        </View>

        <View style={styles.settingRow}>
          <Text style={styles.settingLabel}>Clear After Stop:</Text>
          <Switch value={clearsAfterStop} onValueChange={setClearsAfterStop} />
        </View>

        <View style={styles.settingRow}>
          <Text style={styles.settingLabel}>Loops:</Text>
          <View style={styles.loopButtons}>
            <Button
              title="∞"
              onPress={() => setLoops(0)}
              color={loops === 0 ? 'red' : undefined}
            />
            <Button
              title="1"
              onPress={() => setLoops(1)}
              color={loops === 1 ? 'red' : undefined}
            />
            <Button
              title="2"
              onPress={() => setLoops(2)}
              color={loops === 2 ? 'red' : undefined}
            />
            <Button
              title="3"
              onPress={() => setLoops(3)}
              color={loops === 3 ? 'red' : undefined}
            />
          </View>
        </View>
      </View>

      {/* SVGA播放器 */}
      <View style={styles.playerContainer}>
        {showPlayer ? (
          <RNSvgaPlayer
            ref={svgaRef}
            source={currentSource}
            autoPlay={autoPlay}
            loops={loops}
            clearsAfterStop={clearsAfterStop}
            style={styles.player}
            onError={handleError}
            onFinished={handleFinished}
          />
        ) : (
          <View style={[styles.player, styles.placeholderPlayer]}>
            <Text style={styles.placeholderText}>
              📱 Player Unmounted{'\n'}
              Use "Mount Player" to restore
            </Text>
          </View>
        )}
      </View>

      {/* 控制按钮 */}
      <View style={styles.buttonContainer}>
        <Button title="▶️ Play" onPress={handleStart} />
        <Button title="⏹️ Stop" onPress={handleStop} />
      </View>

      {/* 生命周期测试按钮 */}
      <View style={styles.buttonContainer}>
        <Button
          title={showPlayer ? '🗑️ Unmount Player' : '📱 Mount Player'}
          onPress={() => {
            if (showPlayer) {
              addLog('🗑️ Unmounting SVGA Player component...');
              setShowPlayer(false);
              setIsPlaying(false);
            } else {
              addLog('📱 Mounting SVGA Player component...');
              setShowPlayer(true);
            }
          }}
          color={showPlayer ? 'red' : 'green'}
        />
        <Button
          title="📝 Clear Logs"
          onPress={() => {
            setLogs([]);
            addLog('🧹 Logs cleared');
          }}
        />
      </View>

      {/* 预设源切换按钮 */}
      <View style={styles.sourceButtonContainer}>
        <Button title="Asset" onPress={switchToAsset} />
        <Button title="Remote" onPress={switchToRemoteURL} />
      </View>

      {/* 自定义URL输入 */}
      <View style={styles.urlInputContainer}>
        <Text style={styles.sectionTitle}>🔗 Custom URL</Text>
        <TextInput
          style={styles.urlInput}
          value={customUrl}
          onChangeText={setCustomUrl}
          placeholder="Enter SVGA URL..."
          placeholderTextColor="#999"
        />
        <Button title="Load URL" onPress={useCustomUrl} />
      </View>

      {/* 日志区域 */}
      <View style={styles.logContainer}>
        <View style={styles.logHeader}>
          <Text style={styles.logTitle}>📝 Activity Log</Text>
          <Button title="Clear" onPress={clearLogs} />
        </View>
        <ScrollView style={styles.logScrollView} nestedScrollEnabled={true}>
          {logs.length === 0 ? (
            <Text style={styles.emptyLogText}>No logs yet...</Text>
          ) : (
            logs.map((log, index) => (
              <Text key={index} style={styles.logText}>
                {log}
              </Text>
            ))
          )}
        </ScrollView>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  statusContainer: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
  },
  statusText: {
    fontSize: 14,
    marginVertical: 2,
    color: '#666',
  },
  settingsContainer: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 12,
    color: '#333',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginVertical: 8,
  },
  settingLabel: {
    fontSize: 14,
    color: '#666',
  },
  loopButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  playerContainer: {
    alignItems: 'center',
    marginBottom: 16,
  },
  player: {
    width: 280,
    height: 280,
    borderWidth: 2,
    borderColor: '#007AFF',
    borderRadius: 12,
    backgroundColor: '#fff',
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'center',
    marginBottom: 16,
  },
  sourceButtonContainer: {
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'center',
    marginBottom: 16,
  },
  urlInputContainer: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  urlInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    marginVertical: 8,
    fontSize: 14,
    backgroundColor: '#f9f9f9',
  },
  logContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
    minHeight: 200,
  },
  logHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  logTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  logScrollView: {
    maxHeight: 200,
    backgroundColor: '#f8f8f8',
    padding: 12,
    borderRadius: 8,
  },
  logText: {
    fontSize: 12,
    fontFamily: 'monospace',
    color: '#333',
    marginVertical: 1,
    lineHeight: 16,
  },
  emptyLogText: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
    fontStyle: 'italic',
    padding: 20,
  },
  placeholderPlayer: {
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f0f0f0',
    borderStyle: 'dashed',
  },
  placeholderText: {
    fontSize: 16,
    color: '#999',
    textAlign: 'center',
    fontWeight: 'bold',
  },
});
