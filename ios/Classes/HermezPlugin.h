#import <Flutter/Flutter.h>

@interface HermezPlugin : NSObject<FlutterPlugin>
@end
// NOTE: Append the lines below to ios/Classes/<your>Plugin.h

typedef struct Result_Point__String Result_Point__String;

typedef struct Result_Signature__String Result_Signature__String;

Result_Signature__String decompress_signature(const uint8_t (*b)[64]);

Result_Point__String prv2pub(BigInt key);