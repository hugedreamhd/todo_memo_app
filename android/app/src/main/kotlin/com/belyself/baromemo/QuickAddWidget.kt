package com.belyself.baromemo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import android.text.SpannableString

class QuickAddWidget : AppWidgetProvider() {

    data class WidgetMemoSlot(
        val todoId: String,
        val title: String,
        val isCompleted: Boolean,
        val isImportant: Boolean,
        val isHighlighted: Boolean,
    )

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
        const val ACTION_QUICK_ADD = "com.belyself.baromemo.QUICK_ADD"
        const val ACTION_OPEN_TODO = "com.belyself.baromemo.OPEN_TODO"
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
            val slots = readWidgetSlots(prefs)

            if (slots.isNotEmpty()) {
                bindWidgetSlots(context, views, appWidgetId, slots)
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

        private fun readWidgetSlots(prefs: SharedPreferences): List<WidgetMemoSlot> {
            return (0..2).mapNotNull { index ->
                val todoId = prefs.getString("widget_memo_${index}_id", null)
                val title = prefs.getString("widget_memo_${index}_title", null)

                if (todoId != null && title != null) {
                    WidgetMemoSlot(
                        todoId = todoId,
                        title = title,
                        isCompleted = prefs.getBoolean("widget_memo_${index}_completed", false),
                        isImportant = prefs.getBoolean("widget_memo_${index}_important", false),
                        isHighlighted = prefs.getBoolean("widget_memo_${index}_highlighted", false),
                    )
                } else {
                    null
                }
            }
        }

        private fun bindWidgetSlots(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
            slots: List<WidgetMemoSlot>,
        ) {
            views.setViewVisibility(R.id.widget_todo_empty, if (slots.isEmpty()) View.VISIBLE else View.GONE)
            if (slots.isEmpty()) {
                views.setTextViewText(
                    R.id.widget_todo_empty,
                    "위젯에 표시할 메모가 없어요 ✨\n앱에서 '위젯에 고정'을 눌러보세요.",
                )
            }

            for (i in 0..2) {
                val slot = slots.getOrNull(i)
                if (slot != null) {
                    bindTodoSlot(context, views, appWidgetId, i, slot)
                } else {
                    clearTodoSlot(context, views, i)
                }
            }
        }

        private fun bindTodoSlot(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
            index: Int,
            slot: WidgetMemoSlot,
        ) {
            val containerId = context.resources.getIdentifier("todo_container_$index", "id", context.packageName)
            val titleId = context.resources.getIdentifier("todo_title_$index", "id", context.packageName)
            val importantId = context.resources.getIdentifier("todo_important_$index", "id", context.packageName)
            val chevronId = context.resources.getIdentifier("todo_chevron_$index", "id", context.packageName)

            views.setViewVisibility(containerId, View.VISIBLE)

            val displayTitle = if (slot.isHighlighted) "★ ${slot.title}" else slot.title
            views.setTextViewText(titleId, SpannableString(displayTitle))
            views.setTextColor(
                titleId,
                if (slot.isCompleted) {
                    android.graphics.Color.parseColor("#8A96A3")
                } else if (slot.isHighlighted) {
                    android.graphics.Color.parseColor("#FFD700")
                } else {
                    android.graphics.Color.parseColor("#FFFFFF")
                },
            )
            views.setViewVisibility(importantId, if (slot.isImportant) View.VISIBLE else View.GONE)

            val openIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN_TODO
                putExtra(EXTRA_TODO_ID, slot.todoId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10 + index,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(containerId, openPendingIntent)
            views.setOnClickPendingIntent(titleId, openPendingIntent)
            views.setOnClickPendingIntent(chevronId, openPendingIntent)
        }

        private fun clearTodoSlot(
            context: Context,
            views: RemoteViews,
            index: Int,
        ) {
            val containerId = context.resources.getIdentifier("todo_container_$index", "id", context.packageName)
            val titleId = context.resources.getIdentifier("todo_title_$index", "id", context.packageName)
            val importantId = context.resources.getIdentifier("todo_important_$index", "id", context.packageName)

            views.setViewVisibility(containerId, View.GONE)
            views.setTextViewText(titleId, "")
            views.setViewVisibility(importantId, View.GONE)
        }
    }
}
