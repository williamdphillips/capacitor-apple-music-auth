#import <Capacitor/Capacitor.h>

CAP_PLUGIN(AppleMusicAuthPlugin, "AppleMusicAuth",
           CAP_PLUGIN_METHOD(requestAuthorization, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getAuthorizationStatus, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(hasSubscription, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(playSong, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getCurrentTime, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getDuration, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(pause, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(play, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(stop, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(seek, CAPPluginReturnPromise);
)
