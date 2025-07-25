package com.svgaplayer.events

import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class TopLoadedEvent(
    surfaceId: Int,
    viewTag: Int,
    private val eventData: WritableMap
) : Event<TopLoadedEvent>(surfaceId, viewTag) {

    companion object {
        const val EVENT_NAME = "onLoaded"
    }

    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap? = eventData
}
