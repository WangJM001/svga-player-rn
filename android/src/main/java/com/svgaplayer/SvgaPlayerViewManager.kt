package com.svgaplayer

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

@ReactModule(name = SvgaPlayerViewManager.NAME)
class SvgaPlayerViewManager : SimpleViewManager<SvgaPlayerView>() {

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): SvgaPlayerView {
    return SvgaPlayerView(context)
  }

  // 属性设置方法
  @ReactProp(name = "source")
  fun setSource(view: SvgaPlayerView?, source: String?) {
    view?.setSource(source)
  }

  @ReactProp(name = "autoPlay", defaultBoolean = true)
  fun setAutoPlay(view: SvgaPlayerView?, autoPlay: Boolean) {
    view?.setAutoPlay(autoPlay)
  }

  @ReactProp(name = "loops", defaultInt = 1)
  fun setLoops(view: SvgaPlayerView?, loops: Int) {
    view?.setLoops(loops)
  }

  @ReactProp(name = "clearsAfterStop", defaultBoolean = true)
  fun setClearsAfterStop(view: SvgaPlayerView?, clearsAfterStop: Boolean) {
    view?.setClearsAfterStop(clearsAfterStop)
  }

  // 命令方法 - 新架构支持
  override fun receiveCommand(view: SvgaPlayerView, commandId: String, args: ReadableArray?) {
    when (commandId) {
      "startAnimation" -> view.startAnimation()
      "startAnimationWithRange" -> {
        args?.let {
          if (it.size() >= 3) {
            val location = it.getInt(0)
            val length = it.getInt(1)
            val reverse = it.getBoolean(2)
            view.startAnimationWithRange(location, length, reverse)
          }
        }
      }
      "pauseAnimation" -> view.pauseAnimation()
      "stopAnimation" -> view.stopAnimation()
      "stepToFrame" -> {
        args?.let {
          if (it.size() >= 2) {
            val frame = it.getInt(0)
            val andPlay = it.getBoolean(1)
            view.stepToFrame(frame, andPlay)
          }
        }
      }
      "stepToPercentage" -> {
        args?.let {
          if (it.size() >= 2) {
            val percentage = it.getDouble(0)
            val andPlay = it.getBoolean(1)
            view.stepToPercentage(percentage, andPlay)
          }
        }
      }
    }
  }

  // 旧的命令方法保留用于兼容性
  fun startAnimation(view: SvgaPlayerView?) {
    view?.startAnimation()
  }

  fun startAnimationWithRange(view: SvgaPlayerView?, location: Int, length: Int, reverse: Boolean) {
    view?.startAnimationWithRange(location, length, reverse)
  }

  fun pauseAnimation(view: SvgaPlayerView?) {
    view?.pauseAnimation()
  }

  fun stopAnimation(view: SvgaPlayerView?) {
    view?.stopAnimation()
  }

  fun stepToFrame(view: SvgaPlayerView?, frame: Int, andPlay: Boolean) {
    view?.stepToFrame(frame, andPlay)
  }

  fun stepToPercentage(view: SvgaPlayerView?, percentage: Double, andPlay: Boolean) {
    view?.stepToPercentage(percentage, andPlay)
  }

  // 事件映射 - 添加所有支持的事件
  override fun getExportedCustomBubblingEventTypeConstants(): Map<String, Any> {
    return mapOf(
      "onLoad" to mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to "onLoad"
        )
      ),
      "onError" to mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to "onError"
        )
      ),
      "onFinished" to mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to "onFinished"
        )
      ),
      "onFrame" to mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to "onFrame"
        )
      ),
      "onPercentage" to mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to "onPercentage"
        )
      ),
      "onPause" to mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to "onPause"
        )
      ),
      "onRepeat" to mapOf(
        "phasedRegistrationNames" to mapOf(
          "bubbled" to "onRepeat"
        )
      )
    )
  }

  companion object {
    const val NAME = "SvgaPlayerView"
  }
}
