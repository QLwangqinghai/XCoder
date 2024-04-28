
#include "XCoreCoder.h"
#include <stdio.h>
#include <math.h>
#include <strings.h>


char * _Nonnull const XCoderErrorDomain = "XCoder";

#ifndef XAssert
#define XAssert(cond, desc) {\
    if (!(cond)) {\
        fprintf(stderr, "[%s error] %s\n", __func__, desc);\
        abort();\
    }\
}
#endif

#if DEBUG

#ifndef XDebugAssert
#define XDebugAssert(cond, desc) {\
    if (!(cond)) {\
        fprintf(stderr, "[%s error] %s\n", __func__, desc);\
        abort();\
    }\
}
#endif

#else

#ifndef XDebugAssert
#define XDebugAssert(cond, desc)
#endif

#endif


/// 输入一定要是sint64 类型
static inline uint64_t XCSInt64ZigzagEncode(int64_t value) {
    uint64_t tmp = *((uint64_t *)&value);
    return (tmp << UINT64_C(1)) ^ (0 - (tmp >> UINT64_C(63)));
}
static inline int64_t XCSInt64ZigzagDecode(uint64_t data) {
    return (int64_t)((data >> UINT64_C(1)) ^ (0 - (data & UINT64_C(1))));
}

/// buffer.capacity >= 8
static inline ssize_t __XCEncodeTrimLeadingZeroByteIntToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    // 63-7=56
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)(value >> 56);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 48);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 40);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 32);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 24);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 16);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value >> 8);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)(value);
    if (used > 0 || 0 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    return used;
}

// 高位前导0的个数
static inline ssize_t XCUInt64LeadingZeroBitCount(uint64_t x) {
    if (0 == x) {
        return 64;
    }
    int32_t r = 0;
    if (0 == (x & UINT64_C(0xFFFFFFFF00000000))) {
        x <<= 32;
        r += 32;
    }
    if (0 == (x & UINT64_C(0xFFFF000000000000))) {
        x <<= 16;
        r += 16;
    }
    if (0 == (x & UINT64_C(0xFF00000000000000))) {
        x <<= 8;
        r += 8;
    }
    if (0 == (x & UINT64_C(0xF000000000000000))) {
        x <<= 4;
        r += 4;
    }
    if (0 == (x & UINT64_C(0xC000000000000000))) {
        x <<= 2;
        r += 2;
    }
    if (0 == (x & UINT64_C(0x8000000000000000))) {
        x <<= 1;
        r += 1;
    }
    return r;
}
static inline int32_t XCUInt64TrailingZeroBitCount(uint64_t x) {
    if (0 == x) {
        return 64;
    }
    int32_t r = 0;
    if (0 == (x & UINT64_C(0xFFFFFFFF))) {
        x >>= 32;
        r += 32;
    }
    if (0 == (x & UINT64_C(0xFFFF))) {
        x >>= 16;
        r += 16;
    }
    if (0 == (x & UINT64_C(0xFF))) {
        x >>= 8;
        r += 8;
    }
    if (0 == (x & UINT64_C(0xF))) {
        x >>= 4;
        r += 4;
    }
    if (0 == (x & UINT64_C(0x3))) {
        x >>= 2;
        r += 2;
    }
    if (0 == (x & UINT64_C(0x1))) {
        x >>= 1;
        r += 1;
    }
    return r;
}


static inline void XCDecodeTypeLayout(uint8_t byte, uint8_t * _Nonnull type, uint8_t * _Nonnull layout) {
    *layout = (byte & 0xF);
    *type = (XCType_e)(byte >> 4);
}

static inline void XCEncodeTypeLayout(uint8_t * _Nonnull byte, uint8_t type, uint8_t layout) {
    uint8_t v = (type << 4) | (layout & 0xf);
    *byte = v;
}

static inline double __XCDoubleNan(void) {
    uint64_t v = ((uint64_t)0x7ff8000000000000ULL);
    return *(double *)(&v);
}
static inline double __XCDoublePositiveInfinity(void) {
    uint64_t v = ((uint64_t)0x7ff0000000000000ULL);
    return *(double *)(&v);
}
static inline double __XCDoubleNegativeInfinity(void) {
    uint64_t v = ((uint64_t)0xfff0000000000000ULL);
    return *(double *)(&v);
}
static inline double __XCDoubleZero(void) {
    double v = 0.0;
    return v;
}

static inline XCError_e __XCDecodeUInt63Varint(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t * _Nonnull value) {
    ssize_t used = 0;
    uint64_t tmp = 0;
    if (*location >= capacity - used) {
        return XCErrorNotEnough;
    }
    uint8_t byte = bytes[*location + used];
    used += 1;
    tmp = byte & 0x7f;
    if (byte == 0x80) {
        return XCErrorVarInt;
    } else if (byte & 0x80) {
        while (*location < capacity - used) {
            if (used >= 9) {
                return XCErrorVarInt;
            }
            uint8_t byte = bytes[*location + used];
            used += 1;
            tmp = (tmp << 7) + (byte & 0x7f);
            if ((byte & 0x80) == 0) {
                *value = tmp;
                *location += used;
                return XCErrorNone;
            }
        }
        return XCErrorNotEnough;
    } else {
        *value = tmp;
        *location += 1;
        return XCErrorNone;
    }
}

/// buffer.capacity >= 9
static inline ssize_t __XCEncodeUInt63VarintToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    // 63-7=56
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 56) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 49) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 42) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 35) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }

    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;
    return used;
}


static inline XCError_e __XCEncodeUInt63Varint(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    
    uint8_t buffer[8] = { 0 };
    // 63-7=56
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 56) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 49) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 42) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 35) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    if (*location >= capacity - used - 1) {
        return XCErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, used);
    bytes[*location + used] = (uint8_t)(value & 0x7f);
    *location += used + 1;
    return XCErrorNone;
}

XCError_e __XCEncodeUInt64Varint_old(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    ssize_t length = (64 - XCUInt64LeadingZeroBitCount(value) + 6) / 7;
    if (length == 0) {
        length = 1;
    }
    if (*location + length > capacity) {
        return XCErrorNotEnough;
    }
    ssize_t lastOffset = length - 1;
    for (ssize_t offset=0; offset<lastOffset; offset++) {
        bytes[*location + offset] = (uint8_t)((value >> ((lastOffset - offset) * 7)) | 0x80);
    }
    bytes[*location + lastOffset] = (uint8_t)(value & 0x7f);
    *location += length;
    return XCErrorNone;
}

XCError_e __XCEncodeUInt64Varint_old2(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    uint8_t buffer[16] = { 0 };
    ssize_t used = 0;
    for (ssize_t shift = 63; shift>0; shift-=7) {
        uint8_t byte = (uint8_t)((value >> shift) | 0x80);
        if (used > 0 || 0x80 != byte) {
            buffer[used] = byte;
            used += 1;
        }
    }
    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;
    
    if (*location >= capacity - used) {
        return XCErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, used);
    *location += used;
    return XCErrorNone;
}

static inline ssize_t __XCEncodeUInt64VarintToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 63) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 56) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 49) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 42) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 35) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;

    return used;
}

static inline XCError_e __XCEncodeUInt64Varint(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    XDebugAssert(bytes, "");
    
    uint8_t buffer[16] = { 0 };
    // 63-7=56
    ssize_t used = 0;
    
    uint8_t byte = (uint8_t)((value >> 63) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 56) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 49) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 42) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 35) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 28) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 21) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 14) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    byte = (uint8_t)((value >> 7) | 0x80);
    if (used > 0 || 0x80 != byte) {
        buffer[used] = byte;
        used += 1;
    }
    buffer[used] = (uint8_t)(value & 0x7f);
    used += 1;

    if (*location >= capacity - used) {
        return XCErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, used);
    *location += used;
    return XCErrorNone;
}

static inline XCError_e __XCDecodeUInt64Varint(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t * _Nonnull value) {
    int32_t used = 0;
    uint64_t tmp = 0;
    if (*location >= capacity - used) {
        return XCErrorNotEnough;
    }
    uint8_t byte = bytes[*location + used];
    used += 1;
    tmp = byte & 0x7f;
    if (byte == 0x80) {
        return XCErrorVarInt;
    } else if (byte & 0x80) {
        while (*location < capacity - used) {
            if (used >= 10) {
                return XCErrorVarInt;
            }
            
            uint8_t byte = bytes[*location + used];
            used += 1;
            
            tmp = (tmp << 7) | (byte & 0x7f);
            if ((byte & 0x80) == 0) {
                if (used == 10 && bytes[*location] != 0x81) {
                    return XCErrorVarInt;
                }
                *value = tmp;
                *location += used;
                return XCErrorNone;
            }
        }
        return XCErrorNotEnough;
    } else {
        *value = tmp;
        *location += 1;
        return XCErrorNone;
    }
}

static inline XCError_e __XCEncodeHeaderCount(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCType_e type, ssize_t count) {
    if (count < 0) {
        return XCErrorCount;
    }
    if (count > 14) {
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, type, 15);
        
        uint8_t buffer[16] = { 0 };
        buffer[0] = header;
        uint64_t varint = count - 15;
        ssize_t length = 1 + __XCEncodeUInt63VarintToBuffer(buffer + 1, varint);
        
        if (*location > capacity - length) {
            return XCErrorNotEnough;
        }
        memcpy(bytes + *location, buffer, length);
        *location += length;
        return XCErrorNone;
    } else {
        if (*location > capacity - 1) {
            return XCErrorNotEnough;
        }
        uint8_t layout = (uint8_t)count;
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, type, layout);
        bytes[*location] = header;
        *location += 1;
        return XCErrorNone;
    }
}

static inline XCError_e __XCDecodeHeaderCount(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint8_t layout, uint64_t * _Nonnull value) {
    uint64_t count = 0;
    if (layout == 15) {
        XCError_e result = __XCDecodeUInt64Varint(bytes, capacity, location, &count);
        if (result != XCErrorNone) {
            return result;
        }
        if (count > UINT64_MAX - 15) {
            return XCErrorCount;
        }
        count += 15;
    } else {
        count = layout;
    }
    *value = count;
    return XCErrorNone;
}


static inline ssize_t __XCEncodeSignAndSignificandToBuffer(uint8_t * _Nonnull buffer, uint64_t value) {
    ssize_t used = 0;
    uint64_t tmp = value;
    while (0 != tmp) {
        buffer[used] = (uint8_t)(tmp >> 56);
        used += 1;
        tmp = tmp << 8;
    }
    return used;
}

static inline XCError_e __XCDecodeSignAndSignificand(const uint8_t * _Nonnull bytes, ssize_t length, uint64_t * _Nonnull _value) {
    uint64_t value = 0;
    if (length > 0) {
        uint64_t v = 0;
        for (ssize_t i=0; i<length; i++) {
            v = bytes[i];
            value |= v << ((7 - i) * 8);
        }
        if (v == 0) {
            return XCErrorNumberContent;
        }
    }
    *_value = value;
    return XCErrorNone;
}

static inline XCNumberNormalContent_s __XCEncodeIntNumberInternal(uint64_t sign, uint64_t v) {
    XCNumberNormalContent_s content = {};
    // 高位->低位 前导0个数
    uint64_t leadingZeroCount = XCUInt64LeadingZeroBitCount(v);
    int64_t e = leadingZeroCount + 1;
    uint64_t m = v << e;
    content.exponent = 64 - e;
    content.signAndSignificand = sign | (m >> 1);
    return content;
}

/// f: f != nan && f != inf && f != 0
static inline XCNumberNormalContent_s _XCEncodeNumberFloat64(double f) {
    XCNumberNormalContent_s number = {};
    uint64_t bits = *(uint64_t *)&(f);
    uint64_t sign = bits & (UINT64_C(1) << 63);
    uint64_t te = (bits & UINT64_C(0x7FF0000000000000)) >> 52;
    int64_t e = (int64_t)te - 1023;
    
    XDebugAssert(e < 1024, "");
    XDebugAssert(e >= -1023, "");

    if (e == 1024) {// nan inf
        abort();
    } else if (e == -1023) {
        // 非规约数
        uint64_t m = (bits & UINT64_C(0xFFFFFFFFFFFFF)) << UINT64_C(12);
        XDebugAssert(0 != m, "");
        uint64_t shift = XCUInt64LeadingZeroBitCount(m) + 1;
        XDebugAssert(shift <= 52, "");
        m = m << shift;
        number.exponent = -1022 - shift;
        number.signAndSignificand = sign | (m >> 1);
    } else {
        // e: [1, 2046]
        uint64_t m = (bits & UINT64_C(0xFFFFFFFFFFFFF)) << UINT64_C(11);
        number.exponent = e;
        number.signAndSignificand = sign | m;
    }
    return number;
}

/// number != 0
static inline XCNumberNormalContent_s _XCEncodeNumberUInt64(uint64_t number) {
    XDebugAssert(number != 0, "");
    return __XCEncodeIntNumberInternal(0, number);
}

/// number != 0
static inline XCNumberNormalContent_s _XCEncodeNumberSInt64(int64_t value) {
    XDebugAssert(value != 0, "");
    uint64_t v = value > 0 ? value : value * (-1);
    uint64_t sign = value > 0 ? 0 : UINT64_C(1) << UINT64_C(63);
    return __XCEncodeIntNumberInternal(sign, v);
}

static inline XCError_e __XCDecodeNumberValue(int64_t exponent, uint64_t signAndSignificand, XCNumberValue_s * _Nonnull number) {
    uint64_t sign = signAndSignificand & (UINT64_C(1) << 63);
    uint64_t m = signAndSignificand & (UINT64_MAX >> 1);
    uint64_t m2 = (UINT64_C(1) << 63) | m;
    int64_t trailingZerosCount = XCUInt64TrailingZeroBitCount(m2);
    if (exponent > -1023 && exponent < 1024) {
//        uint64_t e = exponent + 1023;
        if (trailingZerosCount >= 11) {
            uint64_t e = exponent + 1023;
            uint64_t bits = sign | (e << 52) | (m >> 11);
            number->type = XCNumberTypeFloat64;
            number->value.f = *(double *)&(bits);
            return XCErrorNone;
        } else {
            uint64_t m2 = (UINT64_C(1) << 63) | m;
            if (exponent >= 0 && exponent <= 63 && 63 - exponent <= trailingZerosCount) {
                uint64_t value = m2 >> (63 - exponent);
                // 1 exponent=0
                // 2 exponent=1 1
                uint64_t sint64Min = UINT64_C(1) << 63;
                if (sign) {// 负数
                    if (value == sint64Min) {
                        number->type = XCNumberTypeSInt;
                        number->value.s = INT64_MIN;
                        return XCErrorNone;
                    } else if (value < sint64Min) {
                        int64_t sv = value;
                        sv *= -1;
                        number->type = XCNumberTypeSInt;
                        number->value.s = sv;
                        return XCErrorNone;
                    } else {
                        number->type = XCNumberTypeNone;
                        number->value.u = 0;
                        return XCErrorNumberOutOfBounds;
                    }
                } else {
                    if (value < sint64Min) {
                        int64_t sv = value;
                        number->type = XCNumberTypeSInt;
                        number->value.s = sv;
                    } else {
                        number->type = XCNumberTypeUInt;
                        number->value.u = value;
                    }
                    return XCErrorNone;
                }
            } else {
                number->type = XCNumberTypeNone;
                number->value.u = 0;
                return XCErrorNumberOutOfBounds;
            }
        }
    } else if (exponent >= 1024) {
        number->type = XCNumberTypeNone;
        number->value.u = 0;
        return XCErrorNumberOutOfBounds;
    } else { // number.e <= -1023
        int64_t shift = -1022 - exponent + 11;
        if (trailingZerosCount >= shift) {
            uint64_t bits = sign | (m2 >> shift);
            number->type = XCNumberTypeFloat64;
            number->value.f = *(double *)&(bits);
            return XCErrorNone;
        } else {
            number->type = XCNumberTypeNone;
            number->value.u = 0;
            return XCErrorNumberOutOfBounds;
        }
    }
}

ssize_t XCHeaderMaxLength(void) {
    return 16;
}

XCError_e XCDecodeHeader(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCValueHeader_s * _Nonnull header) {
    XAssert(bytes, "");
    XAssert(header, "");
    XAssert(location, "");

    bzero(header, sizeof(XCValueHeader_s));
    if (*location >= capacity) {
        return XCErrorNotEnough;
    }
    XCError_e result = 0;
    uint8_t byte = bytes[*location];
    uint8_t type = 0;
    uint8_t layout = 0;
    XCDecodeTypeLayout(byte, &type, &layout);
    *location += 1;

    switch ((XCType_e)type) {
        case XCTypeNil: {
            if (layout != 0) {
                return XCErrorNilContent;
            }
            header->type = type;
            return XCErrorNone;
        }
        case XCTypeBool: {
            if (layout > 1) {
                return XCErrorBoolContent;
            }
            header->type = type;
            header->value.boolValue = layout != 0;
            return XCErrorNone;
        }
        case XCTypeString:
        case XCTypeData: {
            uint64_t count = 0;
            result = __XCDecodeHeaderCount(bytes, capacity, location, layout, &count);
            if (result != XCErrorNone) {
                return result;
            }
            if (*location > capacity - count) {
                return XCErrorNotEnough;
            }
            header->type = type;
            header->value.count = count;
            return XCErrorNone;
        }
        case XCTypeArray:
        case XCTypeOrderedMap:
        case XCTypeOrderedSet: {
            uint64_t count = 0;
            result = __XCDecodeHeaderCount(bytes, capacity, location, layout, &count);
            if (result != XCErrorNone) {
                return result;
            }
            if (*location > capacity - count) {
                return XCErrorNotEnough;
            }
            header->type = type;
            header->value.count = count;
            return XCErrorNone;
        }
        case XCTypeNumber: {
            header->type = type;
            switch (layout) {
                case XCNumberLayoutZero: {
                    header->value.number.type = XCNumberTypeFloat64;
                    header->value.number.value.f = __XCDoubleZero();
                    return XCErrorNone;
                }
                case XCNumberLayoutNan: {
                    header->value.number.type = XCNumberTypeFloat64;
                    header->value.number.value.f = __XCDoubleNan();
                    return XCErrorNone;
                }
                case XCNumberLayoutPositiveInfinity: {
                    header->value.number.type = XCNumberTypeFloat64;
                    header->value.number.value.f = __XCDoublePositiveInfinity();
                    return XCErrorNone;
                }
                case XCNumberLayoutNegativeInfinity: {
                    header->value.number.type = XCNumberTypeFloat64;
                    header->value.number.value.f = __XCDoubleNegativeInfinity();
                    return XCErrorNone;
                }
                case XCNumberLayoutLarge: {
                    return XCErrorNumberOutOfBounds;
                }
                default: {
                    ssize_t len = layout - XCNumberLayoutLarge;
                    ssize_t startIndex = *location;
                    if (*location > capacity - len) {
                        return XCErrorNotEnough;
                    }
                    uint64_t ev = 0;
                    result = __XCDecodeUInt64Varint(bytes, *location + len, location, &ev);
                    if (result != XCErrorNone) {
                        return result;
                    }
                    ssize_t usingLength = *location - startIndex;
                    int64_t exponent = XCSInt64ZigzagDecode(ev);
                    uint64_t signAndSignificand = 0;
                    result = __XCDecodeSignAndSignificand(bytes + *location, len - usingLength, &signAndSignificand);
                    if (result != XCErrorNone) {
                        return result;
                    }
                    *location += len - usingLength;
                     return __XCDecodeNumberValue(exponent, signAndSignificand, &(header->value.number));
                }
            }
        }
        case XCTypeTimeval:
            header->type = type;
            switch (layout) {
                case XCTimevalLayoutDistantPast: {
                    header->value.timeval = INT64_MIN;
                    return XCErrorNone;
                }
                case XCTimevalLayoutDistantFuture: {
                    header->value.timeval = INT64_MAX;
                    return XCErrorNone;
                }
                default: {
                    int32_t length = layout - XCTimevalLayoutZeroByteCount;
                    if (*location > capacity - length) {
                        return XCErrorNotEnough;
                    }
                    if (length > 8) {
                        return XCErrorTimevalContent;
                    }
                    
                    uint64_t uvalue = 0;
                    if (length > 0) {
                        uint64_t v = bytes[*location];
                        if (0 == v) {
                            return XCErrorTimevalContent;
                        }
                        for (ssize_t i=1; i<length; i++) {
                            v = (v << 8) + bytes[*location + i];
                        }
                        uvalue = v;
                        *location += length;
                    }

                    int64_t value = XCSInt64ZigzagDecode(uvalue);
                    if (value == INT64_MIN) {
                        return XCErrorTimevalContent;
                    } else if (value == INT64_MAX) {
                        return XCErrorTimevalContent;
                    }
                    header->value.timeval = value;
                    return XCErrorNone;
                }
            }
            break;
        case XCTypeMessage: {
            uint64_t count = 0;
            result = __XCDecodeHeaderCount(bytes, capacity, location, layout, &count);
            if (result != XCErrorNone) {
                return result;
            }
            
            uint64_t mtype = 0;
            result = __XCDecodeUInt63Varint(bytes, capacity, location, &mtype);
            if (result != XCErrorNone) {
                return result;
            }
            if (*location > capacity - count) {
                return XCErrorCount;
            }
            header->type = type;
            header->value.message = XCMessageHeaderMake(mtype, count);
            return XCErrorNone;
        }
        default: {
            return XCErrorType;
        }
    }
    return XCErrorNone;
}

XCError_e XCDecodeFieldKeyOffset(const uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t * _Nonnull offset) {
    XAssert(bytes, "");
    XAssert(location, "");
    XAssert(offset, "");
    uint64_t v = 0;
    XCError_e error = __XCDecodeUInt63Varint(bytes, capacity, location, &v);
    if (XCErrorNone != error) {
        return error;
    }
    *offset = (int64_t)v;
    return XCErrorNone;
}

XCError_e XCEncodeFieldKeyOffset(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t offset) {
    if (offset < 0) {
        return XCErrorMessageIndexOffset;
    }
    uint8_t buffer[24] = { 0 };
    uint64_t value = offset;
    ssize_t length = __XCEncodeUInt64VarintToBuffer(buffer, value);
    if (*location > capacity - length) {
        return XCErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, length);
    *location += length;
    return XCErrorNone;
}

XCError_e XCEncodeNil(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location) {
    if (*location + 1 > capacity) {
        return XCErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XCTypeNil, 0);
    bytes[*location] = header;
    *location += 1;
    return XCErrorNone;
}

XCError_e XCEncodeBool(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, _Bool value) {
    if (*location + 1 > capacity) {
        return XCErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XCTypeBool, value ? 1 : 0);
    bytes[*location] = header;
    *location += 1;
    return XCErrorNone;
}

static uint8_t const __XCEncodeNumberLayoutOffset = XCNumberLayoutLarge - 1;

static inline XCError_e __XCEncodeNumberByte(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, XCNumberNormalContent_s value) {
    uint8_t buffer[24] = { 0 };
    ssize_t length = 1;
    length += __XCEncodeUInt64VarintToBuffer(buffer + length, XCSInt64ZigzagEncode(value.exponent));
    length += __XCEncodeSignAndSignificandToBuffer(buffer + length, value.signAndSignificand);
    
    if (*location > capacity - length) {
        return XCErrorNotEnough;
    }
    uint8_t layout = length + __XCEncodeNumberLayoutOffset;
    if (layout >= 16) {
        return XCErrorLayout;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XCTypeNumber, layout);
    buffer[0] = header;
    
    memcpy(bytes + *location, buffer, length);
    *location += length;
    return XCErrorNone;
    
//    if (*location > capacity - length) {
//        return XCErrorNotEnough;
//    }
//    ssize_t headerIndex = *location;
//    *location += 1;
//    XCError_e result = __XCEncodeUInt64Varint(bytes, capacity, location, XCSInt64ZigzagEncode(value.exponent));
//    if (result != XCErrorNone) {
//        return result;
//    }
//    result = XCEncodeSignAndSignificand(bytes, capacity, location, value.signAndSignificand);
//    if (result != XCErrorNone) {
//        return result;
//    }
//    ssize_t len = *location - headerIndex - 1;
//    uint8_t layout = len + XCNumberLayoutLarge;
//    if (layout >= 16) {
//        return XCErrorLayout;
//    }
//    uint8_t header = 0;
//    XCEncodeTypeLayout(&header, XCTypeNumber, layout);
//    bytes[headerIndex] = header;
//    return XCErrorNone;
}

static inline XCError_e __XCEncodeNumberHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint8_t layout) {
    if (*location + 1 > capacity) {
        return XCErrorNotEnough;
    }
    uint8_t header = 0;
    XCEncodeTypeLayout(&header, XCTypeNumber, layout);
    bytes[*location] = header;
    *location += 1;
    return XCErrorNone;
}
XCError_e XCEncodeNumberUInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, uint64_t value) {
    if (0 == value) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberLayoutZero);
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberUInt64(value);
        return __XCEncodeNumberByte(bytes, capacity, location, data);
    }
}
XCError_e XCEncodeNumberSInt64(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value) {
    if (0 == value) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberLayoutZero);
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberSInt64(value);
        return __XCEncodeNumberByte(bytes, capacity, location, data);
    }
}
XCError_e XCEncodeNumberDouble(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, double value) {
    if (value == __XCDoubleZero()) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberLayoutZero);
    } else if (isnan(value)) {
        return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberLayoutNan);
    } else if (isinf(value)) {
        if (value < 0) {
            return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberLayoutNegativeInfinity);
        } else {
            return __XCEncodeNumberHeader(bytes, capacity, location, XCNumberLayoutPositiveInfinity);
        }
    } else {
        XCNumberNormalContent_s data = _XCEncodeNumberFloat64(value);
        return __XCEncodeNumberByte(bytes, capacity, location, data);
    }
}

XCError_e XCEncodeTimeval(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, int64_t value) {
    if (value == INT64_MIN) {
        if (*location + 1 > capacity) {
            return XCErrorNotEnough;
        }
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, XCTypeTimeval, XCTimevalLayoutDistantPast);
        bytes[*location] = header;
        *location += 1;
        return XCErrorNone;
    } else if (value == INT64_MAX) {
        if (*location + 1 > capacity) {
            return XCErrorNotEnough;
        }
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, XCTypeTimeval, XCTimevalLayoutDistantFuture);
        bytes[*location] = header;
        *location += 1;
        return XCErrorNone;
    } else {
        uint8_t buffer[24] = { 0 };
        uint8_t header = 0;
        uint64_t encodedBytes = XCSInt64ZigzagEncode(value);
        ssize_t length = 1;
        length += __XCEncodeTrimLeadingZeroByteIntToBuffer(buffer + length, encodedBytes);
        if (*location > capacity - length) {
            return XCErrorNotEnough;
        }
        XCEncodeTypeLayout(&header, XCTypeTimeval, XCTimevalLayoutZeroByteCount - 1 + length);
        buffer[0] = header;
        memcpy(bytes + *location, buffer, length);
        *location += length;
        return XCErrorNone;
    }
}

XCError_e XCEncodeMessageHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count, int64_t type) {
    if (count < 0) {
        return XCErrorCount;
    }
    if (type < 0) {
        return XCErrorMessageContent;
    }
    uint8_t buffer[24] = { 0 };
    ssize_t length = 1;
    if (count > 14) {
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, XCTypeMessage, 15);
        buffer[0] = header;
        uint64_t varint = count - 15;
        length += __XCEncodeUInt63VarintToBuffer(buffer + length, varint);
        length += __XCEncodeUInt63VarintToBuffer(buffer + length, type);
    } else {
        uint8_t layout = (uint8_t)count;
        uint8_t header = 0;
        XCEncodeTypeLayout(&header, XCTypeMessage, layout);
        buffer[0] = header;
        length += __XCEncodeUInt63VarintToBuffer(buffer + length, type);
    }
    
    if (*location > capacity - length) {
        return XCErrorNotEnough;
    }
    memcpy(bytes + *location, buffer, length);
    *location += length;
    return XCErrorNone;
}

XCError_e XCEncodeArrayHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XCTypeArray, count);
}

XCError_e XCEncodeOrderedMapHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XCTypeOrderedMap, count);
}

XCError_e XCEncodeOrderedSetHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XCTypeOrderedSet, count);
}

XCError_e XCEncodeDataHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XCTypeData, count);
}

XCError_e XCEncodeStringHeader(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, ssize_t count) {
    return __XCEncodeHeaderCount(bytes, capacity, location, XCTypeString, count);
}

XCError_e XCEncodeBody(uint8_t * _Nonnull bytes, ssize_t capacity, ssize_t * _Nonnull location, const void * _Nonnull data, ssize_t count) {
    if (count < 0) {
        return XCErrorCount;
    }
    if (*location + count > capacity) {
        return XCErrorNotEnough;
    }
    memcpy(bytes + *location, data, count);
    *location += count;
    return XCErrorNone;
}

