const c = @import("uws");
const std = @import("std");
const App = @import("./App.zig");

const Request = @This();

ptr: *c.uws_req_s,

pub fn getUrl(self: *const Request) []const u8 {
    var temp: [*c]const u8 = undefined;
    const len = c.uws_req_get_url(self.ptr, &temp);
    return temp[0..len];
}

pub fn getFullUrl(self: *const Request) []const u8 {
    var temp: [*c]const u8 = undefined;
    const len = c.uws_req_get_full_url(self.ptr, &temp);
    return temp[0..len];
}

pub fn getMethod(self: *const Request) !App.Method {
    const method = @constCast(self.getCaseSensitiveMethod());

    for (method) |*char| {
        char.* = std.ascii.toUpper(char.*);
    }

    return std.meta.stringToEnum(App.Method, method) orelse error.UnknownMethod;
}

pub fn getCaseSensitiveMethod(self: *const Request) []const u8 {
    var temp: [*c]const u8 = undefined;
    const len = c.uws_req_get_case_sensitive_method(self.ptr, &temp);
    return temp[0..len];
}

pub const Headers = std.StringHashMap([]const u8);

pub fn getAllHeaders(self: *const Request, gpa: std.mem.Allocator) !Headers {
    var map: Headers = .init(gpa);
    errdefer map.deinit();
    const did_error = c.uws_req_for_each_header(self.ptr, &map, headerIterator);
    if (did_error == 1) return error.OutOfMemory;
    return try map.clone();
}

fn headerIterator(ctx: ?*anyopaque, key: [*c]const u8, key_len: usize, value: [*c]const u8, value_len: usize) callconv(.c) u8 {
    const map: *Headers = @ptrCast(@alignCast(ctx));
    map.put(key[0..key_len], value[0..value_len]) catch return 1;
    return 0;
}

pub fn getHeader(self: *const Request, lower_case_header: []const u8) ?[]const u8 {
    var temp: [*c]const u8 = undefined;
    const len = c.uws_req_get_header(self.ptr, lower_case_header.ptr, lower_case_header.len, &temp);
    return if (temp == null) null else temp[0..len];
}

pub fn getQueryParam(self: *const Request, name: []const u8) ?[]const u8 {
    var temp: [*c]const u8 = undefined;
    const len = c.uws_req_get_query(self.ptr, name.ptr, name.len, &temp);
    return if (temp == null) null else temp[0..len];
}

pub fn getParameter(self: *const Request, index: u16) []const u8 {
    var temp: [*c]const u8 = undefined;
    const len = c.uws_req_get_parameter_index(self.ptr, @as(c_ushort, index), &temp);
    return temp[0..len];
}
