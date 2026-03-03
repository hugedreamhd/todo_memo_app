package com.belyself.todolist

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import com.belyself.baromemo.MainActivity
import com.belyself.baromemo.R

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

    companion object {
        const val ACTION_QUICK_ADD = "com.belyself.todolist.QUICK_ADD"
        const val ACTION_OPEN_TODO = "com.belyself.todolist.OPEN_TODO"
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

                    if (title != null && todoId != null) {
                        views.setViewVisibility(containerId, View.VISIBLE)
                        views.setTextViewText(titleId, title)

                        // 스타일 처리
                        if (isCompleted) {
                            views.setTextColor(titleId, android.graphics.Color.parseColor("#99FFFFFF"))
                            views.setImageViewResource(checkId, R.drawable.ic_check_circle)
                        } else {
                            views.setTextColor(titleId, android.graphics.Color.parseColor("#FFFFFF"))
                            views.setImageViewResource(checkId, R.drawable.ic_radio_button_unchecked)
                        }

                        if (isImportant) {
                            views.setViewVisibility(importantId, View.VISIBLE)
                        } else {
                            views.setViewVisibility(importantId, View.GONE)
                        }

                        // 전체 아이템 클릭 시 메인 앱의 해당 메모 열기
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
                        views.setOnClickPendingIntent(containerId, openPendingIntent)

                        // 체크박스 클릭 시 (백그라운드에서 상태 토글)
                        val toggleIntent = es.antonborri.home_widget.HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            android.net.Uri.parse("myAppWidget://toggleCompletion/$todoId")
                        )
                        views.setOnClickPendingIntent(checkId, toggleIntent)
                        
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
