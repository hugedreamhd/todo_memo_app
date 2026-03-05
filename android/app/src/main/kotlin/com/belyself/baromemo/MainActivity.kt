package com.belyself.baromemo

import android.content.Intent
import com.belyself.baromemo.QuickAddWidget
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.belyself.baromemo/widget"
    }

    private var flutterChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
    }

    override fun onStart() {
        super.onStart()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onStop() {
        super.onStop()
        // 앱을 벗어날 때(홈 화면으로 돌아갈 때) 위젯 표시 갱신
        QuickAddWidget.updateAllWidgets(this)
    }

    private fun handleIntent(intent: Intent?) {
        when (intent?.action) {
            QuickAddWidget.ACTION_QUICK_ADD -> {
                flutterChannel?.invokeMethod("quickAdd", null)
            }
            QuickAddWidget.ACTION_OPEN_TODO -> {
                val todoId = intent.getStringExtra(QuickAddWidget.EXTRA_TODO_ID)
                if (todoId != null) {
                    flutterChannel?.invokeMethod("openTodo", todoId)
                }
            }
        }
    }
}
