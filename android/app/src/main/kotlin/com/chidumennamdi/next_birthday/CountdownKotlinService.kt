package com.chidumennamdi.next_birthday

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Timer
import java.util.TimerTask

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

//import android.app.Service
//import android.content.Intent
//import android.os.IBinder
//import io.flutter.plugin.common.MethodChannel
//import io.flutter.plugin.common.MethodChannel.MethodCallHandler
//import io.flutter.plugin.common.MethodCall
//import io.flutter.plugin.common.MethodChannel.Result
import android.os.Handler
import android.os.Looper

class CountdownKotlinService : Service() {
    private var eventSink: EventChannel.EventSink? = null
    private var timer: Timer? = null
    private val CHANNEL_ID = "BirthdayChannel"
    private val PREF_NAME = "com.chidumennamdi.next_birthday"
    private val KEY_BIRTHDAY = "_birthday"

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
        val CHANNEL_NAME = "com.example/start_countdown"
        println("initializeMethodChannel")

        methodChannel = MethodChannel(messenger, CHANNEL_NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCountdown" -> {
                        val data = call.arguments as String;
                        println(data)
                        startCountdown(data)
                        result.success(null)
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
        eventChannel = EventChannel(messenger, "com.example/stream_channel").apply {
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
//        eventSink?.success(message)
        mainHandler.post {
            eventSink?.success(message)
        }
    }

    private fun startCountdown(date: String?) {
        timer = Timer()
        timer!!.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
//                val countdownMillis = calculateNextBirthdayCountdown(this@CountdownKotlinService)
//                showNotification(countdownMillis)

                val countdownMillis = calculateNextBirthdayCountdown(date)
                sendEventToFlutter(countdownMillis.toString())

            }
        }, 0, 1000) // Run every second

    }

    private fun showNotification(countdownMillis: Long) {
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

        // Format the countdown into days, hours, minutes, and seconds
        val formatter = SimpleDateFormat("dd:HH:mm:ss")
        val formattedCountdown = formatter.format(Date(countdownMillis))

        // Build the notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Birthday Countdown")
            .setContentText("Next birthday in: $formattedCountdown")
            .setSmallIcon(R.drawable.launch_background)
            .setContentIntent(pendingIntent)
            .build()

        // Show the notification
        notificationManager.notify(1, notification)
    }

    private fun calculateNextBirthdayCountdown(date: String?): Long {
        println(date);

//        val sharedPreferences: SharedPreferences =
//            context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

        // Retrieve the birthday in milliseconds from SharedPreferences
        val birthdayMillis = convertDateStringToMillis(date)//sharedPreferences.getLong(KEY_BIRTHDAY, 0)

//        println(sharedPreferences.getString(KEY_BIRTHDAY, KEY_BIRTHDAY));

        // If the birthday is not set, return a large value indicating no countdown
        if (birthdayMillis == 0L) {
            return Long.MAX_VALUE
        }

        val currentTimeMillis = System.currentTimeMillis()

        // Calculate the time until the next birthday
        return calculateTimeUntilNextBirthday(currentTimeMillis, birthdayMillis)
    }

    private fun calculateTimeUntilNextBirthday(currentTimeMillis: Long, birthdayMillis: Long): Long {
        val currentCalendar = Calendar.getInstance().apply {
            timeInMillis = currentTimeMillis
        }

        val birthdayCalendar = Calendar.getInstance().apply {
            timeInMillis = birthdayMillis
        }

        // Set the year of the birthday calendar to the current year
        birthdayCalendar.set(Calendar.YEAR, currentCalendar.get(Calendar.YEAR))

        // If the birthday has already occurred this year, set it to the next year
        if (currentCalendar.after(birthdayCalendar)) {
            birthdayCalendar.add(Calendar.YEAR, 1)
        }

        // Calculate the time until the next birthday
        return birthdayCalendar.timeInMillis - currentTimeMillis
    }

    private fun convertDateStringToMillis(dateString: String?): Long {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd")
        val date = dateFormat.parse(dateString)
        return date?.time ?: 0L
    }

    override fun onDestroy() {
        super.onDestroy()
        timer?.cancel()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }
}