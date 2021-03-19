#import <Flutter/Flutter.h>

@interface HermezPlugin : NSObject<FlutterPlugin>
@end
// NOTE: Append the lines below to ios/Classes/<your>Plugin.h

char *pack_signature(const char *signature);

char *unpack_signature(const char *compressed_signature);

char *pack_point(const char *point_x, const char *point_y);

char *unpack_point(const char *compressed_point);

char *prv2pub(const uint8_t (*private_key)[32]);

char *hash_poseidon(const char *tx_compressed_data,
                    const char *to_eth_addr,
                    const char *to_bjj_ay,
                    const char *rq_txcompressed_data_v2,
                    const char *rq_to_eth_addr,
                    const char *rq_to_bjj_ay);

char *sign_poseidon(const uint8_t (*private_key)[32], const char *msg);

char *verify_poseidon(const char *private_key,
                      const char *compressed_signature,
                      const char *message);