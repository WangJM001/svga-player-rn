package com.svgaplayer

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import com.opensource.svgaplayer.SVGAImageView
import com.opensource.svgaplayer.SVGAParser
import com.opensource.svgaplayer.SVGAVideoEntity
import com.opensource.svgaplayer.SVGACallback
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import java.io.File
import java.net.URL

class SvgaPlayerView : FrameLayout {
  private val svgaImageView: SVGAImageView
  private var currentSource: String? = null
  private var autoPlay: Boolean = true
  private var loops: Int = 1
  private var clearsAfterStop: Boolean = true
  private var currentVideoEntity: SVGAVideoEntity? = null
  private val svgaParser: SVGAParser

  constructor(context: Context) : super(context) {
    svgaImageView = SVGAImageView(context)
    svgaParser = SVGAParser.shareParser()
    setupView()
  }

  constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
    svgaImageView = SVGAImageView(context)
    svgaParser = SVGAParser.shareParser()
    setupView()
  }

  constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr
  ) {
    svgaImageView = SVGAImageView(context)
    svgaParser = SVGAParser.shareParser()
    setupView()
  }

  private fun setupView() {
    // 设置默认值 - loops 默认为 1（播放一次），clearsAfterStop 默认为 true
    svgaImageView.loops = loops
    svgaImageView.clearsAfterStop = clearsAfterStop

    // 确保 SVGAImageView 能正确填充父容器
    val layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    svgaImageView.layoutParams = layoutParams

    // 设置 ScaleType 确保动画能正确显示
    svgaImageView.scaleType = android.widget.ImageView.ScaleType.FIT_CENTER

    // 添加到布局
    addView(svgaImageView)

    // 设置回调 - 使用官方标准的 SVGACallback
    svgaImageView.callback = object : SVGACallback {
      override fun onPause() {
        // 发送暂停事件
        sendEvent("onPause", Arguments.createMap().apply {
          putBoolean("paused", true)
        })
      }

      override fun onFinished() {
        // 发送完成事件
        sendEvent("onFinished", Arguments.createMap().apply {
          putBoolean("finished", true)
        })
      }

      override fun onRepeat() {
        // 发送重复事件
        sendEvent("onRepeat", Arguments.createMap().apply {
          putBoolean("repeat", true)
        })
      }

      override fun onStep(frame: Int, percentage: Double) {
        // 发送帧事件 - percentage 已经是 0.0-1.0 范围，转换为 0-100
        val eventData = Arguments.createMap().apply {
          putInt("frame", frame)
          putDouble("percentage", percentage * 100.0)
        }
        sendEvent("onFrame", eventData)
        sendEvent("onPercentage", eventData)
      }
    }
  }

  private fun sendEvent(eventName: String, params: WritableMap) {
    val reactContext = context as ReactContext
    reactContext.getJSModule(RCTEventEmitter::class.java)
      .receiveEvent(id, eventName, params)
  }

  // 属性设置方法
  fun setSource(source: String?) {
    android.util.Log.d("SvgaPlayerView", "setSource called with: $source")
    if (source != null && source != currentSource) {
      currentSource = source
      loadSVGAFromSource(source)
    }
  }

  fun setAutoPlay(autoPlay: Boolean) {
    android.util.Log.d("SvgaPlayerView", "setAutoPlay called with: $autoPlay")
    this.autoPlay = autoPlay
  }

  fun setLoops(loops: Int) {
    this.loops = loops
    svgaImageView.loops = loops
  }

  fun setClearsAfterStop(clearsAfterStop: Boolean) {
    this.clearsAfterStop = clearsAfterStop
    svgaImageView.clearsAfterStop = clearsAfterStop
  }

  // SVGA 加载方法
  private fun loadSVGAFromSource(source: String) {
    when {
      source.startsWith("http://") || source.startsWith("https://") -> {
        loadSVGAFromURL(source)
      }
      source.startsWith("file://") -> {
        loadSVGAFromFileURL(source)
      }
      source.startsWith("/") -> {
        loadSVGAFromAbsolutePath(source)
      }
      else -> {
        loadSVGAFromAssets(source)
      }
    }
  }

  private fun loadSVGAFromURL(urlString: String) {
    try {
      val url = URL(urlString)
      // 使用官方推荐的 parse 方法而不是 decodeFromURL
      svgaParser.parse(url, object : SVGAParser.ParseCompletion {
        override fun onComplete(videoItem: SVGAVideoEntity) {
          post {
            android.util.Log.d("SvgaPlayerView", "SVGA loaded successfully from URL: $urlString")
            currentVideoEntity = videoItem
            svgaImageView.setVideoItem(videoItem)

            sendEvent("onLoad", Arguments.createMap().apply {
              putBoolean("loaded", true)
            })

            if (autoPlay) {
              android.util.Log.d("SvgaPlayerView", "Starting autoPlay animation")
              svgaImageView.startAnimation()
            }
          }
        }

        override fun onError() {
          println("SVGA load from URL error: $urlString")
          sendEvent("onError", Arguments.createMap().apply {
            putString("error", "Failed to load SVGA from URL: $urlString")
          })
        }
      })
    } catch (e: Exception) {
      println("SVGA load from URL error: ${e.message}")
      sendEvent("onError", Arguments.createMap().apply {
        putString("error", "Failed to load SVGA from URL: ${e.message}")
      })
    }
  }

  private fun loadSVGAFromFileURL(fileURLString: String) {
    try {
      val filePath = fileURLString.removePrefix("file://")
      val file = File(filePath)
      if (file.exists()) {
        // 使用官方推荐的 parse 方法处理输入流
        svgaParser.parse(file.inputStream(), filePath, object : SVGAParser.ParseCompletion {
          override fun onComplete(videoItem: SVGAVideoEntity) {
            post {
              currentVideoEntity = videoItem
              svgaImageView.setVideoItem(videoItem)

              sendEvent("onLoad", Arguments.createMap().apply {
                putBoolean("loaded", true)
              })

              if (autoPlay) {
                svgaImageView.startAnimation()
              }
            }
          }

          override fun onError() {
            println("SVGA load from file URL error: $fileURLString")
            sendEvent("onError", Arguments.createMap().apply {
              putString("error", "Failed to load SVGA from file URL: $fileURLString")
            })
          }
        }, true) // closeInputStream = true
      } else {
        println("SVGA file not found at: $fileURLString")
        sendEvent("onError", Arguments.createMap().apply {
          putString("error", "SVGA file not found at: $fileURLString")
        })
      }
    } catch (e: Exception) {
      println("SVGA load from file URL error: ${e.message}")
      sendEvent("onError", Arguments.createMap().apply {
        putString("error", "Failed to load SVGA from file URL: ${e.message}")
      })
    }
  }

  private fun loadSVGAFromAbsolutePath(absolutePath: String) {
    try {
      val file = File(absolutePath)
      if (file.exists()) {
        // 使用官方推荐的 parse 方法处理输入流
        svgaParser.parse(file.inputStream(), absolutePath, object : SVGAParser.ParseCompletion {
          override fun onComplete(videoItem: SVGAVideoEntity) {
            post {
              currentVideoEntity = videoItem
              svgaImageView.setVideoItem(videoItem)

              sendEvent("onLoad", Arguments.createMap().apply {
                putBoolean("loaded", true)
              })

              if (autoPlay) {
                svgaImageView.startAnimation()
              }
            }
          }

          override fun onError() {
            println("SVGA load from absolute path error: $absolutePath")
            sendEvent("onError", Arguments.createMap().apply {
              putString("error", "Failed to load SVGA from path: $absolutePath")
            })
          }
        }, true) // closeInputStream = true
      } else {
        println("SVGA file not found at absolute path: $absolutePath")
        sendEvent("onError", Arguments.createMap().apply {
          putString("error", "SVGA file not found at: $absolutePath")
        })
      }
    } catch (e: Exception) {
      println("SVGA load from absolute path error: ${e.message}")
      sendEvent("onError", Arguments.createMap().apply {
        putString("error", "Failed to load SVGA from path: ${e.message}")
      })
    }
  }

  private fun loadSVGAFromAssets(fileName: String) {
    try {
      // 使用官方推荐的 parse 方法处理 assets 文件
      svgaParser.parse(fileName, object : SVGAParser.ParseCompletion {
        override fun onComplete(videoItem: SVGAVideoEntity) {
          post {
            currentVideoEntity = videoItem
            svgaImageView.setVideoItem(videoItem)

            sendEvent("onLoad", Arguments.createMap().apply {
              putBoolean("loaded", true)
            })

            if (autoPlay) {
              svgaImageView.startAnimation()
            }
          }
        }

        override fun onError() {
          println("SVGA load from assets error: $fileName")
          sendEvent("onError", Arguments.createMap().apply {
            putString("error", "Failed to load SVGA from assets: $fileName")
          })
        }
      })
    } catch (e: Exception) {
      println("SVGA load from assets error: ${e.message}")
      sendEvent("onError", Arguments.createMap().apply {
        putString("error", "Failed to load SVGA from assets: ${e.message}")
      })
    }
  }

  // Command 方法 - 对照官方 API 文档
  fun startAnimation() {
    if (currentVideoEntity != null) {
      svgaImageView.startAnimation()
    }
  }

  fun startAnimationWithRange(location: Int, length: Int, reverse: Boolean) {
    if (currentVideoEntity != null) {
      // SVGARange 在当前版本中不可用，使用基本方法实现
      // 跳转到起始帧后开始播放
      svgaImageView.stepToFrame(location, false)
      svgaImageView.startAnimation()

      // 注意：反向播放和精确范围控制需要更高版本的 SVGA 库支持
      if (reverse) {
        println("Reverse playback is not supported in current SVGA version")
      }
    }
  }

  fun pauseAnimation() {
    svgaImageView.pauseAnimation()
  }

  fun stopAnimation() {
    svgaImageView.stopAnimation()
  }

  fun stepToFrame(frame: Int, andPlay: Boolean) {
    if (currentVideoEntity != null) {
      svgaImageView.stepToFrame(frame, andPlay)
    }
  }

  fun stepToPercentage(percentage: Double, andPlay: Boolean) {
    if (currentVideoEntity != null) {
      // percentage 从 JS 层传入时已经是 0.0-1.0 范围，直接使用
      svgaImageView.stepToPercentage(percentage, andPlay)
    }
  }

  // 新增一些有用的方法
  fun isAnimating(): Boolean {
    return svgaImageView.isAnimating
  }

  fun getCurrentFrame(): Int {
    return currentVideoEntity?.frames ?: 0
  }
}
