package com.yona.app.core

import android.content.Context
import com.yona.app.YonaApplication

/** Small persisted UI preferences (SharedPreferences), e.g. the Home sort choice. */
object Settings {
    private const val KEY_SORT = "tile_sort"

    private val prefs by lazy {
        YonaApplication.instance.getSharedPreferences("yona_prefs", Context.MODE_PRIVATE)
    }

    var tileSort: TileSort
        get() = prefs.getString(KEY_SORT, null)
            ?.let { runCatching { TileSort.valueOf(it) }.getOrNull() }
            ?: TileSort.RECENT
        set(value) {
            prefs.edit().putString(KEY_SORT, value.name).apply()
        }
}
