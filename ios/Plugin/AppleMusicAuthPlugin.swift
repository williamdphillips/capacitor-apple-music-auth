import Capacitor
import Foundation
import MusicKit
import StoreKit

@objc(AppleMusicAuthPlugin)
public class AppleMusicAuthPlugin: CAPPlugin {

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            let developerToken = call.getString("developerToken")
            Task { @MainActor in
                do {
                    let status = await MusicAuthorization.request()
                    let authorized = status == .authorized
                    let statusString = statusToString(status)
                    if !authorized {
                        call.resolve([
                            "authorized": false,
                            "status": statusString
                        ])
                        return
                    }
                    if let devToken = developerToken, !devToken.isEmpty {
                        SKCloudServiceController().requestUserToken(forDeveloperToken: devToken) { [weak call] userToken, error in
                            DispatchQueue.main.async {
                                guard let call = call else { return }
                                var result: [String: Any] = [
                                    "authorized": true,
                                    "status": statusString
                                ]
                                if let token = userToken, !token.isEmpty {
                                    result["token"] = token
                                }
                                call.resolve(result)
                            }
                        }
                    } else {
                        call.resolve([
                            "authorized": true,
                            "status": statusString
                        ])
                    }
                } catch {
                    call.reject("Apple Music authorization failed: \(error.localizedDescription)", nil, error)
                }
            }
        } else {
            call.reject("Apple Music requires iOS 15 or later", nil, nil)
        }
    }

    @objc func getAuthorizationStatus(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            let status = MusicAuthorization.currentStatus
            call.resolve([
                "status": statusToString(status)
            ])
        } else {
            call.resolve(["status": "notDetermined"])
        }
    }

    @objc func hasSubscription(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            Task { @MainActor in
                do {
                    let value = try await MusicSubscription.current.canPlayCatalogContent
                    call.resolve(["value": value])
                } catch {
                    call.resolve(["value": false])
                }
            }
        } else {
            call.resolve(["value": false])
        }
    }

    @available(iOS 15.0, *)
    private func statusToString(_ status: MusicAuthorization.Status) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }
}
