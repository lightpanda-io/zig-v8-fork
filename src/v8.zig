const std = @import("std");

const c = @cImport({
    @cInclude("binding.h");
});

pub const String = c.String;
pub const Value = c.Value;

pub const Platform = struct {
    const Self = @This();

    handle: *c.Platform,

    /// Must be called first before initV8Platform and initV8
    /// Returns a new instance of the default v8::Platform implementation.
    ///
    /// |thread_pool_size| is the number of worker threads to allocate for
    /// background jobs. If a value of zero is passed, a suitable default
    /// based on the current number of processors online will be chosen.
    /// If |idle_task_support| is enabled then the platform will accept idle
    /// tasks (IdleTasksEnabled will return true) and will rely on the embedder
    /// calling v8::platform::RunIdleTasks to process the idle tasks.
    pub fn initDefault(thread_pool_size: u32, idle_task_support: bool) Self {
        // Verify struct sizes.
        const assert = std.debug.assert;
        assert(@sizeOf(c.CreateParams) == c.v8__Isolate__CreateParams__SIZEOF());
        assert(@sizeOf(c.TryCatch) == c.v8__TryCatch__SIZEOF());
        return .{
            .handle = c.v8__Platform__NewDefaultPlatform(@intCast(c_int, thread_pool_size), if (idle_task_support) 1 else 0).?,
        };
    }

    pub fn deinit(self: Self) void {
        c.v8__Platform__DELETE(self.handle);
    }

    /// [V8]
    /// Pumps the message loop for the given isolate.
    ///
    /// The caller has to make sure that this is called from the right thread.
    /// Returns true if a task was executed, and false otherwise. If the call to
    /// PumpMessageLoop is nested within another call to PumpMessageLoop, only
    /// nestable tasks may run. Otherwise, any task may run. Unless requested through
    /// the |behavior| parameter, this call does not block if no task is pending. The
    /// |platform| has to be created using |NewDefaultPlatform|.
    pub fn pumpMessageLoop(self: Self, isolate: Isolate, wait_for_work: bool) bool {
        return c.v8__Platform__PumpMessageLoop(self.handle, isolate.handle, wait_for_work);
    }
};

pub fn getVersion() []const u8 {
    const str = c.v8__V8__GetVersion();
    const idx = std.mem.indexOfSentinel(u8, 0, str);
    return str[0..idx];
}

pub fn initV8Platform(platform: Platform) void {
    c.v8__V8__InitializePlatform(platform.handle);
}

pub fn initV8() void {
    c.v8__V8__Initialize();
}

pub fn deinitV8() bool {
    return c.v8__V8__Dispose() == 1;
}

pub fn deinitV8Platform() void {
    c.v8__V8__ShutdownPlatform();
}

pub fn initCreateParams() c.CreateParams {
    var params: c.CreateParams = undefined;
    c.v8__Isolate__CreateParams__CONSTRUCT(&params);
    return params;
}

pub fn createDefaultArrayBufferAllocator() *c.ArrayBufferAllocator {
    return c.v8__ArrayBuffer__Allocator__NewDefaultAllocator().?;
}

pub fn destroyArrayBufferAllocator(alloc: *c.ArrayBufferAllocator) void {
    c.v8__ArrayBuffer__Allocator__DELETE(alloc);
}

pub const Isolate = struct {
    const Self = @This();

    handle: *c.Isolate,

    pub fn init(params: *const c.CreateParams) Self {
        const ptr = @intToPtr(*c.CreateParams, @ptrToInt(params));
        return .{
            .handle = c.v8__Isolate__New(ptr).?,
        };
    }

    /// [V8]
    /// Disposes the isolate.  The isolate must not be entered by any
    /// thread to be disposable.
    pub fn deinit(self: Self) void {
        c.v8__Isolate__Dispose(self.handle);
    }

    /// [V8]
    /// Sets this isolate as the entered one for the current thread.
    /// Saves the previously entered one (if any), so that it can be
    /// restored when exiting.  Re-entering an isolate is allowed.
    /// [Notes]
    /// This is equivalent to initing an Isolate Scope.
    pub fn enter(self: *Self) void {
        c.v8__Isolate__Enter(self.handle);
    }

    /// [V8]
    /// Exits this isolate by restoring the previously entered one in the
    /// current thread.  The isolate may still stay the same, if it was
    /// entered more than once.
    ///
    /// Requires: this == Isolate::GetCurrent().
    /// [Notes]
    /// This is equivalent to deiniting an Isolate Scope.
    pub fn exit(self: *Self) void {
        c.v8__Isolate__Exit(self.handle);
    }

    pub fn getCurrentContext(self: Self) Context {
        return .{
            .handle = c.v8__Isolate__GetCurrentContext(self.handle).?,
        };
    }

};

pub const HandleScope = struct {
    const Self = @This();

    inner: c.HandleScope,

    /// [Notes]
    /// This starts a new stack frame to record objects created.
    pub fn init(self: *Self, isolate: Isolate) void {
        c.v8__HandleScope__CONSTRUCT(&self.inner, isolate.handle);
    }

    /// [Notes]
    /// This pops the scope frame and allows V8 to mark/free objects created since initHandleScope.
    /// In C++ code, this would happen automatically when the HandleScope var leaves the current scope.
    pub fn deinit(self: *Self) void {
        c.v8__HandleScope__DESTRUCT(&self.inner);
    }
};

pub const Context = struct {
    const Self = @This();

    handle: *c.Context,

    /// Creates a new context and returns a handle to the newly allocated
    /// context.
    ///
    /// \param isolate The isolate in which to create the context.
    ///
    /// \param extensions An optional extension configuration containing
    /// the extensions to be installed in the newly created context.
    ///
    /// \param global_template An optional object template from which the
    /// global object for the newly created context will be created.
    ///
    /// \param global_object An optional global object to be reused for
    /// the newly created context. This global object must have been
    /// created by a previous call to Context::New with the same global
    /// template. The state of the global object will be completely reset
    /// and only object identify will remain.
    pub fn init(isolate: Isolate, global_tmpl: ?*c.ObjectTemplate, global_obj: ?*c.Value) Self {
        return .{
            .handle = c.v8__Context__New(isolate.handle, global_tmpl, global_obj).?,
        };
    }

    /// [V8]
    /// Enter this context.  After entering a context, all code compiled
    /// and run is compiled and run in this context.  If another context
    /// is already entered, this old context is saved so it can be
    /// restored when the new context is exited.
    pub fn enter(self: *Self) void {
        c.v8__Context__Enter(self.handle);
    }

    /// [V8]
    /// Exit this context.  Exiting the current context restores the
    /// context that was in place when entering the current context.
    pub fn exit(self: *Self) void {
        c.v8__Context__Exit(self.handle);
    }

    /// [V8]
    /// Returns the isolate associated with a current context.
    pub fn getIsolate(self: *const Self) *Isolate {
        return c.v8__Context__GetIsolate(self);
    }
};

pub const Message = struct {
    const Self = @This();

    handle: *const c.Message,

    pub fn getSourceLine(self: Self, ctx: Context) ?*const c.String {
        return c.v8__Message__GetSourceLine(self.handle, ctx.handle);
    }

    pub fn getScriptResourceName(self: Self) *const c.Value {
        return c.v8__Message__GetScriptResourceName(self.handle).?;
    }

    pub fn getLineNumber(self: Self, ctx: Context) ?u32 {
        const num = c.v8__Message__GetLineNumber(self.handle, ctx.handle);
        return if (num >= 0) @intCast(u32, num) else null;
    }

    pub fn getStartColumn(self: Self) u32 {
        return @intCast(u32, c.v8__Message__GetStartColumn(self.handle));
    }

    pub fn getEndColumn(self: Self) u32 {
        return @intCast(u32, c.v8__Message__GetEndColumn(self.handle));
    }
};

pub const TryCatch = struct {
    const Self = @This();

    inner: c.TryCatch,

    // TryCatch is wrapped in a v8::Local so have to initialize in place.
    pub fn init(self: *Self, isolate: Isolate) void {
        c.v8__TryCatch__CONSTRUCT(&self.inner, isolate.handle);
    }

    pub fn deinit(self: *Self) void {
        c.v8__TryCatch__DESTRUCT(&self.inner);
    }

    pub fn hasCaught(self: Self) bool {
        return c.v8__TryCatch__HasCaught(&self.inner);
    }

    pub fn getException(self: Self) *const Value {
        return c.v8__TryCatch__Exception(&self.inner).?;
    }

    pub fn getStackTrace(self: Self, ctx: Context) ?*const Value {
        return c.v8__TryCatch__StackTrace(&self.inner, ctx.handle);
    }

    pub fn getMessage(self: Self) ?Message {
        if (c.v8__TryCatch__Message(&self.inner)) |message| {
            return Message{
                .handle = message,
            };
        } else {
            return null;
        }
    }
};

pub const ScriptOrigin = struct {
    const Self = @This();

    inner: c.ScriptOrigin,

    // ScriptOrigin is not wrapped in a v8::Local so we don't care if it points to another copy.
    pub fn initDefault(isolate: Isolate, resource_name: *const c.Value) Self {
        var inner: c.ScriptOrigin = undefined;
        c.v8__ScriptOrigin__CONSTRUCT(&inner, isolate.handle, resource_name);
        return .{
            .inner = inner,
        };
    }
};

pub fn createUtf8String(isolate: Isolate, str: []const u8) *const c.String {
    return c.v8__String__NewFromUtf8(isolate.handle, str.ptr, c.kNormal, @intCast(c_int, str.len)).?;
}

/// Null indicates there was an compile error.
pub fn compileScript(ctx: Context, src: *const c.String, origin: ?ScriptOrigin) ?*const c.Script {
    return c.v8__Script__Compile(ctx.handle, src, if (origin != null) &origin.?.inner else null);
}

/// Null indicates a runtime error.
pub fn runScript(ctx: Context, script: *const c.Script) ?*const c.Value {
    return c.v8__Script__Run(script, ctx.handle);
}

pub fn writeUtf8String(str: *const c.String, isolate: Isolate, buf: []const u8) u32 {
    const options = c.NO_NULL_TERMINATION | c.REPLACE_INVALID_UTF8;
    // num chars is how many utf8 characters are actually written and the function returns how many bytes were written.
    var nchars: c_int = 0;
    // TODO: Return num chars
    return @intCast(u32, c.v8__String__WriteUtf8(str, isolate.handle, buf.ptr, @intCast(c_int, buf.len), &nchars, options));
}

pub fn valueToString(ctx: Context, val: *const c.Value) *const c.String {
    return c.v8__Value__ToString(val, ctx.handle).?;
}

pub fn utf8Len(isolate: Isolate, str: *const c.String) u32 {
    return @intCast(u8, c.v8__String__Utf8Length(str, isolate.handle));
}