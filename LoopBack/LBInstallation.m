#import "LBInstallation.h"
#import <UICKeyChainStore.h>

@interface LBInstallation ()
@property (nonatomic, readwrite, copy) NSString *deviceType;
@property (nonatomic, readwrite, copy) NSString *timeZone;
@end

@implementation LBInstallation

+ (NSString *)deviceTokenWithData: (NSData *) token {
    // Convert device token from NSData to NSString
    const unsigned *tokenBytes = [token bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    return hexToken;
}

+ (void)registerDevice: (LBInstallation *) device
               success: (SLSuccessBlock) success
               failure: (SLFailureBlock) failure {
    // Save!
    [device saveWithSuccess:^{
        NSLog(@"LBInstallation: Successfully saved %@", device);
        success(device);
    } failure:^(NSError *error) {
        NSLog(@"LBInstallation: Failed to save %@ with %@", device, error);
        failure(error);
    }];
}

/**
 * Saves the desired Device model to the server with all values pulled from the UI.
 */
+ (void)registerDeviceWithAdapter: (LBRESTAdapter *) adapter
                      deviceToken: (NSData *) deviceToken
                   registrationId: (id) registrationId
                            appId: (NSString *) appId
                       appVersion: (NSString *) appVersion
                           userId: (NSString *) userId
                            badge: (NSNumber *) badge
                    subscriptions: (NSArray *) subscriptions
						   status: (NSString *) status
                          success: (SLSuccessBlock) success
                          failure: (SLFailureBlock) failure {
    
    NSString* hexToken = [LBInstallation deviceTokenWithData:deviceToken];
    
    LBInstallationRepository *repository = (LBInstallationRepository *) [adapter repositoryWithClass:[LBInstallationRepository class]];
    
    if(appVersion == nil) {
        appVersion = @"1.0.0";
    }
    
    // 3. From that repository, create a new LBInstallation.
    LBInstallation *model = nil;
    
    if(registrationId) {
        model = (LBInstallation *)[repository modelWithDictionary:@{@"id": registrationId}];
    } else {
        // The repository doesn't seem to accept nil as the value for id
        model = (LBInstallation *)[repository modelWithDictionary:@{}];
    }
    
	[model setId:[UICKeyChainStore stringForKey:@"loopback-installation-id"]?[UICKeyChainStore stringForKey:@"loopback-installation-id"]:nil];
    model.appId = appId;
    model.appVersion = appVersion;
    model.userId = userId;
    model.deviceType = @"ios";
    model.deviceToken = hexToken;
    model.status = [status isEqual:nil]?@"Active":status;
    model.badge = badge;
    model.subscriptions = subscriptions ? subscriptions : @[];
    model.timeZone = [[NSTimeZone defaultTimeZone] name];
    
    [LBInstallation registerDevice:model success:success failure:failure];
}


@end

@implementation LBInstallationRepository

+ (instancetype)repository {
    static LBInstallationRepository *singleton = nil;
    @synchronized(self) {
        if(singleton == nil) {
            singleton = [self repositoryWithClassName:@"installations"];
            singleton.modelClass = [LBInstallation class];
        }
    }
    return singleton;
}

@end

