package com.yona.app

import android.app.Application

/** Holds the application instance so process-level singletons (e.g. TileCache) can
 *  reach a Context without injecting one everywhere. */
class YonaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    companion object {
        lateinit var instance: YonaApplication
            private set
    }
}
