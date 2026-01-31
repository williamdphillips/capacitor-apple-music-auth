package com.soundsstudios.applemusicauth;

import android.content.Intent;
import android.content.SharedPreferences;

import androidx.activity.result.ActivityResult;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;

import com.apple.android.sdk.authentication.AuthenticationFactory;
import com.apple.android.sdk.authentication.AuthenticationManager;
import com.apple.android.sdk.authentication.TokenResult;

@CapacitorPlugin(name = "AppleMusicAuth")
public class AppleMusicAuthPlugin extends Plugin {

    private static final String PREFS_NAME = "AppleMusicAuth";
    private static final String KEY_MUSIC_USER_TOKEN = "musicUserToken";

    private AuthenticationManager authenticationManager;
    private SharedPreferences getPrefs() {
        return getContext().getSharedPreferences(PREFS_NAME, 0);
    }

    private String getStoredToken() {
        return getPrefs().getString(KEY_MUSIC_USER_TOKEN, null);
    }

    private void setStoredToken(String token) {
        getPrefs().edit().putString(KEY_MUSIC_USER_TOKEN, token != null ? token : "").apply();
    }

    private void clearStoredToken() {
        getPrefs().edit().remove(KEY_MUSIC_USER_TOKEN).apply();
    }

    @PluginMethod
    public void requestAuthorization(PluginCall call) {
        String developerToken = call.getString("developerToken");
        if (developerToken == null || developerToken.isEmpty()) {
            JSObject ret = new JSObject();
            ret.put("authorized", false);
            ret.put("status", "unsupported");
            call.resolve(ret);
            return;
        }
        try {
            if (authenticationManager == null) {
                authenticationManager = AuthenticationFactory.createAuthenticationManager(getContext());
            }
            Intent intent = authenticationManager.createIntentBuilder(developerToken).build();
            startActivityForResult(call, intent, "onAppleMusicAuthResult");
        } catch (Exception e) {
            JSObject ret = new JSObject();
            ret.put("authorized", false);
            ret.put("status", "unknown");
            call.resolve(ret);
        }
    }

    @ActivityCallback
    private void onAppleMusicAuthResult(PluginCall call, ActivityResult result) {
        if (result.getResultCode() != android.app.Activity.RESULT_OK || result.getData() == null) {
            JSObject ret = new JSObject();
            ret.put("authorized", false);
            ret.put("status", "denied");
            call.resolve(ret);
            return;
        }
        try {
            TokenResult tokenResult = authenticationManager.handleTokenResult(result.getData());
            if (tokenResult.isError()) {
                String status = tokenResult.getError() != null ? tokenResult.getError().name().toLowerCase() : "denied";
                if (status.contains("_")) status = status.replace("_", "");
                clearStoredToken();
                JSObject ret = new JSObject();
                ret.put("authorized", false);
                ret.put("status", status);
                call.resolve(ret);
                return;
            }
            String musicUserToken = tokenResult.getMusicUserToken();
            if (musicUserToken != null && !musicUserToken.isEmpty()) {
                setStoredToken(musicUserToken);
            }
            JSObject ret = new JSObject();
            ret.put("authorized", true);
            ret.put("status", "authorized");
            ret.put("token", musicUserToken != null ? musicUserToken : getStoredToken());
            call.resolve(ret);
        } catch (Exception e) {
            JSObject ret = new JSObject();
            ret.put("authorized", false);
            ret.put("status", "unknown");
            call.resolve(ret);
        }
    }

    @PluginMethod
    public void getAuthorizationStatus(PluginCall call) {
        String token = getStoredToken();
        JSObject ret = new JSObject();
        ret.put("status", (token != null && !token.isEmpty()) ? "authorized" : "notDetermined");
        call.resolve(ret);
    }

    @PluginMethod
    public void hasSubscription(PluginCall call) {
        String token = getStoredToken();
        JSObject ret = new JSObject();
        ret.put("value", token != null && !token.isEmpty());
        call.resolve(ret);
    }
}
