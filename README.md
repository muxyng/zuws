# zuws

Small Zig bindings for uWebSockets, tuned for our deploy style.

- Zig: `0.16.0-dev.2535+b5bd49460`
- Linux backend: epoll
- In-process TLS: off (put nginx/caddy in front)
- WebSocket compression: off

Install:

```bash
zig fetch --save "git+https://github.com/muxyng/zuws?ref=main#<commit>"
```

Then import in `build.zig`:

```zig
const zuws = b.dependency("zuws", .{
    .target = target,
    .optimize = optimize,
    .debug_logs = false,
    .with_proxy = false,
});

exe.root_module.addImport("zuws", zuws.module("zuws"));
exe.root_module.addImport("uws", zuws.module("uws"));
```
