#import <Flutter/Flutter.h>





@interface HermezPlugin : NSObject<FlutterPlugin>
@end

// NOTE: Append the lines below to ios/Classes/<your>Plugin.h

typedef struct Result_Signature__String Result_Signature__String;

Result_Signature__String decompress_signature(const uint8_t (*b)[64]);

char *rust_greeting(const char *to);

//void rust_cstr_free(char *s);