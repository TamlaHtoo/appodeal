import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'consent.dart';

class Appodeal {
  static String _androidAppKey;
  static String _iosAppKey;

  static Function(String) _bannerCallback;
  static Function(String) _interstitialCallback;
  static Function(String) _rewardCallback;
  static Function(String) _nonSkippableCallback;

  static const MethodChannel _channel = const MethodChannel('appodeal_flutter');

  /// Request the user authorization to track him across multiple apps and websites in order to deliver more relevant
  /// ads. This command must be called before the initialization of the Appodeal plugin.
  ///
  /// This authorization request is only relevant for iOS 14+. In older versions of iOS and on Android devices this
  /// function nothing. It simply returns `true` as if the authorization had already been granted.
  ///
  /// On devices with iOS 14+ it returns `true` or `false` depending whether the user granted access or not.
  static Future<bool> requestIOSTrackingAuthorization() async {
    return Platform.isIOS ?
      await _channel.invokeMethod('requestIOSTrackingAuthorization') :
      true;
  }

  // region - Appodeal
  /// Define the Appodeal app keys for Android and iOS. At least one of the keys must be set, otherwise an error will be
  /// throw during the initialization.
  static void setAppKeys({String androidAppKey, String iosAppKey}) {
    _androidAppKey = androidAppKey;
    _iosAppKey = iosAppKey;
  }

  /// Initialize the Appodeal plugin.
  ///
  /// During the initialization you must define the type of ads [adTypes] that you would like to display in your app and
  /// also if ads should be presented in test mode [testMode] or not. Always set test mode as `true` during development
  /// or tests.
  static Future<void> initialize({@required bool hasConsent, List<int> adTypes = const [], bool testMode = false}) async {
    assert(_androidAppKey != null || _iosAppKey != null, 'You must set at least one of the keys for Android or iOS');

    // Register the callbacks
    _setCallbacks();

    return _channel.invokeMethod('initialize', {
      'androidAppKey': _androidAppKey,
      'iosAppKey': _iosAppKey,
      'hasConsent': hasConsent,
      'adTypes': adTypes,
      'testMode': testMode
    });
  }

  /// Check if an ad of certain type [adType] is loaded and ready to be presented.
  ///
  /// Use the constants in the class `AdType` to specify what ad should be loaded.
  ///
  /// Returns `true` if the ad is loaded.
  static Future<bool> isLoaded(int adType) async {
    return _channel.invokeMethod('isLoaded', {
      'adType': adType
    });
  }

  /// Shows an ad of certain type [adType].
  ///
  /// Use the constants in the class `AdType` to specify what ad should be shown.
  ///
  /// Returns `true` if the ad is shown.
  static Future<bool> show(int adType) async {
    return _channel.invokeMethod('show', {
      'adType': adType
    });
  }
  // endregion

  // region - Callbacks
  static void _setCallbacks() {
    _channel.setMethodCallHandler((call) {
      if (call.method.startsWith('onBanner')) {
        _bannerCallback?.call(call.method);
      } else if (call.method.startsWith('onInterstitial')) {
        _interstitialCallback?.call(call.method);
      } else if (call.method.startsWith('onRewarded')) {
        _rewardCallback?.call(call.method);
      } else if (call.method.startsWith('onRewarded')) {
        _nonSkippableCallback?.call(call.method);
      }

      return null;
    });
  }

  /// Define a callback to track banner ad events.
  ///
  /// It receives a function [callback] with parameter `event` of type `String.
  static void setBannerCallback(Function(String event) callback) {
    _bannerCallback = callback;
  }

  /// Define a callback to track interstitial ad events.
  ///
  /// It receives a function [callback] with parameter `event` of type `String.
  static void setInterstitialCallback(Function(String event) callback) {
    _interstitialCallback = callback;
  }

  /// Define a callback to track reward ad events.
  ///
  /// It receives a function [callback] with parameter `event` of type `String.
  static void setRewardCallback(Function(String event) callback) {
    _rewardCallback = callback;
  }

  /// Define a callback to track non-skippable ad events.
  ///
  /// It receives a function [callback] with parameter `event` of type `String.
  static void setNonSkippableCallback(Function(String event) callback) {
    _nonSkippableCallback = callback;
  }
  // endregion

  // region - Consent Manager
  /// Fetches the user consent status, respecting the GDPR and CCPA laws, about tracking individuals across multiple
  /// sites and apps. This command must be called before the initialization of the Appodeal plugin.
  ///
  /// Returns an object of type `Consent` where you can check the user status, in what zone, if any, that consent
  /// applies.
  static Future<Consent> fetchConsentInfo() async {
    assert(_androidAppKey != null || _iosAppKey != null, 'You must set at least one of the keys for Android or iOS');

    var consentMap = await _channel.invokeMethod('fetchConsentInfo', {
      'androidAppKey': _androidAppKey,
      'iosAppKey': _iosAppKey
    });

    return Consent(consentMap);
  }

  /// Checks if the app needs to request the user consent to track him online.
  ///
  /// Depending on the current user location he might not be protected by privacy laws, so in this cases it's not
  /// necessary to request consent to track him online.
  ///
  /// Returns `true` if the app must request consent. This function will return `false` when the user is not protected
  /// by any privacy laws, but also when the user previously granted or declined permission to be tracked.
  static Future<bool> shouldShowConsent() async {
    assert(_androidAppKey != null || _iosAppKey != null, 'You must set at least one of the keys for Android or iOS');

    await fetchConsentInfo();
    return await _channel.invokeMethod('shouldShowConsent', {
      'androidAppKey': _androidAppKey,
      'iosAppKey': _iosAppKey
    });
  }

  /// Displays a dialog window where the user can grant or deny access to be tracked across multiple sites and devices,
  /// according to GDPR or CCPA laws.
  static Future<void> requestConsentAuthorization() async {
    await fetchConsentInfo();
    return _channel.invokeMethod('requestConsentAuthorization');
  }
  // endregion
}