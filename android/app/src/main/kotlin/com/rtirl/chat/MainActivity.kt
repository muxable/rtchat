package com.rtirl.chat

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

  private var sharedData: String = ""

  // In-App Update channels
  private val updateMethodChannel = "com.rtirl.chat/in_app_updates"
  private val updateEventChannel = "com.rtirl.chat/in_app_updates/events"

  private lateinit var updateManager: AppUpdateManager

  private var updateEventSink: EventChannel.EventSink? = null
  private val pendingUpdateEvents = mutableListOf<Map<String, Any>>()

  private var updateManagerInitialized = false

  companion object {
    private const val UPDATE_REQUEST_CODE = 9001
    private const val MIN_STALENESS_DAYS = 21
  }

  // Listen for Google Play download status changes.
  private val installStateListener = InstallStateUpdatedListener { state ->
    when (state.installStatus()) {
      InstallStatus.DOWNLOADING -> {
        emitUpdateEvent(
            mapOf(
                "event" to "downloadProgress",
                "bytesDownloaded" to state.bytesDownloaded(),
                "totalBytesToDownload" to state.totalBytesToDownload(),
            )
        )
      }

      InstallStatus.DOWNLOADED -> {
        emitUpdateEvent(mapOf("event" to "updateDownloaded"))
      }
      InstallStatus.INSTALLED -> {
        emitUpdateEvent(mapOf("event" to "updateInstalled"))
      }
      InstallStatus.FAILED -> {
        emitUpdateEvent(
            mapOf(
                "event" to "updateFailed",
                "errorCode" to state.installErrorCode(),
            )
        )
      }

      InstallStatus.CANCELED -> {
        emitUpdateEvent(mapOf("event" to "updateCancelled"))
      }

      else -> {}
    }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    handleIntent()
  }

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val ttsServiceChannel =
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rtirl.chat/tts_service",
        )
    TtsService.channel = ttsServiceChannel
    ttsServiceChannel.setMethodCallHandler { call, result ->
      when (call.method) {
        "start" -> {
          TtsService.start(
              this,
              call.argument<String>("title") ?: "",
              call.argument<String>("text") ?: "",
              call.argument<String>("turnOff") ?: "",
          )
          result.success(true)
        }
        "stop" -> {
          TtsService.stop(this)
          result.success(true)
        }
        "isRunning" -> result.success(TtsService.isRunning)
        else -> result.notImplemented()
      }
    }

    MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rtirl.chat/audio",
        )
        .setMethodCallHandler { call, result ->
          when (call.method) {
            "set" -> {
              val urls = call.argument<List<String>>("urls") ?: listOf()
              val intent = Intent(this, AudioService::class.java)
              intent.putStringArrayListExtra("urls", ArrayList(urls))
              intent.action = AudioService.ACTION_START_SERVICE
              try {
                // Clearing goes through the service too: stopService() could
                // land before a just-requested start promotes itself, which
                // crashes the app. The service stops itself once empty.
                ContextCompat.startForegroundService(this, intent)
                result.success(true)
              } catch (_: IllegalStateException) {
                // Android may refuse to start it from the background, in which
                // case no start is pending and stopping directly is safe.
                if (urls.isEmpty()) stopService(intent)
                result.success(urls.isEmpty())
              }
            }
            "reload" -> {
              val intent = Intent(this, AudioService::class.java)
              intent.action = AudioService.ACTION_RELOAD_SOURCES
              try {
                startService(intent)
                result.success(true)
              } catch (_: IllegalStateException) {
                // The service isn't running, so there's nothing to reload.
                result.success(false)
              }
            }
            "hasPermission" -> {
              result.success(
                  Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
              )
            }
            "requestPermission" -> {
              if (
                  Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)
              ) {
                startActivityForResult(
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName"),
                    ),
                    8675309,
                )
              }
              result.success(
                  Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
              )
            }
            else -> result.notImplemented()
          }
        }

    MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rtirl.chat/share",
        )
        .setMethodCallHandler { call, result ->
          if (call.method == "getSharedData") {
            result.success(sharedData)
            sharedData = ""
          } else {
            result.notImplemented()
          }
        }

    updateManager = AppUpdateManagerFactory.create(this)
    updateManagerInitialized = true
    updateManager.registerListener(installStateListener)
    // Event channel: Android -> Flutter
    EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            updateEventChannel,
        )
        .setStreamHandler(
            object : EventChannel.StreamHandler {
              override fun onListen(
                  arguments: Any?,
                  events: EventChannel.EventSink?,
              ) {
                updateEventSink = events
                // Deliver events that occurred before Flutter subscribed.
                val eventsToSend = pendingUpdateEvents.toList()
                pendingUpdateEvents.clear()
                eventsToSend.forEach { event ->
                  updateEventSink?.success(event)
                }
                // Recover an already downloaded update.
                checkDownloadedUpdate()
              }

              override fun onCancel(arguments: Any?) {
                updateEventSink = null
              }
            }
        )

    // Method channel: Flutter -> Android
    MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            updateMethodChannel,
        )
        .setMethodCallHandler { call, result ->
          when (call.method) {
            "checkForUpdate" -> {
              checkForUpdate(result)
            }
            "startFlexibleUpdate" -> {
              startFlexibleUpdate(result)
            }
            "completeUpdate" -> {
              completeUpdate(result)
            }
            "checkDownloadedUpdate" -> {
              checkDownloadedUpdate()
              result.success(true)
            }
            else -> result.notImplemented()
          }
        }
  }

  private fun checkForUpdate(result: MethodChannel.Result) {

    updateManager.appUpdateInfo
        .addOnSuccessListener { info ->
          val stalenessDays = info.clientVersionStalenessDays() ?: -1

          val eligible =
              info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                  stalenessDays >= MIN_STALENESS_DAYS &&
                  info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)

          result.success(
              mapOf(
                  "available" to eligible,
                  "stalenessDays" to stalenessDays,
                  "availableVersionCode" to info.availableVersionCode(),
                  "updatePriority" to info.updatePriority(),
              )
          )
        }
        .addOnFailureListener { error ->
          result.error(
              "UPDATE_CHECK_FAILED",
              error.message,
              null,
          )
        }
  }

  private fun startFlexibleUpdate(result: MethodChannel.Result) {
    // Fetch fresh AppUpdateInfo each time.
    updateManager.appUpdateInfo
        .addOnSuccessListener { info ->
          val eligible =
              info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                  info.clientVersionStalenessDays()?.let { it >= MIN_STALENESS_DAYS } == true &&
                  info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
          if (!eligible) {
            result.success(false)
            return@addOnSuccessListener
          }
          try {
            val started =
                updateManager.startUpdateFlowForResult(
                    info,
                    this,
                    AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
                    UPDATE_REQUEST_CODE,
                )

            result.success(started)
          } catch (error: Exception) {
            result.error(
                "UPDATE_START_FAILED",
                error.message,
                null,
            )
          } catch (error: Exception) {

            result.error(
                "UPDATE_START_FAILED",
                error.message,
                null,
            )
          }
        }
        .addOnFailureListener { error ->
          result.error(
              "UPDATE_START_FAILED",
              error.message,
              null,
          )
        }
  }

  private fun completeUpdate(result: MethodChannel.Result) {
    updateManager
        .completeUpdate()
        .addOnSuccessListener {
          result.success(true)
        }
        .addOnFailureListener { error ->
          result.error(
              "UPDATE_INSTALL_FAILED",
              error.message,
              null,
          )
        }
  }

  private fun checkDownloadedUpdate() {
    if (!updateManagerInitialized) return
    updateManager.appUpdateInfo.addOnSuccessListener { info ->
      if (info.installStatus() == InstallStatus.DOWNLOADED) {
        emitUpdateEvent(mapOf("event" to "updateDownloaded"))
      }
    }
  }

  private fun emitUpdateEvent(event: Map<String, Any>) {
    runOnUiThread {
      val sink = updateEventSink
      if (sink != null) {
        sink.success(event)
      } else {
        // Keep the most recent events until Flutter subscribes.
        pendingUpdateEvents.add(event)
      }
    }
  }

  override fun onResume() {
    super.onResume()

    if (updateManagerInitialized) {
      checkDownloadedUpdate()
    }
  }

  @Suppress("DEPRECATION")
  override fun onActivityResult(
      requestCode: Int,
      resultCode: Int,
      data: Intent?,
  ) {
    super.onActivityResult(requestCode, resultCode, data)

    if (requestCode == UPDATE_REQUEST_CODE) {

      when (resultCode) {
        Activity.RESULT_OK -> {
          emitUpdateEvent(mapOf("event" to "updateAccepted"))
        }
        Activity.RESULT_CANCELED -> {
          emitUpdateEvent(mapOf("event" to "updateCancelled"))
        }

        else -> {
          emitUpdateEvent(
              mapOf(
                  "event" to "updateFailed",
                  "resultCode" to resultCode,
              )
          )
        }
      }
    }
  }

  override fun onDestroy() {

    if (updateManagerInitialized) {
      updateManager.unregisterListener(installStateListener)
    }

    super.onDestroy()
  }

  private fun handleIntent() {
    // Handle the received text share intent
    if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
      intent.getStringExtra(Intent.EXTRA_TEXT)?.let { intentData ->
        sharedData = intentData
      }
    }
  }
}
