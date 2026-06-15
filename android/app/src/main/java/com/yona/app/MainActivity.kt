package com.yona.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import com.yona.app.core.Supabase
import com.yona.app.ui.AuthGate
import com.yona.app.ui.theme.YonaTheme
import io.github.jan.supabase.auth.handleDeeplinks

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Completes an OAuth sign-in if the app was (re)launched via yona://auth-callback.
        Supabase.client.handleDeeplinks(intent)

        enableEdgeToEdge()
        setContent {
            YonaTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    AuthGate(modifier = Modifier.padding(innerPadding))
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Supabase.client.handleDeeplinks(intent)
    }
}
