package com.chidumennamdi.next_birthday;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class CountdownJavaService extends Service {
    private final String CHANNEL_ID = "BirthdayChannel";

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startCountdown();
        return START_STICKY;
    }

    private void startCountdown() {
        String TAG = "bhgvhg";
        System.out.println("hi");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
