
#ifndef XCoreCoder_h
#define XCoreCoder_h

#include <stdlib.h>
#include <stdbool.h>

#define XCTypeLength 1

extern char * _Nonnull const XCoderErrorDomain;

typedef enum {
        
    XCTypeNil = 0x0,

    /// Type - Value
    XCTypeBool = 0x1,
    
    // 为了保证编码的一致性，编码成 varint(e) + (sign + 尾数)， sign+尾数的尾部的0省略
    XCTypeNumber = 0x2,
    
    XCTypeTimeval = 0x3,
    
    /// Type - Count - Value
    XCTypeString = 0x4,

    /// Type - Count - Value
    XCTypeData = 0x5,

    /// Type - Count - Value[(offst, Item)]
    XCTypeMessage = 0x6,

    /// Type - Count - Value[Item]
    XCTypeArray = 0x7,

    /// Type - Count - Value[Item]
    /// 为了确保hash的一致性，map必须是有序的
    XCTypeOrderedMap = 0x8,

    /// 为了确保hash的一致性，set必须是有序的
    XCTypeOrderedSet = 0x9,
    
    // 最大值23
} XCType_e;

typedef enum {
    XCErrorNone = 0,
    
    XCErrorContent = -1,
    XCErrorCount = -2,
    XCErrorNotEnough = -3,
    XCErrorNotSupport = -4,
    
    /// 编码压缩错误 编码错误，高位为0， 占用了更多的字节， 这种不允许;
    XCErrorVarInt = -0x5,
        
    /// 非法编码
    XCErrorType = -0x6,
    XCErrorLayout = -0x7,

    XCErrorMessageFieldKeyOffset = -0x8,
    XCErrorNumberOutOfBounds = -0x9,
    
    /// 非法编码， type 后的4位非0
    XCErrorNilContent = -0x10,
    
    /// 非法编码， type 后的4位 只能是0或者1
    XCErrorBoolContent = -0x11,
    XCErrorTimevalContent = -0x12,
    XCErrorNumberContent = -0x13,
    XCErrorMessageIndexOffset = -0x14,
    XCErrorStringContent = -0x15,
    XCErrorArrayContent = -0x16,
    XCErrorMessageContent = -0x17,
    XCErrorMapContent = -0x18,
    XCErrorSetContent = -0x19,
} XCError_e;

/// 取值范围最大63
typedef enum {
    XCNumberTypeNone = 0x0,
    XCNumberTypeSInt,
    XCNumberTypeUInt,
    XCNumberTypeFloat64,
} XCNumberType_e;

typedef enum {
    XCNumberLayoutZero = 0x0,
    XCNumberLayoutNan = 0x1,
    XCNumberLayoutPositiveInfinity = 0x2,
    XCNumberLayoutNegativeInfinity = 0x3,
    
    // unused
    XCNumberLayoutLarge = 0x4,

    // other:  len = layout - XCNumberLayoutLarge
} XCNumberLayout_e;

typedef struct {
    ssize_t type;
    union {
        int64_t s;
        uint64_t u;
        double f;
    } value;
} XCNumberValue_s;

typedef struct {
    int64_t type;
    ssize_t count;
} XCMessageHeader_s;

static inline XCMessageHeader_s XCMessageHeaderMake(uint64_t type, ssize_t count) {
    XCMessageHeader_s result = {
        .type = type,
        .count = count,
    };
    return result;
}

///
typedef struct {
    int64_t exponent;
    uint64_t signAndSignificand;
} XCNumberNormalContent_s;


typedef struct {
    ssize_t type;
    union {
        _Bool boolValue;
        XCMessageHeader_s message;
        XCNumberValue_s number;
        int64_t timeval;
        
        // XCTypeData, XCTypeString, XCTypeOrderedMap, XCTypeOrderedSet, XCTypeArray
        ssize_t count;
    } value;
} XCValueHeader_s;

static inline XCValueHeader_s XCValueHeaderMake(void) {
    XCValueHeader_s h = { 0 };
    return h;
}

typedef enum {
    XCTimevalLayoutDistantPast = 0x0,
    XCTimevalLayoutDistantFuture = 0x1,
    
    // 0 字节  为0
    XCTimevalLayoutZeroByteCount = 0x2,
    
} XCTimevalLayout_e;

extern ssize_t XCHeaderMaxLength(void);



extern XCError_e XCDecodeHeader(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCValueHeader_s * _Nonnull header);
extern XCError_e XCDecodeFieldKeyOffset(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t * _Nonnull offset);



extern XCError_e XCEncodeNil(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location);

extern XCError_e XCEncodeBool(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, _Bool value);

extern XCError_e XCEncodeNumberUInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value);
extern XCError_e XCEncodeNumberSInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value);
extern XCError_e XCEncodeNumberDouble(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, double value);

extern XCError_e XCEncodeTimeval(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value);

extern XCError_e XCEncodeFieldKeyOffset(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t offset);

/// type >= 0
extern XCError_e XCEncodeMessageHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count, int64_t type);

extern XCError_e XCEncodeArrayHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XCError_e XCEncodeOrderedMapHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XCError_e XCEncodeOrderedSetHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XCError_e XCEncodeDataHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);

extern XCError_e XCEncodeStringHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count);


extern XCError_e XCEncodeBody(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, const void * _Nonnull data, ssize_t count);


typedef XCError_e (*XCVarintEncode_f)(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value);
typedef XCError_e (*XCVarintDecode_f)(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t * _Nonnull value);

#endif /* XCoreCoder_h */
