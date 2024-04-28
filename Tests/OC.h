//
//  OC.h
//  Tests
//
//  Created by vector on 2024/4/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSONCoder : NSObject

+ (NSData *)encode: (id) any;
+ (id)decode: (NSData *) data;

@end

NS_ASSUME_NONNULL_END
