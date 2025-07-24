import { useRef, useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  Button,
  Alert,
  Text,
  ScrollView,
  Switch,
} from 'react-native';
import {
  SvgaPlayer,
  type SvgaPlayerRef,
  type SvgaErrorEvent,
} from '@jayming/svga-player-rn';

// Assets 中的 SVGA 文件列表
const SVGA_ASSETS = [
  { name: '嘉年华', file: 'jianianhua.svga' },
  { name: '天使', file: 'angel.svga' },
  { name: '王者', file: 'kingset.svga' },
  { name: '大文件', file: '1651892151.svga' },
];

export default function App() {
  const svgaRef = useRef<SvgaPlayerRef>(null);
  const [currentAssetIndex, setCurrentAssetIndex] = useState<number>(0);
  const [logs, setLogs] = useState<string[]>([]);
  const [autoPlay, setAutoPlay] = useState(true);
  const [loops, setLoops] = useState(0);
  const [clearsAfterStop, setClearsAfterStop] = useState(true);
  const [align, setAlign] = useState<'top' | 'bottom' | 'center'>('center');

  // 当前源
  const currentSource =
    SVGA_ASSETS[currentAssetIndex]?.file || 'jianianhua.svga';

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

  // 事件处理函数
  const handleError = (event: SvgaErrorEvent) => {
    const errorMsg = event.error || 'Unknown error';
    addLog(`❌ SVGA load error: ${errorMsg}`);
    Alert.alert('Error', errorMsg);
  };

  const handleFinished = () => {
    addLog('🏁 SVGA animation finished - event received');
  };

  const handleLoaded = () => {
    addLog(
      `✅ [${SVGA_ASSETS[currentAssetIndex]?.name}] SVGA loaded successfully`
    );
  };

  // 控制函数
  const handleStart = () => {
    addLog(`▶️ Starting animation... (loops: ${loops === 0 ? '∞' : loops})`);
    svgaRef.current?.startAnimation();
  };

  const handleStop = () => {
    addLog('⏹️ Stopping animation...');
    svgaRef.current?.stopAnimation();
  };

  // SVGA 资源切换函数
  const switchToAsset = (index: number) => {
    const asset = SVGA_ASSETS[index];
    if (asset) {
      addLog(`🔄 Switching to: ${asset.name} (${asset.file})`);
      setCurrentAssetIndex(index);
    }
  };

  const clearLogs = () => {
    setLogs([]);
    addLog('🧹 Logs cleared');
  };

  return (
    <ScrollView style={styles.container}>
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

        <View style={styles.settingRow}>
          <Text style={styles.settingLabel}>Align Mode:</Text>
          <View style={styles.contentModeButtons}>
            <Button
              title="Top"
              onPress={() => setAlign('top')}
              color={align === 'top' ? 'blue' : undefined}
            />
            <Button
              title="Center"
              onPress={() => setAlign('center')}
              color={align === 'center' ? 'green' : undefined}
            />
            <Button
              title="Bottom"
              onPress={() => setAlign('bottom')}
              color={align === 'bottom' ? 'red' : undefined}
            />
          </View>
        </View>
      </View>

      {/* SVGA播放器 */}
      <View style={styles.playerContainer}>
        <SvgaPlayer
          ref={svgaRef}
          source={currentSource}
          autoPlay={autoPlay}
          loops={loops}
          clearsAfterStop={clearsAfterStop}
          align={align}
          style={styles.player}
          onError={handleError}
          onFinished={handleFinished}
          onLoaded={handleLoaded}
        />
      </View>

      {/* 控制按钮 */}
      <View style={styles.buttonContainer}>
        <Button title="▶️ Play" onPress={handleStart} />
        <Button title="⏹️ Stop" onPress={handleStop} />
      </View>

      {/* SVGA 资源切换按钮 */}
      <View style={styles.sourceButtonContainer}>
        <Text style={styles.sectionTitle}>🎬 SVGA Assets</Text>
        <View style={styles.contentModeButtons}>
          {SVGA_ASSETS.map((asset, index) => (
            <Button
              key={asset.file}
              title={asset.name}
              onPress={() => switchToAsset(index)}
              color={currentAssetIndex === index ? 'red' : undefined}
            />
          ))}
        </View>
        <Text style={styles.statusText}>
          Current: {SVGA_ASSETS[currentAssetIndex]?.name} ({currentSource})
        </Text>
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
  contentModeButtons: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
  },
  playerContainer: {
    alignItems: 'center',
    marginBottom: 16,
  },
  player: {
    width: 320,
    height: 420,
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
  statusText: {
    fontSize: 12,
    marginTop: 8,
    color: '#666',
    textAlign: 'center',
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
});
