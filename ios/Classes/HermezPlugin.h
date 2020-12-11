#import <Flutter/Flutter.h>

@interface HermezPlugin : NSObject<FlutterPlugin>
@end
// NOTE: Append the lines below to ios/Classes/<your>Plugin.h

uint8_t (pack_signature(const uint8_t (*signature)[64]))[64];

uint8_t (unpack_signature(const uint8_t (*compressed_signature)[64]))[64];

uint8_t (pack_point(const uint8_t (*point)[64]))[32];

uint8_t (unpack_point(const uint8_t (*point)[32]))[64];

uint8_t (prv2pub(const char *private_key))[32];

uint8_t (sign_poseidon(const char *private_key, const char *message))[64];

char verify_poseidon(const char *private_key, const uint8_t (*signature)[64], const char *message);