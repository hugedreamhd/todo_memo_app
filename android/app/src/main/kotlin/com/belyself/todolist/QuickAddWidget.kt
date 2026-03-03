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

            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE,
            )
            
            // 메모 개수 및 목록 읽기
            val count = prefs.getLong("flutter.todo_active_count", -1L)

            if (count > 0) {
                views.setViewVisibility(R.id.widget_todo_empty, View.GONE)

                // 최대 3개 아이템 표시 처리
                val itemIds = intArrayOf(R.id.todo_item_0, R.id.todo_item_1, R.id.todo_item_2)
                for (i in 0..2) {
                    val title = prefs.getString("flutter.todo_item_$i", null)
                    val todoId = prefs.getString("flutter.todo_item_${i}_id", null)
                    if (title != null) {
                        views.setViewVisibility(itemIds[i], View.VISIBLE)
                        views.setTextViewText(itemIds[i], "• $title")

                        if (todoId != null) {
                            val intent = Intent(context, MainActivity::class.java).apply {
                                action = ACTION_OPEN_TODO
                                putExtra(EXTRA_TODO_ID, todoId)
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            }
                            val pendingIntent = PendingIntent.getActivity(
                                context,
                                appWidgetId * 10 + i,
                                intent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                            )
                            views.setOnClickPendingIntent(itemIds[i], pendingIntent)
                        }
                    } else {
                        views.setViewVisibility(itemIds[i], View.GONE)
                    }
                }
            } else {
                // 메모가 없거나 로드 전일 때
                views.setViewVisibility(R.id.widget_todo_empty, View.VISIBLE)
                views.setViewVisibility(R.id.todo_item_0, View.GONE)
                views.setViewVisibility(R.id.todo_item_1, View.GONE)
                views.setViewVisibility(R.id.todo_item_2, View.GONE)
                
                if (count == -1L) {
                    views.setTextViewText(R.id.widget_todo_empty, "앱을 열어 메모를 관리하세요")
                } else {
                    views.setTextViewText(R.id.widget_todo_empty, "바로메모를 시작해보세요 ✨")
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
