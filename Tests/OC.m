//
//  OC.m
//  Tests
//
//  Created by vector on 2024/4/26.
//

#import "OC.h"

@implementation JSONCoder

+ (NSData *)encode: (id) any {
    return [NSJSONSerialization dataWithJSONObject:any options:NSJSONWritingFragmentsAllowed error:NULL];
}
+ (id)decode: (NSData *) data {
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
}

@end
