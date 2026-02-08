# zuws

Opinionated zig bindings for [`uWebSockets`](https://github.com/uNetworking/uWebSockets).

# Installation

In your `build.zig.zon` file add the following:

```zig
.dependencies = .{
    .zuws = .{
        .url = "git+https://github.com/muxyng/zuws?ref=main#<commit>",
        .hash = "zuws-...",
    },
},
```

And import it on your `build.zig` file:

```zig
const zuws = b.dependency("zuws", .{
    .target = target,
    .optimize = optimize,
    .debug_logs = true,
    .with_proxy = false,
});

exe.root_module.addImport("zuws", zuws.module("zuws"));
```

> [!NOTE]
> The raw C bindings are available via `zuws.module("uws")`

# Usage

```zig
const uws = @import("zuws");
const App = uws.App;
const Request = uws.Request;
const Response = uws.Response;

pub fn main() !void {
    const app: App = try .init();
    defer app.deinit();

    app.get("/hello", hello);
    app.listen(3000, null);
    app.run();
}

fn hello(res: *Response, _: *Request) void {
    const str = "Hello World!\n";
    res.end(str, false);
}
```

## TLS and compression

This fork is intentionally lean and ships an epoll + no-SSL + no-zlib build. TLS termination should happen at a reverse proxy (nginx/caddy) in front of the app.

# Grouping

Grouping is not something provided by uws itself and instead is an abstraction we provide to aid developers.

The grouping API has a `comptime` and a `runtime` variant, most of the time you will want to use the `comptime` variant, but for the rare cases where adding routes at runtime dynamically is needed the functionality is there.

## Creating groups at `comptime`

```zig
const app: App = try .init();
defer app.deinit();

const my_group = App.Group.initComptime("/v1")
    .get("/example", someHandler);

// This will create the following route:
// /v1/example
app.comptimeGroup(my_group);
```

## Creating groups at `runtime`

```zig
const app: App = try .init();
defer app.deinit();

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
const allocator = gpa.allocator();

var my_group = App.Group.init(allocator, "/v1");
try my_group.get("/example", someHandler);

// This will create the following route:
// /v1/example
try app.group(my_group);

// We highly recommend you deinit the group
// after you don't need it anymore
my_group.deinit();


```

## Combining groups together

We provide 2 different ways of combining groups together.

### Grouping

```zig
const app: App = try .init();
defer app.deinit();

const api = App.Group.initComptime("/api");
const v1 = App.Group.initComptime("/v1")
    .get("/example", someHandler);

_ = api.group(v1);

// This will create the following route:
// /api/v1/example
app.comptimeGroup(api);
```

### Merging

```zig
const app: App = try .init();
defer app.deinit();

const v1 = App.Group.initComptime("/v1")
    .get("/example", someHandler);
const v2 = App.Group.initComptime("/v2");

_ = v2.merge(v1);

// This will create the following route:
// /v2/example
app.comptimeGroup(v2);
```

# Running the Examples

To run the provided examples in `zuws`, clone the repository and run the following command:

```zsh
zig build example -- <example-name>
```

You can also generate the assembly of a specific example using the following:

```zsh
zig build example-asm -- <example-name>
```
