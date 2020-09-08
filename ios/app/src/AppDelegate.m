/*
 * Copyright @ 2018-present 8x8, Inc.
 * Copyright @ 2017-2018 Atlassian Pty Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AppDelegate.h"
#import "FIRUtilities.h"
#import "Types.h"
#import "ViewController.h"

@import Crashlytics;
@import Fabric;
@import Firebase;
@import JitsiMeet;

@implementation AppDelegate

-             (BOOL)application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    JitsiMeet *jitsiMeet = [JitsiMeet sharedInstance];

    jitsiMeet.conferenceActivityType = JitsiMeetConferenceActivityType;
    jitsiMeet.customUrlScheme = @"org.jitsi.meet";
    jitsiMeet.universalLinkDomains = @[@"meet.jit.si", @"alpha.jitsi.net", @"beta.meet.jit.si"];

    jitsiMeet.defaultConferenceOptions = [JitsiMeetConferenceOptions fromBuilder:^(JitsiMeetConferenceOptionsBuilder *builder) {
        [builder setFeatureFlag:@"resolution" withValue:@(360)];
//      https://vb1-kt-kzo.bilimland.kz:8443/125ab28b-d223-412b-bfc8-b99d7a8dee31?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjb250ZXh0Ijp7InVzZXIiOnsiYXZhdGFyIjoiaHR0cHM6XC9cL3Jtcy5iaWxpbWxhbmQua3pcL3VwbG9hZFwvcHJvZmlsZS02MTcyNDEyXC8xNTk4OTYzNTY0LmpwZWciLCJuYW1lIjoiU21hcnRuYXRpb24gXHUwNDE3XHUwNDMwXHUwNDMyXHUwNDQzXHUwNDQ3IiwiaWQiOjYxNzI0MTJ9fSwiYXVkIjoiaml0c2kiLCJpc3MiOiJvbmxpbmVtZWt0ZXBfaml0c2lfYXBwX2lkIiwic3ViIjoiaHR0cHM6XC9cL29ubGluZW1la3RlcC5vcmciLCJyb29tIjoiMTI1YWIyOGItZDIyMy00MTJiLWJmYzgtYjk5ZDdhOGRlZTMxIiwibW9kZXJhdG9yIjp0cnVlfQ.sn27dBLIlRQmUv_SJtphUgJolW1LSuqnVvHoj5_8Rbk
        builder.serverURL = [NSURL URLWithString:@"vb1-kt-kzo.bilimland.kz:8443"];
      builder.room = @"125ab28b-d223-412b-bfc8-b99d7a8dee31";
      builder.token = @"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjb250ZXh0Ijp7InVzZXIiOnsiYXZhdGFyIjoiaHR0cHM6XC9cL3Jtcy5iaWxpbWxhbmQua3pcL3VwbG9hZFwvcHJvZmlsZS02MTcyNDEyXC8xNTk4OTYzNTY0LmpwZWciLCJuYW1lIjoiU21hcnRuYXRpb24gXHUwNDE3XHUwNDMwXHUwNDMyXHUwNDQzXHUwNDQ3IiwiaWQiOjYxNzI0MTJ9fSwiYXVkIjoiaml0c2kiLCJpc3MiOiJvbmxpbmVtZWt0ZXBfaml0c2lfYXBwX2lkIiwic3ViIjoiaHR0cHM6XC9cL29ubGluZW1la3RlcC5vcmciLCJyb29tIjoiMTI1YWIyOGItZDIyMy00MTJiLWJmYzgtYjk5ZDdhOGRlZTMxIiwibW9kZXJhdG9yIjp0cnVlfQ.sn27dBLIlRQmUv_SJtphUgJolW1LSuqnVvHoj5_8Rbk";
        builder.welcomePageEnabled = YES;
      builder.currentLocale = @"kk";
        // Apple rejected our app because they claim requiring a
        // Dropbox account for recording is not acceptable.
#if DEBUG
        [builder setFeatureFlag:@"ios.recording.enabled" withBoolean:YES];
#endif
    }];

    // Initialize Crashlytics and Firebase if a valid GoogleService-Info.plist file was provided.
    if ([FIRUtilities appContainsRealServiceInfoPlist] && ![jitsiMeet isCrashReportingDisabled]) {
        NSLog(@"Enabling Crashlytics and Firebase");
        [FIRApp configure];
        [Fabric with:@[[Crashlytics class]]];
    }

    [jitsiMeet application:application didFinishLaunchingWithOptions:launchOptions];

    return YES;
}

- (void) applicationWillTerminate:(UIApplication *)application {
    NSLog(@"Application will terminate!");
    // Try to leave the current meeting graceefully.
    ViewController *rootController = (ViewController *)self.window.rootViewController;
    [rootController terminate];
}

#pragma mark Linking delegate methods

-    (BOOL)application:(UIApplication *)application
  continueUserActivity:(NSUserActivity *)userActivity
    restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {

    if ([FIRUtilities appContainsRealServiceInfoPlist]) {
        // 1. Attempt to handle Universal Links through Firebase in order to support
        //    its Dynamic Links (which we utilize for the purposes of deferred deep
        //    linking).
        BOOL handled
          = [[FIRDynamicLinks dynamicLinks]
                handleUniversalLink:userActivity.webpageURL
                         completion:^(FIRDynamicLink * _Nullable dynamicLink, NSError * _Nullable error) {
           NSURL *firebaseUrl = [FIRUtilities extractURL:dynamicLink];
           if (firebaseUrl != nil) {
             userActivity.webpageURL = firebaseUrl;
             [[JitsiMeet sharedInstance] application:application
                                continueUserActivity:userActivity
                                  restorationHandler:restorationHandler];
           }
        }];

        if (handled) {
          return handled;
        }
    }

    // 2. Default to plain old, non-Firebase-assisted Universal Links.
    return [[JitsiMeet sharedInstance] application:application
                              continueUserActivity:userActivity
                                restorationHandler:restorationHandler];
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    // This shows up during a reload in development, skip it.
    // https://github.com/firebase/firebase-ios-sdk/issues/233
    if ([[url absoluteString] containsString:@"google/link/?dismiss=1&is_weak_match=1"]) {
        return NO;
    }

    NSURL *openUrl = url;

    if ([FIRUtilities appContainsRealServiceInfoPlist]) {
        // Process Firebase Dynamic Links
        FIRDynamicLink *dynamicLink = [[FIRDynamicLinks dynamicLinks] dynamicLinkFromCustomSchemeURL:url];
        NSURL *firebaseUrl = [FIRUtilities extractURL:dynamicLink];
        if (firebaseUrl != nil) {
            openUrl = firebaseUrl;
        }
    }

    return [[JitsiMeet sharedInstance] application:app
                                           openURL:openUrl
                                           options:options];
}

@end
