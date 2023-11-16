package com.chidumennamdi.next_birthday

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.icu.text.CaseMap.Title
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Timer
import java.util.TimerTask

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

import android.os.Handler
import android.os.Looper
import java.util.Locale

class CountdownKotlinService : Service() {
    private var eventSink: EventChannel.EventSink? = null
    private var timer: Timer? = null
    private val CHANNEL_ID = "BirthdayChannel"

    private var eventChannel: EventChannel? = null
    private var methodChannel: MethodChannel? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        println("onStartCommand")

        // This assumes that MainActivity.sharedFlutterEngine is properly initialized
        MainActivity.sharedFlutterEngine?.let { engine ->
            initializeEventChannel(engine.dartExecutor.binaryMessenger)
            initializeMethodChannel(engine.dartExecutor.binaryMessenger)
        } ?: println("Error: sharedFlutterEngine not initialized")

        println("Kotlin: initializing EventChannel")
        return START_STICKY
    }

    private fun initializeMethodChannel(messenger: BinaryMessenger) {
        val CHANNEL_NAME = "com.chidumennamdi/countdown"
        println("initializeMethodChannel")

        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCountdown" -> {
                        val data = call.arguments as String;
                        startCountdown(data)
                        result.success(null)
                    }
                    "stopCountdown" -> {
                        stopCountdown()
                        showNotification("", "Countdown stopped")
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    private fun initializeEventChannel(messenger: BinaryMessenger) {
        println("initializeEventChannel")
        // Set up EventChannel
        eventChannel = EventChannel(messenger, "com.chidumennamdi/stream_channel").apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        }
    }

    private fun sendEventToFlutter(message: String) {
        mainHandler.post {
            eventSink?.success(message)
        }
    }

    private fun startCountdown(date: String) {
        showCountDownNotif(calculateNextBirthdayCountdown(date));

        timer = Timer()
        timer!!.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {

                val countdownMillis = calculateNextBirthdayCountdown(date)

                if (countdownMillis <= 0) {
                    println("Birthday countdown is done!")
                    showCountDownDoneNotif()
                    // You can perform any actions or trigger events when the countdown is done
                }

                sendEventToFlutter(countdownMillis.toString())

            }
        }, 0, 1000) // Run every second

    }

    private fun showCountDownNotif(countdownMillis: Long) {
        // Format the countdown into days, hours, minutes, and seconds
        val formatter = SimpleDateFormat("dd:HH:mm:ss")
        val formattedCountdown = formatter.format(Date(countdownMillis))
        showNotification("Birthday Countdown", "Next birthday in: $formattedCountdown")
    }

    private fun showCountDownDoneNotif() {
        showNotification("Birthday Countdown","Birthday countdown is done!")
    }

    private fun showNotification(title: String, body: String) {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create a notification channel (required for API level 26 and above)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Birthday Countdown",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }

        // Create an intent for the notification
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT
        )


        // Build the notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.launch_background)
            .setContentIntent(pendingIntent)
            .build()

        // Show the notification
        notificationManager.notify(1, notification)
    }

    private fun calculateNextBirthdayCountdown(date: String): Long {
        println(date);

        // Calculate the time until the next birthday
        return calculateTimeUntilNextBirthday(date)
    }

    private fun calculateTimeUntilNextBirthday(birthdayDate: String): Long {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val today = Calendar.getInstance()
        val birthday = Calendar.getInstance()

        val currentYear = today.get(Calendar.YEAR)

        // Set the birthday date to the current year
        birthday.time = dateFormat.parse("$birthdayDate/$currentYear")!!

        // If the birthday has already passed this year, set it to the next year
        if (today.after(birthday)) {
            birthday.set(Calendar.YEAR, currentYear + 1)
        }

        // Calculate the time until the next birthday
        return birthday.timeInMillis - today.timeInMillis
    }

    private fun stopCountdown() {
        timer?.cancel();
    }

    override fun onDestroy() {
        super.onDestroy()
        timer?.cancel()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }
}