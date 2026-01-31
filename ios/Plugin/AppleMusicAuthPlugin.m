#import <Capacitor/Capacitor.h>

CAP_PLUGIN(AppleMusicAuthPlugin, "AppleMusicAuth",
    CAP_PLUGIN_METHOD(requestAuthorization, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getAuthorizationStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(hasSubscription, CAPPluginReturnPromise);
)
