pub const InternalMethod = enum(u8) {
    GET = 0,
    POST = 1,
    PUT = 2,
    OPTIONS = 3,
    DEL = 4,
    PATCH = 5,
    HEAD = 6,
    CONNECT = 7,
    TRACE = 8,
    ANY = 9,
};
