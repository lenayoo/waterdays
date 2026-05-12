package com.example.waterdays

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingLaunchAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        captureLaunchAction()
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureLaunchAction()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "waterdays/widget",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWaterProgress" -> {
                    val args = call.arguments as? Map<*, *>
                    val drankCups = (args?.get("drankCups") as? Number)?.toInt()
                    val goalCups = (args?.get("goalCups") as? Number)?.toInt()
                    val currentDateKey = args?.get("currentDateKey") as? String

                    if (drankCups == null || goalCups == null || currentDateKey == null) {
                        result.error(
                            "INVALID_ARGS",
                            "Widget progress data is missing.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    applicationContext
                        .getSharedPreferences(
                            WaterdaysWidgetStore.prefsName,
                            MODE_PRIVATE,
                        )
                        .edit()
                        .putInt(WaterdaysWidgetStore.drankKey, drankCups)
                        .putInt(WaterdaysWidgetStore.goalKey, goalCups)
                        .putString(WaterdaysWidgetStore.currentDateKey, currentDateKey)
                        .apply()

                    WaterdaysWidgetProvider.updateAllWidgets(applicationContext)
                    WaterdaysWidgetProvider.scheduleMidnightRefresh(applicationContext)
                    result.success(null)
                }

                "consumeLaunchAction" -> {
                    result.success(pendingLaunchAction)
                    pendingLaunchAction = null
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun captureLaunchAction() {
        pendingLaunchAction =
            intent?.getStringExtra(WaterdaysWidgetProvider.EXTRA_LAUNCH_ACTION)
    }
}
