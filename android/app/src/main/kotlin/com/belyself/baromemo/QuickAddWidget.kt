package com.belyself.baromemo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.text.SpannableString
import android.text.style.StrikethroughSpan

class QuickAddWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TOGGLE_COMPLETION) {
            val todoId = intent.getStringExtra(EXTRA_TODO_ID)
            val index = intent.getIntExtra("extra_index", -1)
            
            if (todoId != null && index != -1) {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, QuickAddWidget::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                
                // 1. SharedPreferences에서 즉시 상태 변경 (Optimistic UI)
                val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
                val key = "widget_memo_${index}_completed"
                val currentStatus = prefs.getBoolean(key, false)
                val newStatus = !currentStatus
                
                prefs.edit().putBoolean(key, newStatus).apply()

                // 2. 부분 업데이트 (Partial Update) 실행 - 깜빡임 방지
                for (appWidgetId in appWidgetIds) {
                    val partialViews = RemoteViews(context.packageName, R.layout.quick_add_widget)
                    val titleId = context.resources.getIdentifier("todo_title_$index", "id", context.packageName)
                    val checkId = context.resources.getIdentifier("todo_check_$index", "id", context.packageName)
                    val title = prefs.getString("widget_memo_${index}_title", "") ?: ""

                    if (newStatus) {
                        val spannableTitle = SpannableString(title)
                        spannableTitle.setSpan(StrikethroughSpan(), 0, title.length, 0)
                        partialViews.setTextColor(titleId, android.graphics.Color.parseColor("#99FFFFFF"))
                        partialViews.setTextViewText(titleId, spannableTitle)
                        partialViews.setImageViewResource(checkId, R.drawable.ic_check_circle)
                    } else {
                        partialViews.setTextColor(titleId, android.graphics.Color.parseColor("#FFFFFF"))
                        partialViews.setTextViewText(titleId, title)
                        partialViews.setImageViewResource(checkId, R.drawable.ic_radio_button_unchecked)
                    }
                    
                    appWidgetManager.partiallyUpdateAppWidget(appWidgetId, partialViews)
                }

                // 3. Flutter 백그라운드 콜백 호출 (데이터 최종 저장 + 위젯 새로고침)
                val backgroundIntent = es.antonborri.home_widget.HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    android.net.Uri.parse("myappwidget://togglecompletion/$todoId")
                )
                backgroundIntent.send()
            }
        }
        super.onReceive(context, intent)
    }

    companion object {
        const val ACTION_QUICK_ADD = "com.belyself.baromemo.QUICK_ADD"
        const val ACTION_OPEN_TODO = "com.belyself.baromemo.OPEN_TODO"
        const val ACTION_TOGGLE_COMPLETION = "com.belyself.baromemo.TOGGLE_COMPLETION"
        const val EXTRA_TODO_ID = "extra_todo_id"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, QuickAddWidget::class.java),
            )
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)

            // HomeWidgetPlugin.getData returns the correct SharedPreferences
            val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
            
            val count = prefs.getInt("widget_memo_count", -1)

            if (count > 0) {
                views.setViewVisibility(R.id.widget_todo_empty, View.GONE)

                for (i in 0..2) {
                    val containerId = context.resources.getIdentifier("todo_container_$i", "id", context.packageName)
                    val titleId = context.resources.getIdentifier("todo_title_$i", "id", context.packageName)
                    val checkId = context.resources.getIdentifier("todo_check_$i", "id", context.packageName)
                    val importantId = context.resources.getIdentifier("todo_important_$i", "id", context.packageName)

                    val todoId = prefs.getString("widget_memo_${i}_id", null)
                    val title = prefs.getString("widget_memo_${i}_title", null)
                    val isCompleted = prefs.getBoolean("widget_memo_${i}_completed", false)
                    val isImportant = prefs.getBoolean("widget_memo_${i}_important", false)
                    val isHighlighted = prefs.getBoolean("widget_memo_${i}_highlighted", false)

                    if (title != null && todoId != null) {
                        views.setViewVisibility(containerId, View.VISIBLE)
                        
                        // 중요 메모는 '★' 접두사와 금색으로 표시
                        val displayTitle = if (isHighlighted) "★ $title" else title
                        val spannableTitle = SpannableString(displayTitle)

                        if (isCompleted) {
                            spannableTitle.setSpan(StrikethroughSpan(), 0, displayTitle.length, 0)
                            views.setTextColor(titleId, android.graphics.Color.parseColor("#99FFFFFF"))
                            views.setImageViewResource(checkId, R.drawable.ic_check_circle)
                        } else if (isHighlighted) {
                            // 중요 메모: 제목 금색 표시
                            views.setTextColor(titleId, android.graphics.Color.parseColor("#FFD700"))
                            views.setImageViewResource(checkId, R.drawable.ic_radio_button_unchecked)
                        } else {
                            views.setTextColor(titleId, android.graphics.Color.parseColor("#FFFFFF"))
                            views.setImageViewResource(checkId, R.drawable.ic_radio_button_unchecked)
                        }
                        views.setTextViewText(titleId, spannableTitle)

                        if (isImportant) {
                            views.setViewVisibility(importantId, View.VISIBLE)
                        } else {
                            views.setViewVisibility(importantId, View.GONE)
                        }

                        // 제목 클릭 시 메인 앱의 해당 메모 열기
                        val openIntent = Intent(context, MainActivity::class.java).apply {
                            action = ACTION_OPEN_TODO
                            putExtra(EXTRA_TODO_ID, todoId)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val openPendingIntent = PendingIntent.getActivity(
                            context,
                            appWidgetId * 10 + i,
                            openIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                        )
                        // 제목(titleId)에만 클릭 리스너 설정 (컨테이너나 배경X)
                        views.setOnClickPendingIntent(titleId, openPendingIntent)

                        // 체크박스 클릭 시 (네이티브에서 즉시 상태 변경 후 Flutter 호출)
                        val toggleIntent = Intent(context, QuickAddWidget::class.java).apply {
                            action = ACTION_TOGGLE_COMPLETION
                            putExtra(EXTRA_TODO_ID, todoId)
                            putExtra("extra_index", i)
                        }
                        val togglePendingIntent = PendingIntent.getBroadcast(
                            context,
                            appWidgetId * 100 + i,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(checkId, togglePendingIntent)
                        
                    } else {
                        views.setViewVisibility(containerId, View.GONE)
                    }
                }
            } else {
                views.setViewVisibility(R.id.widget_todo_empty, View.VISIBLE)
                val containers = intArrayOf(R.id.todo_container_0, R.id.todo_container_1, R.id.todo_container_2)
                for (id in containers) {
                    views.setViewVisibility(id, View.GONE)
                }
                
                if (count == -1) {
                    views.setTextViewText(R.id.widget_todo_empty, "앱을 열어 메모를 추가하세요")
                } else {
                    views.setTextViewText(R.id.widget_todo_empty, "위젯에 표시할 메모가 없어요 ✨\n앱에서 '위젯에 고정'을 눌러보세요.")
                }
            }

            // "메모 추가하기" 버튼 탭 설정
            val intent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_QUICK_ADD
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.btn_quick_add, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
