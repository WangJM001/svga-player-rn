package com.svgaplayer

import android.content.Context
import android.util.Log
import com.facebook.infer.annotation.Assertions
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.SvgaPlayerViewManagerDelegate
import com.facebook.react.viewmanagers.SvgaPlayerViewManagerInterface
import com.opensource.svgaplayer.SVGAParser
import com.opensource.svgaplayer.SVGAVideoEntity
import com.opensource.svgaplayer.SVGACache
import com.svgaplayer.events.TopErrorEvent
import com.svgaplayer.events.TopFinishedEvent
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.net.URL

@ReactModule(name = SvgaPlayerViewManager.NAME)
class SvgaPlayerViewManager : SimpleViewManager<SvgaPlayerView>(), SvgaPlayerViewManagerInterface<SvgaPlayerView> {

  companion object {
    const val NAME = "SvgaPlayerView"
  }

  private val mDelegate: ViewManagerDelegate<SvgaPlayerView> = SvgaPlayerViewManagerDelegate(this)

  override fun getName(): String = NAME

  override fun getDelegate(): ViewManagerDelegate<SvgaPlayerView>? = mDelegate

  override fun createViewInstance(c: ThemedReactContext): SvgaPlayerView {
    return SvgaPlayerView(c, null, 0)
  }

  override fun setSource(view: SvgaPlayerView, source: String?) {
    val context = view.context
    source?.let {
      val parseCompletion = object : SVGAParser.ParseCompletion {
        override fun onError() {
          view.setVideoItem(null)
          view.clear()

          val errorData = Arguments.createMap()
          errorData.putString("error", "Failed to load SVGA : $it")
          val surfaceId = UIManagerHelper.getSurfaceId(context)
          val errorEvent = TopErrorEvent(surfaceId, view.id, errorData)
          val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context as ThemedReactContext, view.id)
          dispatcher?.dispatchEvent(errorEvent)
        }

        override fun onComplete(videoItem: SVGAVideoEntity) {
          view.setVideoItem(videoItem)
          if(view.autoPlay){
            view.startAnimationSafely()
          }
        }
      }

      when {
        it.startsWith("http") || it.startsWith("https") -> {
          SVGAParser(context).decodeFromURL(URL(it), parseCompletion)
        }
        it.startsWith("file://") -> {
          // 移除 file:// 前缀，获取实际文件路径
          val filePath = it.removePrefix("file://")
          val file = File(filePath)

          if (file.exists() && file.isFile) {
            val inputStream = FileInputStream(file)
            val cacheKey = SVGACache.buildCacheKey(it)
            SVGAParser(context).decodeFromInputStream(inputStream, cacheKey, parseCompletion)
          } else {
            parseCompletion.onError()
          }
        }
        else -> {
          Log.d("SvgaPlayerViewManager", "Loading from assets: $it")
          SVGAParser(context).decodeFromAssets(it, parseCompletion)
        }
      }
    }
  }

  override fun setLoops(view: SvgaPlayerView, loops: Int) {
    view.loops = loops
  }

  override fun setClearsAfterStop(view: SvgaPlayerView, clearsAfterStop: Boolean) {
    view.clearsAfterDetached = clearsAfterStop
    view.clearsAfterStop = clearsAfterStop
  }

  override fun setAutoPlay(view: SvgaPlayerView, autoPlay: Boolean) {
    view.autoPlay = autoPlay
  }


  override fun receiveCommand(root: SvgaPlayerView, commandId: String, args: ReadableArray?) {
    super.receiveCommand(root, commandId, args)
    when (commandId) {
      "startAnimation" -> startAnimation(root)
      "stopAnimation" -> stopAnimation(root)
    }
  }

  override fun startAnimation(view: SvgaPlayerView) {
    view.startAnimationSafely()
  }

  override fun stopAnimation(view: SvgaPlayerView) {
    view.stopAnimation(true)
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
    val export = super.getExportedCustomDirectEventTypeConstants()?.toMutableMap()
      ?: mutableMapOf<String, Any>()

    export[TopErrorEvent.EVENT_NAME] = mapOf("registrationName" to "onError")
    export[TopFinishedEvent.EVENT_NAME] = mapOf("registrationName" to "onFinished")

    return export
  }
}
