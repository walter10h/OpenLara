#define SEG_MATH    .text
#define SEG_TRANS   .data
#define SEG_FACE    .data
#define SEG_RASTER  .data
#define SEG_PHYSICS .data

// Matrix:
// int16 e00, e01, e02  // rotation
// int16 e10, e11, e12  // rotation
// int16 e20, e21, e22  // rotation
// int16 e03, e13, e23  // translation
//
// word [ N Z Z ]  // rot
//      [ Z N Z ]  // rot
//      [ Z Z N ]  // rot
//      [ Z Z Z ]  // trans
// long [ NZ ZZ NZ ZZ NZ ZZ ]

// row[0] rotation
#define M00     0
#define M01     2
#define M02     4
// row[1] rotation
#define M10     6
#define M11     8
#define M12     10
// row[2] rotation
#define M20     12
#define M21     14
#define M22     16
// row[3] translation
#define M03     18
#define M13     20
#define M23     22

#define MATRIX_SIZEOF   24

#define FIXED_SHIFT     14

#define FACE_TYPE_F     1

#define VERTEX_X                0
#define VERTEX_Y                2
#define VERTEX_Z                4
#define VERTEX_G                6
#define VERTEX_CLIP             7
#define VERTEX_T                8
#define VERTEX_PREV             12
#define VERTEX_NEXT             13
#define VERTEX_PADDING          14

#define VERTEX_SIZEOF_SHIFT     4
#define VERTEX_SIZEOF           (1 << VERTEX_SIZEOF_SHIFT)

#define VIEW_DIST       (1024 * 10)   // max = DIV_TABLE_END << PROJ_SHIFT
#define FOG_SHIFT       1
#define FOG_MAX         VIEW_DIST
#define FOG_MIN         (FOG_MAX - (8192 >> FOG_SHIFT))
#define VIEW_MIN        (64)
#define VIEW_MAX        (VIEW_DIST)
#define VIEW_OFF        4096

#define CLIP_FRAME      (1 << 0)
#define CLIP_LEFT       (1 << 1)
#define CLIP_RIGHT      (1 << 2)
#define CLIP_TOP        (1 << 3)
#define CLIP_BOTTOM     (1 << 4)
#define CLIP_FAR        (1 << 5)
#define CLIP_NEAR       (1 << 6)

#define VP_MINX         0
#define VP_MINY         4
#define VP_MAXX         8
#define VP_MAXY         12

#define FRAME_WIDTH     320
#define FRAME_HEIGHT    224

.macro align_fetch
    .p2alignw 2, 0x0009
.endm

.macro shlr14 x
        shll2   \x
        shlr16  \x
        //exts.w  x, x      // skip this because of mov.w
.endm

// int32 >> 12
// 1. shar x 12 => 12 op
// 2. (int32(int16(x >> 16)) << 4) | (x >> 12) => 8 op (require an extra register)
.macro shar12 x, t
        swap.w  \x, \t
        exts.w  \t, \t
        shll2   \t
        shll2   \t
        shlr8   \x
        shlr2   \x
        shlr2   \x
        or      \t, \x
.endm

// out = uv * f
// uv and out regs must be different
// destructive for uv reg
.macro scaleUV uv, out, f
        muls.w  \uv, \f
        shlr16  \uv
        sts     MACL, \out      // v = int16(uv) * f (16-bit shift)
        muls.w  \uv, \f
        sts     MACL, \uv       // u = int16(uv >> 16) * f (16-bit shift)
        shlr16  \uv
        xtrct   \uv, \out       // out = uint16(v >> 16) | (u & 0xFFFF0000)
.endm

// UUuuVVvv -> 0000VVUU
.macro getUV uv, index
        swap.b  \uv, \index     // UUuuvvVV
        swap.w  \index, \index  // vvVVUUuu
        shll8   \index          // VVUUuu00
        shlr16  \index          // 0000VVUU
.endm

// index (r0) = gLightmap[index]
// in index 0..255
// in lightmap one of 32 gLightmap slices
.macro lit lightmap, index
        mov.b   @(\index, \lightmap), \index
.endm
