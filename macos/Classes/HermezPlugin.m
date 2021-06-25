#import "HermezPlugin.h"
#if __has_include(<hermez_sdk/hermez_sdk-Swift.h>)
#import <hermez_sdk/hermez_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "hermez_sdk-Swift.h"
#endif

@implementation HermezPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftHermezPlugin registerWithRegistrar:registrar];
}
@end
