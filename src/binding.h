#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef uintptr_t usize;
typedef struct Data Data;
typedef struct ArrayBufferAllocator ArrayBufferAllocator;
typedef struct CreateParams CreateParams;
typedef struct Isolate Isolate;
typedef struct StackTrace StackTrace;
typedef struct StackFrame StackFrame;
typedef struct FixedArray FixedArray;
typedef struct Data Module;
typedef struct FunctionTemplate FunctionTemplate;
typedef struct Message Message;
typedef struct Data Context;
typedef struct Data Private;
typedef struct Data Signature;
typedef struct MicrotaskQueue MicrotaskQueue;
// Internally, all Value types have a base InternalAddress struct.
typedef uintptr_t InternalAddress;
// Super type.
typedef Data Value;
typedef Value Object;
typedef Value String;
typedef Value Function;
typedef Value Number;
typedef Value Primitive;
typedef Value Integer;
typedef Value BigInt;
typedef Value Array;
typedef Value Uint8ClampedArray;
typedef Value Uint8Array;
typedef Value Int8Array;
typedef Value Uint16Array;
typedef Value Int16Array;
typedef Value Uint32Array;
typedef Value Int32Array;
typedef Value BigUint64Array;
typedef Value BigInt64Array;
typedef Value Float16Array;
typedef Value Float32Array;
typedef Value Float64Array;
typedef Value ArrayBuffer;
typedef Value SharedArrayBuffer;
typedef Value ArrayBufferView;
typedef Value External;
typedef Value Symbol;
typedef Value Boolean;
typedef Value Promise;
typedef Value Name;
typedef Value PromiseResolver;
typedef Value RegExp;
typedef enum CompileOptions {
    kNoCompileOptions = 0,
    kConsumeCodeCache = 1,
    kEagerCompile = 2,
} CompileOptions;
typedef enum NoCacheReason {
    kNoCacheNoReason = 0,
    kNoCacheBecauseCachingDisabled,
    kNoCacheBecauseNoResource,
    kNoCacheBecauseInlineScript,
    kNoCacheBecauseModule,
    kNoCacheBecauseStreamingSource,
    kNoCacheBecauseInspector,
    kNoCacheBecauseScriptTooSmall,
    kNoCacheBecauseCacheTooCold,
    kNoCacheBecauseV8Extension,
    kNoCacheBecauseExtensionModule,
    kNoCacheBecausePacScript,
    kNoCacheBecauseInDocumentWrite,
    kNoCacheBecauseResourceWithNoCacheHandler,
    kNoCacheBecauseDeferredProduceCodeCache
} NoCacheReason;
typedef enum PromiseRejectEvent {
    kPromiseRejectWithNoHandler = 0,
    kPromiseHandlerAddedAfterReject = 1,
    kPromiseRejectAfterResolved = 2,
    kPromiseResolveAfterResolved = 3,
} PromiseRejectEvent;
typedef enum RegExpFlags {
    kRegExpNone        = 0,
    kRegExpGlobal      = 1 << 0,
    kRegExpIgnoreCase  = 1 << 1,
    kRegExpMultiline   = 1 << 2,
    kRegExpSticky      = 1 << 3,
    kRegExpUnicode     = 1 << 4,
    kRegExpDotAll      = 1 << 5,
    kRegExpLinear      = 1 << 6,
    kRegExpHasIndices  = 1 << 7,
    kRegExpUnicodeSets = 1 << 8,
} RegExpFlags;
typedef struct PromiseRejectMessage PromiseRejectMessage;
typedef void (*PromiseRejectCallback)(PromiseRejectMessage);
typedef Promise* (*HostImportModuleDynamicallyCallback)(Context*, Data*, Value*, String*, FixedArray*);
typedef void (*HostInitializeImportMetaObjectCallback)(Context*, Module*, Data*);
typedef enum MessageErrorLevel {
    kMessageLog = (1 << 0),
    kMessageDebug = (1 << 1),
    kMessageInfo = (1 << 2),
    kMessageError = (1 << 3),
    kMessageWarning = (1 << 4),
    kMessageAll = kMessageLog | kMessageDebug | kMessageInfo | kMessageError |
                  kMessageWarning,
} MessageErrorLevel;
typedef void (*MessageCallback)(const Message* message, const Value* data);
typedef struct OOMDetails {
    bool is_heap_oom;
    const char* detail;
} OOMDetails;
typedef void (*FatalErrorCallback)(const char* location, const char* message);
typedef void (*OOMErrorCallback)(const char* location, const OOMDetails* details);
typedef usize UniquePtr;
typedef struct SharedPtr {
    usize a;
    usize b;
} SharedPtr;
typedef uintptr_t IntAddress; // v8::internal::Address

typedef struct MaybeU32 {
    bool has_value;
    uint32_t value;
} MaybeU32;
typedef struct MaybeI32 {
    bool has_value;
    int32_t value;
} MaybeI32;
typedef struct MaybeF64 {
    bool has_value;
    double value;
} MaybeF64;
typedef struct MaybeBool {
    bool has_value;
    bool value;
} MaybeBool;
typedef enum PropertyAttribute {
    /** None. **/
    None = 0,
    /** ReadOnly, i.e., not writable. **/
    ReadOnly = 1 << 0,
    /** DontEnum, i.e., not enumerable. **/
    DontEnum = 1 << 1,
    /** DontDelete, i.e., not configurable. **/
    DontDelete = 1 << 2
} PropertyAttribute;

// Platform
typedef struct Platform Platform;
Platform* v8__Platform__NewDefaultPlatform(int thread_pool_size, int idle_task_support);
void v8__Platform__DELETE(Platform* platform);
bool v8__Platform__PumpMessageLoop(Platform* platform, Isolate* isolate, bool wait_for_work);
void v8__Platform__RunIdleTasks(Platform* platform, Isolate* isolate, double idle_time_in_seconds);

// Root
const Primitive* v8__Undefined(Isolate* isolate);
const Primitive* v8__Null(Isolate* isolate);
const Boolean* v8__True(Isolate* isolate);
const Boolean* v8__False(Isolate* isolate);
const Uint8ClampedArray* v8__Uint8ClampedArray__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Uint8Array* v8__Uint8Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Int8Array* v8__Int8Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Uint16Array* v8__Uint16Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Int16Array* v8__Int16Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Uint32Array* v8__Uint32Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Int32Array* v8__Int32Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Float16Array* v8__Float16Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Float32Array* v8__Float32Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const Float64Array* v8__Float64Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const BigUint64Array* v8__BigUint64Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

const BigInt64Array* v8__BigInt64Array__New(
    const ArrayBuffer* buf,
    size_t byte_offset,
    size_t length);

// V8
void v8__V8__InitializePlatform(Platform* platform);
void v8__V8__Initialize();
bool v8__V8__InitializeICU();
int v8__V8__Dispose();
void v8__V8__DisposePlatform();
const char* v8__V8__GetVersion();

// Microtask
typedef enum MicrotasksPolicy { kExplicit, kScoped, kAuto } MicrotasksPolicy;

// MicrotaskQueue
MicrotaskQueue* v8__MicrotaskQueue__New(Isolate* isolate, MicrotasksPolicy policy);
void v8__MicrotaskQueue__DELETE(MicrotaskQueue* queue);
void v8__MicrotaskQueue__PerformCheckpoint(MicrotaskQueue* queue, Isolate* isolate);
typedef void (*MicrotaskCallback)(void* data);
void v8__MicrotaskQueue__EnqueueMicrotask(MicrotaskQueue* queue, Isolate* isolate, MicrotaskCallback callback, void* data);
void v8__MicrotaskQueue__EnqueueMicrotaskFunc(MicrotaskQueue* queue, Isolate* isolate, const Function* function);

// Snapshot
typedef enum FunctionCodeHandling { kClear, kKeep } FunctionCodeHandling;

// Isolate
Isolate* v8__Isolate__New(CreateParams* params);
void v8__Isolate__Enter(Isolate* isolate);
void v8__Isolate__Exit(Isolate* isolate);
void v8__Isolate__Dispose(Isolate* isolate);
Context* v8__Isolate__GetCurrentContext(Isolate* isolate);
Context* v8__Isolate__GetIncumbentContext(Isolate* isolate);
const Value* v8__Isolate__ThrowException(
    Isolate* isolate,
    const Value* exception);
int v8__Isolate__ContextDisposedNotification(Isolate* isolate);
void v8__Isolate__SetHostImportModuleDynamicallyCallback(
    Isolate* isolate,
    HostImportModuleDynamicallyCallback callback);
void v8__Isolate__SetHostInitializeImportMetaObjectCallback(
    Isolate* isolate,
    HostInitializeImportMetaObjectCallback callback);
void v8__Isolate__SetPromiseRejectCallback(
    Isolate* isolate,
    PromiseRejectCallback callback);
void v8__Isolate__SetFatalErrorHandler(
    Isolate* isolate,
    FatalErrorCallback callback);
void v8__Isolate__SetOOMErrorHandler(
    Isolate* isolate,
    OOMErrorCallback callback);
MicrotasksPolicy v8__Isolate__GetMicrotasksPolicy(const Isolate* self);
void v8__Isolate__SetMicrotasksPolicy(
    Isolate* self,
    MicrotasksPolicy policy);
void v8__Isolate__PerformMicrotaskCheckpoint(Isolate* self);
bool v8__Isolate__AddMessageListener(
    Isolate* self,
    MessageCallback callback);
bool v8__Isolate__AddMessageListenerWithErrorLevel(
    Isolate* self,
    MessageCallback callback,
    int message_levels,
    const Value* data);
void v8__Isolate__SetCaptureStackTraceForUncaughtExceptions(
    Isolate* isolate,
    bool capture,
    int frame_limit);
void v8__Isolate__TerminateExecution(Isolate* self);
bool v8__Isolate__IsExecutionTerminating(Isolate* self);
void v8__Isolate__CancelTerminateExecution(Isolate* self);
typedef void (*InterruptCallback)(Isolate* isolate, void* data);
void v8__Isolate__RequestInterrupt(Isolate* self, InterruptCallback callback, void* data);
void v8__Isolate__LowMemoryNotification(Isolate* self);
typedef enum MemoryPressureLevel {
    kNone = 0,
    kModerate = 1,
    kCritical = 2
} MemoryPressureLevel;
void v8__Isolate__MemoryPressureNotification(Isolate* self, MemoryPressureLevel level);
typedef struct HeapStatistics {
    size_t total_heap_size;
    size_t total_heap_size_executable;
    size_t total_physical_size;
    size_t total_available_size;
    size_t used_heap_size;
    size_t heap_size_limit;
    size_t malloced_memory;
    size_t external_memory;
    size_t peak_malloced_memory;
    bool does_zap_garbage;
    size_t number_of_native_contexts;
    size_t number_of_detached_contexts;
    size_t total_global_handles_size;
    size_t used_global_handles_size;
} HeapStatistics;
void v8__Isolate__GetHeapStatistics(
    Isolate* self,
    HeapStatistics* stats);
usize v8__HeapStatistics__SIZEOF();
void* v8__Isolate__GetData(Isolate* self, int idx);
void v8__Isolate__SetData(Isolate* self, int idx, void* val);
void v8__Isolate__EnqueueMicrotask(Isolate* self, MicrotaskCallback callback, void* data);
void v8__Isolate__EnqueueMicrotaskFunc(Isolate* self, const Function* function);
bool v8__Isolate__HasPendingBackgroundTasks(Isolate *self);
const Data* v8__Isolate__GetDataFromSnapshotOnce(const Isolate *self, size_t idx);

typedef struct StartupData {
    const char* data;
    int raw_size;
} StartupData;

typedef struct ResourceConstraints {
    usize code_range_size_;
    usize max_old_generation_size_;
    usize max_young_generation_size_;
    usize initial_old_generation_size_;
    usize initial_young_generation_size_;
    uint64_t physical_memory_size_;
    uint32_t* stack_limit_;
} ResourceConstraints;

void v8__ResourceConstraints__ConfigureDefaultsFromHeapSize(
    ResourceConstraints* self,
    usize initial_heap_size_in_bytes,
    usize maximum_heap_size_in_bytes);

typedef struct CreateParams {
    void* code_event_handler; // JitCodeEventHandler
    ResourceConstraints constraints;
    StartupData* snapshot_blob;
    void* counter_lookup_callback;
    void* create_histogram_callback; // CreateHistogramCallback
    void* add_histogram_sample_callback; // AddHistogramSampleCallback
    ArrayBufferAllocator* array_buffer_allocator;
    SharedPtr array_buffer_allocator_shared;
    const intptr_t* external_references;
    bool allow_atomics_wait;
    bool only_terminate_in_safe_scope;
    int embedder_wrapper_type_index;
    int embedder_wrapper_object_index;
    void* fatal_error_callback;
    void* oom_error_callback;
    void* cpp_heap;
} CreateParams;
usize v8__Isolate__CreateParams__SIZEOF();
void v8__Isolate__CreateParams__CONSTRUCT(CreateParams* buf);

// FixedArray
int v8__FixedArray__Length(const FixedArray* self);
const Data* v8__FixedArray__Get(
    const FixedArray* self,
    const Context* ctx,
    int idx);

// ArrayBuffer
typedef void (*PromiseRejectCallback)(PromiseRejectMessage);
typedef void (*BackingStoreDeleterCallback)(void* data, size_t len, void* deleter_data);
typedef struct BackingStore BackingStore;
ArrayBufferAllocator* v8__ArrayBuffer__Allocator__NewDefaultAllocator();
void v8__ArrayBuffer__Allocator__DELETE(ArrayBufferAllocator* self);
BackingStore* v8__ArrayBuffer__NewBackingStore(
    Isolate* isolate,
    size_t byte_len);
BackingStore* v8__ArrayBuffer__NewBackingStore2(
    void* data,
    size_t byte_len,
    BackingStoreDeleterCallback deleter,
    void* deleter_data);
void* v8__BackingStore__Data(const BackingStore* self);
size_t v8__BackingStore__ByteLength(const BackingStore* self);
bool v8__BackingStore__IsShared(const BackingStore* self);
SharedPtr v8__BackingStore__TO_SHARED_PTR(BackingStore* unique_ptr);
void std__shared_ptr__v8__BackingStore__reset(SharedPtr* self);
BackingStore* std__shared_ptr__v8__BackingStore__get(const SharedPtr* self);
long std__shared_ptr__v8__BackingStore__use_count(const SharedPtr* self);
const ArrayBuffer* v8__ArrayBuffer__New(Isolate* isolate, size_t byte_len);
const ArrayBuffer* v8__ArrayBuffer__New2(Isolate* isolate, const SharedPtr* backing_store);
size_t v8__ArrayBuffer__ByteLength(const ArrayBuffer* self);
SharedPtr v8__ArrayBuffer__GetBackingStore(const ArrayBuffer* self);

// ArrayBufferView
const ArrayBuffer* v8__ArrayBufferView__Buffer(const ArrayBufferView* self);
size_t v8__ArrayBufferView__ByteLength(const ArrayBufferView* self);
size_t v8__ArrayBufferView__ByteOffset(const ArrayBufferView* self);

// HandleScope
typedef struct HandleScope {
    // internal vars.
    Isolate* isolate_;
    InternalAddress* prev_next_;
    InternalAddress* prev_limit_;
} HandleScope;
void v8__HandleScope__CONSTRUCT(HandleScope* buf, Isolate* isolate);
void v8__HandleScope__DESTRUCT(HandleScope* scope);

// Message
const String* v8__Message__Get(const Message* self);
const String* v8__Message__GetSourceLine(const Message* self, const Context* context);
const Value* v8__Message__GetScriptResourceName(const Message* self);
int v8__Message__GetLineNumber(const Message* self, const Context* context);
int v8__Message__GetStartColumn(const Message* self);
int v8__Message__GetEndColumn(const Message* self);
const StackTrace* v8__Message__GetStackTrace(const Message* self);

// TryCatch
typedef struct TryCatch {
    void* isolate_;
    struct TryCatch* next_;
    void* exception_;
    void* message_obj_;
    IntAddress js_stack_comparable_address_;
    usize flags;
} TryCatch;
usize v8__TryCatch__SIZEOF();
void v8__TryCatch__CONSTRUCT(TryCatch* buf, Isolate* isolate);
void v8__TryCatch__DESTRUCT(TryCatch* self);
const Value* v8__TryCatch__Exception(const TryCatch* self);
const Message* v8__TryCatch__Message(const TryCatch* self);
bool v8__TryCatch__HasCaught(const TryCatch* self);
const Value* v8__TryCatch__StackTrace(const TryCatch* self, const Context* context);
bool v8__TryCatch__IsVerbose(const TryCatch* self);
void v8__TryCatch__SetVerbose(
    TryCatch* self,
    bool value);
const Value* v8__TryCatch__ReThrow(TryCatch* self);

// StackTrace
int v8__StackTrace__GetFrameCount(const StackTrace* self);
const StackFrame* v8__StackTrace__GetFrame(
    const StackTrace* self,
    Isolate* isolate,
    uint32_t idx);
const StackTrace* v8__StackTrace__CurrentStackTrace__STATIC(Isolate* isolate, int frame_limit);
const String* v8__StackTrace__CurrentScriptNameOrSourceURL__STATIC(Isolate* isolate);

// StackFrame
int v8__StackFrame__GetLineNumber(const StackFrame* self);
int v8__StackFrame__GetColumn(const StackFrame* self);
int v8__StackFrame__GetScriptId(const StackFrame* self);
const String* v8__StackFrame__GetScriptName(const StackFrame* self);
const String* v8__StackFrame__GetScriptNameOrSourceURL(const StackFrame* self);
const String* v8__StackFrame__GetFunctionName(const StackFrame* self);
bool v8__StackFrame__IsEval(const StackFrame* self);
bool v8__StackFrame__IsConstructor(const StackFrame* self);
bool v8__StackFrame__IsWasm(const StackFrame* self);
bool v8__StackFrame__IsUserJavaScript(const StackFrame* self);

// Context
typedef struct ObjectTemplate ObjectTemplate;

typedef struct v8__ContextConfig {
    const ObjectTemplate* global_template;
    const Value* global_object;
    MicrotaskQueue* microtask_queue;
} v8__ContextConfig;

Context* v8__Context__New(Isolate* isolate, const ObjectTemplate* global_tmpl, const Value* global_obj);
Context* v8__Context__New__Config(Isolate* isolate, const v8__ContextConfig* config);
Context* v8__Context__FromSnapshot(Isolate*, size_t);
Context* v8__Context__FromSnapshot__Config(Isolate* isolate, size_t context_snapshot_index, const v8__ContextConfig* config);
void v8__Context__Enter(const Context* context);
void v8__Context__Exit(const Context* context);
Isolate* v8__Context__GetIsolate(const Context* context);
const Object* v8__Context__Global(const Context* self);
const Value* v8__Context__GetEmbedderData(
    const Context* self,
    int idx);
void v8__Context__SetEmbedderData(
    const Context* self,
    int idx,
    const Value* val);
void* v8__Context__GetAlignedPointerFromEmbedderData(
    const Context* self,
    int idx);
void v8__Context__SetAlignedPointerInEmbedderData(
    const Context* self,
    int idx,
    void* ptr);

int v8__Context__DebugContextId(const Context* self);
const Data* v8__Context__GetDataFromSnapshotOnce(const Context *self, size_t idx);

void v8__Context__SetSecurityToken(const Context* self, const Value* val);
void v8__Context__UseDefaultSecurityToken(const Context* self);
const Value* v8__Context__GetSecurityToken(const Context* self);

// Boolean
const Boolean* v8__Boolean__New(
    Isolate* isolate,
    bool value);

// String
typedef enum NewStringType {
    /**
     * Create a new string, always allocating new storage memory.
     */
    kNormal,

    /**
     * Acts as a hint that the string should be created in the
     * old generation heap space and be deduplicated if an identical string
     * already exists.
     */
    kInternalized
} NewStringType;
typedef enum WriteOptions {
    NO_OPTIONS = 0,
    HINT_MANY_WRITES_EXPECTED = 1,
    NO_NULL_TERMINATION = 2,
    PRESERVE_ONE_BYTE_NULL = 4,
    // Used by WriteUtf8 to replace orphan surrogate code units with the
    // unicode replacement character. Needs to be set to guarantee valid UTF-8
    // output.
    REPLACE_INVALID_UTF8 = 8
} WriteOptions;
String* v8__String__NewFromUtf8(Isolate* isolate, const char* data, NewStringType type, int length);
size_t v8__String__WriteUtf8(const String* str, Isolate* isolate, const char* buf, size_t len, WriteOptions options);
int v8__String__Utf8Length(const String* str, Isolate* isolate);

// One-byte (Latin-1) string APIs. NewFromOneByte maps each input byte 0..255
// directly to a JS code unit 0..255 (no UTF-8 decoding). Length returns the
// JS-level character count (code units). ContainsOnlyOneByte tells whether
// every code unit fits in a uint8_t. WriteOneByte copies code units as bytes
// (truncating any code unit >= 256, so callers should check ContainsOnlyOneByte
// first if that distinction matters).
String* v8__String__NewFromOneByte(Isolate* isolate, const uint8_t* data, NewStringType type, int length);
int v8__String__Length(const String* str);
bool v8__String__ContainsOnlyOneByte(const String* str);
void v8__String__WriteOneByte(const String* str, Isolate* isolate, uint32_t offset, uint32_t length, uint8_t* buffer);

// Value
String* v8__Value__TypeOf(
    const Value* self,
    Isolate* isolate);
String* v8__Value__ToString(
    const Value* self,
    const Context* ctx);
const String* v8__Value__ToDetailString(
    const Value* self,
    const Context* ctx);
bool v8__Value__BooleanValue(
    const Value* self,
    Isolate* isolate);
void v8__Value__Uint32Value(
    const Value* self,
    const Context* ctx,
    MaybeU32* out);
void v8__Value__Int32Value(
    const Value* self,
    const Context* ctx,
    MaybeI32* out);
void v8__Value__NumberValue(
    const Value* self,
    const Context* context,
    MaybeF64* out);
bool v8__Value__IsFunction(const Value* self);
bool v8__Value__IsAsyncFunction(const Value* self);
bool v8__Value__IsPromise(const Value* self);
bool v8__Value__IsBoolean(const Value* self);
bool v8__Value__IsBooleanObject(const Value* self);
bool v8__Value__IsInt32(const Value* self);
bool v8__Value__IsUint32(const Value* self);
bool v8__Value__IsNumber(const Value* self);
bool v8__Value__IsNumberObject(const Value* self);
bool v8__Value__IsObject(const Value* self);
bool v8__Value__IsString(const Value* self);
bool v8__Value__IsSymbol(const Value* self);
bool v8__Value__IsArray(const Value* self);
bool v8__Value__IsTypedArray(const Value* self);
bool v8__Value__IsUint8ClampedArray(const Value* self);
bool v8__Value__IsInt8Array(const Value* self);
bool v8__Value__IsUint16Array(const Value* self);
bool v8__Value__IsInt16Array(const Value* self);
bool v8__Value__IsUint32Array(const Value* self);
bool v8__Value__IsInt32Array(const Value* self);
bool v8__Value__IsBigInt64Array(const Value* self);
bool v8__Value__IsBigUint64Array(const Value* self);
bool v8__Value__IsFloat32Array(const Value* self);
bool v8__Value__IsFloat64Array(const Value* self);
bool v8__Value__IsArrayBuffer(const Value* self);
bool v8__Value__IsArrayBufferView(const Value* self);
bool v8__Value__IsUint8Array(const Value* self);
bool v8__Value__IsExternal(const Value* self);
bool v8__Value__IsTrue(const Value* self);
bool v8__Value__IsFalse(const Value* self);
bool v8__Value__IsUndefined(const Value* self);
bool v8__Value__IsNull(const Value* self);
bool v8__Value__IsNullOrUndefined(const Value* self);
bool v8__Value__IsNativeError(const Value* self);
bool v8__Value__IsBigInt(const Value* self);
bool v8__Value__IsBigIntObject(const Value* self);
void v8__Value__InstanceOf(
    const Value* self,
    const Context* ctx,
    const Object* object,
    MaybeBool* out);

// Promise
typedef enum PromiseState { kPending, kFulfilled, kRejected } PromiseState;
const PromiseResolver* v8__Promise__Resolver__New(
    const Context* ctx);
const Promise* v8__Promise__Resolver__GetPromise(
    const PromiseResolver* self);
void v8__Promise__Resolver__Resolve(
    const PromiseResolver* self,
    const Context* ctx,
    const Value* value,
    MaybeBool* out);
void v8__Promise__Resolver__Reject(
    const PromiseResolver* self,
    const Context* ctx,
    const Value* value,
    MaybeBool* out);
const Promise* v8__Promise__Catch(
    const Promise* self,
    const Context* ctx,
    const Function* handler);
const Promise* v8__Promise__Then(
    const Promise* self,
    const Context* ctx,
    const Function* handler);
const Promise* v8__Promise__Then2(
    const Promise* self,
    const Context* ctx,
    const Function* on_fulfilled,
    const Function* on_rejected);
PromiseState v8__Promise__State(const Promise* self);
void v8__Promise__MarkAsHandled(const Promise* self);
const Value* v8__Promise__Result(const Promise* self);

// Array
const Array* v8__Array__New(
    Isolate* isolate,
    int length);
const Array* v8__Array__New2(
    Isolate* isolate,
    const Value* const elements[],
    size_t length);
uint32_t v8__Array__Length(const Array* self);

// Object
const Object* v8__Object__New(Isolate* isolate);
const String* v8__Object__GetConstructorName(const Object* self);
int v8__Object__InternalFieldCount(
    const Object* self);
const Data* v8__Object__GetInternalField(
    const Object* self,
    int index);
void v8__Object__SetInternalField(
    const Object* self,
    int index,
    const Value* value);
const Value* v8__Object__Get(
    const Object* self,
    const Context* ctx,
    const Value* key);
const Value* v8__Object__GetIndex(
    const Object* self,
    const Context* ctx,
    uint32_t idx);
void v8__Object__Set(
    const Object* self,
    const Context* ctx,
    const Value* key,
    const Value* value,
    MaybeBool* out);
void v8__Object__Delete(
    const Object* self,
    const Context* ctx,
    const Value* key,
    MaybeBool* out);
void v8__Object__SetAtIndex(
    const Object* self,
    const Context* ctx,
    uint32_t idx,
    const Value* value,
    MaybeBool* out);
void v8__Object__DefineOwnProperty(
    const Object* self,
    const Context* ctx,
    const Name* key,
    const Value* value,
    PropertyAttribute attr,
    MaybeBool* out);
Isolate* v8__Object__GetIsolate(const Object* self);
const Context* v8__Object__GetCreationContext(const Object* self);
int v8__Object__GetIdentityHash(const Object* self);
void v8__Object__Has(
    const Object* self,
    const Context* ctx,
    const Value* key,
    MaybeBool* out);
void v8__Object__HasIndex(
    const Object* self,
    const Context* ctx,
    uint32_t idx,
    MaybeBool* out);
const Array* v8__Object__GetOwnPropertyNames(
    const Object* self,
    const Context* ctx);
const Array* v8__Object__GetPropertyNames(
    const Object* self,
    const Context* ctx);
const Value* v8__Object__GetPrototype(const Object* self);
void v8__Object__SetPrototype(
    const Object* self,
    const Context* ctx,
    const Object* prototype,
    MaybeBool* out);
void v8__Object__SetAlignedPointerInInternalField(
    const Object* self,
    int idx,
    void* ptr);
void* v8__Object__GetAlignedPointerFromInternalField(
    const Object* self,
    int idx);

void v8__Object__HasPrivate(const Object* self, const Context *ctx, const Private* private, MaybeBool* out);
void v8__Object__DeletePrivate(const Object* self, const Context *ctx, const Private* private, MaybeBool* out);
void v8__Object__SetPrivate(const Object* self, const Context *ctx, const Private* private, const Value* value, MaybeBool* out);
const Value* v8__Object__GetPrivate(const Object* self, const Context *ctx, const Private* private);

// RegExp
const RegExp* v8__RegExp__New(
    const Context* ctx,
    const String* pattern,
    int flags);
const RegExp* v8__RegExp__NewWithBacktrackLimit(
    const Context* ctx,
    const String* pattern,
    int flags,
    uint32_t backtrack_limit);
const Object* v8__RegExp__Exec(
    const RegExp* self,
    const Context* ctx,
    const String* subject);

// Exception
const Value* v8__Exception__Error(const String* message);
const Value* v8__Exception__TypeError(const String* message);
const Value* v8__Exception__SyntaxError(const String* message);
const Value* v8__Exception__ReferenceError(const String* message);
const Value* v8__Exception__RangeError(const String* message);
const StackTrace* v8__Exception__GetStackTrace(const Value* exception);
const Message* v8__Exception__CreateMessage(
    Isolate* isolate,
    const Value* exception);

// Number
const Number* v8__Number__New(
    Isolate* isolate,
    double value);

// Integer
const Integer* v8__Integer__New(
    Isolate* isolate,
    int32_t value);
const Integer* v8__Integer__NewFromUnsigned(
    Isolate* isolate,
    uint32_t value);
int64_t v8__Integer__Value(const Integer* self);

// BigInt
const BigInt* v8__BigInt__New(
    Isolate* iso,
    int64_t val);
const BigInt* v8__BigInt__NewFromUnsigned(
    Isolate* iso,
    uint64_t val);
uint64_t v8__BigInt__Uint64Value(
    const BigInt* self,
    bool* lossless);
int64_t v8__BigInt__Int64Value(
    const BigInt* self,
    bool* lossless);

// Template
typedef struct Template Template;
void v8__Template__Set(
    const Template* self,
    const Name* key,
    const Data* value,
    PropertyAttribute attr);
void v8__Template__SetAccessorProperty(
    const Template* self,
    const Name* key,
    const FunctionTemplate* getter,
    const FunctionTemplate* setter,
    PropertyAttribute attribute);

typedef struct PropertyCallbackInfo PropertyCallbackInfo;
typedef void (*AccessorNameGetterCallback)(const Name*, const PropertyCallbackInfo*);
typedef void (*AccessorNameSetterCallback)(const Name*, const Value*, const PropertyCallbackInfo*);
void v8__Template__SetNativeDataProperty__DEFAULT(
    const Template* self,
    const Name* key,
    const AccessorNameGetterCallback* getter);
void v8__Template__SetNativeDataProperty__DEFAULT2(
    const Template* self,
    const Name* key,
    const AccessorNameGetterCallback* getter,
    const AccessorNameSetterCallback* setter);

typedef void (*AccessorNameGetterCallback)(const Name*, const PropertyCallbackInfo*);
typedef void (*AccessorNameSetterCallback)(const Name*, const Value*, const PropertyCallbackInfo*);

// FunctionCallbackInfo
typedef struct FunctionCallbackInfo FunctionCallbackInfo;
typedef struct ReturnValue {
    uintptr_t addr;
} ReturnValue;
Isolate* v8__FunctionCallbackInfo__GetIsolate(
    const FunctionCallbackInfo* self);
int v8__FunctionCallbackInfo__Length(
    const FunctionCallbackInfo* self);
const Value* v8__FunctionCallbackInfo__INDEX(
    const FunctionCallbackInfo* self, int i);
void v8__FunctionCallbackInfo__GetReturnValue(
    const FunctionCallbackInfo* self,
    ReturnValue* res);
const Object* v8__FunctionCallbackInfo__This(
    const FunctionCallbackInfo* self);
const Value* v8__FunctionCallbackInfo__Data(
    const FunctionCallbackInfo* self);
bool v8__FunctionCallbackInfo__IsConstructCall(
    const FunctionCallbackInfo* self);
const Value* v8__FunctionCallbackInfo__NewTarget(
    const FunctionCallbackInfo* self);

// PropertyCallbackInfo
Isolate* v8__PropertyCallbackInfo__GetIsolate(
    const PropertyCallbackInfo* self);
void v8__PropertyCallbackInfo__GetReturnValue(
    const PropertyCallbackInfo* self,
    ReturnValue* res);
const Object* v8__PropertyCallbackInfo__This(
    const PropertyCallbackInfo* self);
const Value* v8__PropertyCallbackInfo__Data(
    const PropertyCallbackInfo* self);

// PromiseRejectMessage
struct PromiseRejectMessage {
    uintptr_t promise;
    PromiseRejectEvent event;
    uintptr_t value;
};
PromiseRejectEvent v8__PromiseRejectMessage__GetEvent(
    const PromiseRejectMessage* self);
const Promise* v8__PromiseRejectMessage__GetPromise(
    const PromiseRejectMessage* self);
const Value* v8__PromiseRejectMessage__GetValue(
    const PromiseRejectMessage* self);
usize v8__PromiseRejectMessage__SIZEOF();

// ReturnValue
void v8__ReturnValue__Set(
    const ReturnValue self,
    const Value* value);
const Value* v8__ReturnValue__Get(
    const ReturnValue self);

// FunctionTemplate
typedef void (*FunctionCallback)(const FunctionCallbackInfo*);

typedef enum SideEffectType {
    kSideEffectType_HasSideEffect = 0,
    kSideEffectType_HasNoSideEffect = 1,
    kSideEffectType_HasSideEffectToReceiver = 2,
} SideEffectType;

typedef enum ConstructorBehavior {
    kConstructorBehavior_Throw = 0,
    kConstructorBehavior_Allow = 1,
} ConstructorBehavior;

typedef struct v8__FunctionTemplateConfig {
    FunctionCallback callback;
    const Value* data;
    const Signature* signature;
    int length;
    ConstructorBehavior behavior;
    SideEffectType side_effect_type;
} v8__FunctionTemplateConfig;

const FunctionTemplate* v8__FunctionTemplate__New__DEFAULT(
    Isolate* isolate);
const FunctionTemplate* v8__FunctionTemplate__New__DEFAULT2(
    Isolate* isolate,
    FunctionCallback callback_or_null);
const FunctionTemplate* v8__FunctionTemplate__New__DEFAULT3(
    Isolate* isolate,
    FunctionCallback callback_or_null,
    const Value* data);
const FunctionTemplate* v8__FunctionTemplate__New__Config(
    Isolate* isolate,
    const v8__FunctionTemplateConfig* config);

// Signature
const Signature* v8__Signature__New(
    Isolate* isolate,
    const FunctionTemplate* receiver);
const ObjectTemplate* v8__FunctionTemplate__InstanceTemplate(
    const FunctionTemplate* self);
const ObjectTemplate* v8__FunctionTemplate__PrototypeTemplate(
    const FunctionTemplate* self);
void v8__FunctionTemplate__Inherit(
    const FunctionTemplate* self,
    const FunctionTemplate* parent);
void v8__FunctionTemplate__SetPrototypeProviderTemplate(
    const FunctionTemplate* self,
    const FunctionTemplate* prototype_provider);
const Function* v8__FunctionTemplate__GetFunction(
    const FunctionTemplate* self, const Context* context);
void v8__FunctionTemplate__SetClassName(
    const FunctionTemplate* self,
    const String* name);
void v8__FunctionTemplate__ReadOnlyPrototype(
    const FunctionTemplate* self);

// Function
const Function* v8__Function__New__DEFAULT(
    const Context* ctx,
    FunctionCallback callback);
const Function* v8__Function__New__DEFAULT2(
    const Context* ctx,
    FunctionCallback callback,
    const Value* data);
const Value* v8__Function__Call(
    const Function* self,
    const Context* context,
    const Value* recv,
    int argc,
    const Value* const argv[]);
const Object* v8__Function__NewInstance(
    const Function* self,
    const Context* context,
    int argc,
    const Value* const argv[]);
const Value* v8__Function__GetName(const Function* self);
void v8__Function__SetName(const Function* self, const String* name);

// External
const External* v8__External__New(
    Isolate* isolate,
    void* value);
void* v8__External__Value(
    const External* self);

// Symbol
const Symbol* v8__Symbol__GetAsyncIterator(Isolate* isolate);
const Symbol* v8__Symbol__GetHasInstance(Isolate* isolate);
const Symbol* v8__Symbol__GetIsConcatSpreadable(Isolate* isolate);
const Symbol* v8__Symbol__GetIterator(Isolate* isolate);
const Symbol* v8__Symbol__GetMatch(Isolate* isolate);
const Symbol* v8__Symbol__GetReplace(Isolate* isolate);
const Symbol* v8__Symbol__GetSearch(Isolate* isolate);
const Symbol* v8__Symbol__GetSplit(Isolate* isolate);
const Symbol* v8__Symbol__GetToPrimitive(Isolate* isolate);
const Symbol* v8__Symbol__GetToStringTag(Isolate* isolate);
const Symbol* v8__Symbol__GetUnscopables(Isolate* isolate);
const Value* v8__Symbol__Description(const Symbol* self, Isolate* isolate);

// Persistent
typedef struct Persistent {
    uintptr_t data_ptr;
} Persistent;
void v8__Persistent__New(
    Isolate* isolate,
    const Data* data,
    Persistent* out);
void v8__Persistent__Reset(
    Persistent* self);
void v8__Persistent__SetWeak(
    Persistent* self);
typedef struct WeakCallbackInfo WeakCallbackInfo;
typedef void (*WeakCallback)(const WeakCallbackInfo*);
typedef enum WeakCallbackType {
    kParameter,
    kInternalFields,
    kFinalizer
} WeakCallbackType;
void v8__Persistent__SetWeakFinalizer(
    Persistent* self,
    void* finalizer_ctx,
    WeakCallback finalizer_cb,
    WeakCallbackType type);

// Global
typedef struct Global {
    uintptr_t data_ptr;
} Global;
void v8__Global__New(
    Isolate* isolate,
    const Data* data,
    Global* out);
void v8__Global__Reset(
    Global* self);
void v8__Global__ClearWeak(
    Global* self);
void v8__Global__SetWeak(
    Global* self);
void v8__Global__SetWeakFinalizer(
    Global* self,
    void* finalizer_ctx,
    WeakCallback finalizer_cb,
    WeakCallbackType type);
const Data* v8__Global__Get(
    const Global* self,
    Isolate* isolate);
bool v8__Global__IsEqual(
    const Global* self,
    const Data*);

// Eternal
typedef struct Eternal {
    uintptr_t data_ptr;
} Eternal;
void v8__Eternal__New(
    Isolate* isolate,
    const Data* data,
    Eternal* out);
const Data* v8__Eternal__Get(
    const Eternal* self,
    Isolate* isolate);

// WeakCallbackInfo
Isolate* v8__WeakCallbackInfo__GetIsolate(const WeakCallbackInfo* self);
void* v8__WeakCallbackInfo__GetParameter(const WeakCallbackInfo* self);
void* v8__WeakCallbackInfo__GetInternalField(
    const WeakCallbackInfo* self,
    int idx);

// ObjectTemplate
typedef struct ObjectTemplate ObjectTemplate;
ObjectTemplate* v8__ObjectTemplate__New__DEFAULT(
    Isolate* isolate);
ObjectTemplate* v8__ObjectTemplate__New(
    Isolate* isolate, const FunctionTemplate* templ);
Object* v8__ObjectTemplate__NewInstance(
    const ObjectTemplate* self, const Context* ctx);
void v8__ObjectTemplate__SetInternalFieldCount(
    const ObjectTemplate* self,
    int value);
typedef struct v8__AccessorPropertyConfig {
    const Name* key;
    const FunctionTemplate* getter;
    const FunctionTemplate* setter;
    PropertyAttribute attribute;
} v8__AccessorPropertyConfig;

void v8__ObjectTemplate__SetAccessorProperty__Config(
    const ObjectTemplate* self,
    const v8__AccessorPropertyConfig* config);
void v8__ObjectTemplate__SetNativeDataProperty__DEFAULT(
    const ObjectTemplate* self,
    const Name* key,
    AccessorNameGetterCallback getter);
void v8__ObjectTemplate__SetNativeDataProperty__DEFAULT2(
    const ObjectTemplate* self,
    const Name* key,
    AccessorNameGetterCallback getter,
    AccessorNameSetterCallback setter);
void v8__ObjectTemplate__MarkAsUndetectable(
    const ObjectTemplate* self);
void v8__ObjectTemplate__SetCallAsFunctionHandler(
    const ObjectTemplate* self,
    FunctionCallback callback_or_null);

typedef bool (*AccessCheckCallback)(const Context* accessing_context,
                                    const Object* accessed_object,
                                    const Value* data);
void v8__ObjectTemplate__SetAccessCheckCallback(
    const ObjectTemplate* self,
    AccessCheckCallback callback,
    const Value* data_or_null);

typedef enum PropertyHandlerFlags {
       kNonMasking = 1,
       kOnlyInterceptStrings = 1 << 1,
       kHasNoSideEffect = 1 << 2,
} PropertyHandlerFlags;

typedef struct PropertyDescriptor {} PropertyDescriptor;
typedef uint8_t (*IndexedPropertyGetterCallback)(uint32_t, const PropertyCallbackInfo*);
typedef uint8_t (*IndexedPropertySetterCallback)(uint32_t, const Value*, const PropertyCallbackInfo*);
typedef uint8_t (*IndexedPropertyQueryCallback)(uint32_t, const PropertyCallbackInfo*);
typedef uint8_t (*IndexedPropertyDeleterCallback)(uint32_t, const PropertyCallbackInfo*);
typedef uint8_t (*IndexedPropertyEnumeratorCallback)(const PropertyCallbackInfo*);
typedef void (*IndexedPropertyDefinerCallback)(uint32_t, PropertyDescriptor* desc, const PropertyCallbackInfo*);
typedef void (*IndexedPropertyDescriptorCallback)(uint32_t, const PropertyCallbackInfo*);
typedef struct IndexedPropertyHandlerConfiguration {
    IndexedPropertyGetterCallback getter;
    IndexedPropertySetterCallback setter;
    IndexedPropertyQueryCallback query;
    IndexedPropertyDeleterCallback deleter;
    IndexedPropertyEnumeratorCallback enumerator;
    IndexedPropertyDefinerCallback definer;
    IndexedPropertyDescriptorCallback descriptor;
    const Value* data;
    PropertyHandlerFlags flags;
} IndexedPropertyHandlerConfiguration;
void v8__ObjectTemplate__SetIndexedHandler(
    const ObjectTemplate* self,
    const IndexedPropertyHandlerConfiguration* configuration);

typedef uint8_t (*NamedPropertyGetterCallback)(const Name*, const PropertyCallbackInfo*);
typedef uint8_t (*NamedPropertySetterCallback)(const Name*, const Value*, const PropertyCallbackInfo*);
typedef uint8_t (*NamedPropertyQueryCallback)(const Name*, const PropertyCallbackInfo*);
typedef uint8_t (*NamedPropertyDeleterCallback)(const Name*, const PropertyCallbackInfo*);
typedef uint8_t (*NamedPropertyEnumeratorCallback)(const PropertyCallbackInfo*);
typedef void (*NamedPropertyDefinerCallback)(const Name*, PropertyDescriptor* desc, const PropertyCallbackInfo*);
typedef void (*NamedPropertyDescriptorCallback)(const Name*, const PropertyCallbackInfo*);
typedef struct NamedPropertyHandlerConfiguration {
    NamedPropertyGetterCallback getter;
    NamedPropertySetterCallback setter;
    NamedPropertyQueryCallback query;
    NamedPropertyDeleterCallback deleter;
    NamedPropertyEnumeratorCallback enumerator;
    NamedPropertyDefinerCallback definer;
    NamedPropertyDescriptorCallback descriptor;
    const Value* data;
    PropertyHandlerFlags flags;
} NamedPropertyHandlerConfiguration;
void v8__ObjectTemplate__SetNamedHandler(
    const ObjectTemplate* self,
    const NamedPropertyHandlerConfiguration* configuration);

// ScriptOrigin
typedef struct ScriptOriginOptions {
    const int flags_;
} ScriptOriginOptions;
typedef struct ScriptOrigin {
    Value* resource_name_;
    int resource_line_offset_;
    int resource_column_offset_;
    ScriptOriginOptions options_;
    int script_id_;
    Value* source_map_url_;
    void* host_defined_options_;
} ScriptOrigin;
void v8__ScriptOrigin__CONSTRUCT(ScriptOrigin* buf, const Value* resource_name);
void v8__ScriptOrigin__CONSTRUCT2(
    ScriptOrigin* buf,
    const Value* resource_name,
    int resource_line_offset,
    int resource_column_offset,
    bool resource_is_shared_cross_origin,
    int script_id,
    const Value* source_map_url,
    bool resource_is_opaque,
    bool is_wasm,
    bool is_module,
    const Data* host_defined_options
);

usize v8__ScriptCompiler__CompilationDetails__SIZEOF();
typedef struct CompilationDetails {
    //  this is an enum, but should get padded to an int64_t
    int64_t in_memory_cache_result;
    int64_t foreground_time_in_microseconds;
    int64_t background_time_in_microseconds;
} CompilationDetails;

typedef bool (*CompileHintCallback)(int, void*);

// ScriptCompiler
typedef struct ScriptCompilerSource {
    String* source_string;

    // Origin information
    Value* resource_name;
    int resource_line_offset;
    int resource_column_offset;
    ScriptOriginOptions resource_options;
    Value* source_map_url;
    Data* host_defined_options;

    // Cached data from previous compilation (if a kConsume*Cache flag is
    // set), or hold newly generated cache data (kProduce*Cache flags) are
    // set when calling a compile method.
    UniquePtr cached_data;
    UniquePtr consume_cache_task;

    CompileHintCallback compile_hint_callback;
    void* compile_hint_callback_data;
    CompilationDetails compilation_details

} ScriptCompilerSource;
typedef enum BufferPolicy {
    BufferNotOwned,
    BufferOwned
} BufferPolicy;
typedef struct ScriptCompilerCachedData {
    const uint8_t* data;
    int length;
    bool rejected;
    BufferPolicy buffer_policy;
} ScriptCompilerCachedData;
size_t v8__ScriptCompiler__Source__SIZEOF();
void v8__ScriptCompiler__Source__CONSTRUCT(
    const String* src,
    ScriptCompilerCachedData* cached_data,
    ScriptCompilerSource* out);
void v8__ScriptCompiler__Source__CONSTRUCT2(
    const String* src,
    const ScriptOrigin* origin,
    ScriptCompilerCachedData* cached_data,
    ScriptCompilerSource* out);
void v8__ScriptCompiler__Source__DESTRUCT(ScriptCompilerSource* self);
size_t v8__ScriptCompiler__CachedData__SIZEOF();
ScriptCompilerCachedData* v8__ScriptCompiler__CachedData__NEW(
    const uint8_t* data,
    int length);
void v8__ScriptCompiler__CachedData__DELETE(ScriptCompilerCachedData* self);
const Module* v8__ScriptCompiler__CompileModule(
    Isolate* isolate,
    ScriptCompilerSource* source,
    CompileOptions options,
    NoCacheReason reason);

// Script
typedef struct Script Script;
typedef struct Data UnboundScript;
Script* v8__Script__Compile(const Context* context, const String* src, const ScriptOrigin* origin);
Value* v8__Script__Run(const Script* script, const Context* context);

// A context-independent compiled script. Obtained from a bound Script and
// re-bound to a context (possibly a different one, on the same isolate) to run
// again, or serialized into a ScriptCompilerCachedData blob.
const UnboundScript* v8__Script__GetUnboundScript(const Script* script);
Script* v8__UnboundScript__BindToCurrentContext(const UnboundScript* unbound);

// Serializes an UnboundScript into a code cache. The returned CachedData owns
// its buffer (BufferOwned) and must be released with
// v8__ScriptCompiler__CachedData__DELETE after the bytes have been copied out.
ScriptCompilerCachedData* v8__ScriptCompiler__CreateCodeCache(const UnboundScript* unbound);

// Module
typedef enum ModuleStatus {
    kUninstantiated,
    kInstantiating,
    kInstantiated,
    kEvaluating,
    kEvaluated,
    kErrored
} ModuleStatus;
ModuleStatus v8__Module__GetStatus(const Module* self);
const Value* v8__Module__GetException(const Module* self);
const FixedArray* v8__Module__GetModuleRequests(const Module* self);
typedef const Module* (*ResolveModuleCallback)(
    const Context* ctx, const String* spec,
    const FixedArray* import_assertions, const Module* referrer);
void v8__Module__InstantiateModule(
    const Module* self,
    const Context* ctx,
    ResolveModuleCallback cb,
    MaybeBool* out);
const Value* v8__Module__Evaluate(const Module* self, const Context* ctx);
int v8__Module__GetIdentityHash(const Module* self);
Value* v8__Module__GetModuleNamespace(const Module* self);
int v8__Module__ScriptId(const Module* self);

Script* v8__ScriptCompiler__Compile(
        const Context* context,
        ScriptCompilerSource* source,
        CompileOptions options,
        NoCacheReason reason);
Function* v8__ScriptCompiler__CompileFunction(
        const Context* context,
        ScriptCompilerSource* source,
        size_t arguments_count,
        const String* const arguments[],
        size_t context_extension_count,
        const Object* const context_extensions[],
        CompileOptions options,
        NoCacheReason reason);

// ModuleRequest
typedef Data ModuleRequest;
const String* v8__ModuleRequest__GetSpecifier(const ModuleRequest* self);
int v8__ModuleRequest__GetSourceOffset(const ModuleRequest* self);

// JSON
const Value* v8__JSON__Parse(
    const Context* ctx,
    const String* json);
const String* v8__JSON__Stringify(
    const Context* ctx,
    const Value* val,
    const String* gap);

// Misc.
void v8__base__SetDcheckFunction(void (*func)(const char*, int, const char*));

// Utils

typedef struct {
    const char *ptr;
    uint64_t len;
} CZigString;

// CpuProfiler
// -----------

typedef struct CpuProfiler CpuProfiler;
typedef struct CpuProfile CpuProfile;
typedef struct CpuProfileNode CpuProfileNode;

CpuProfiler* v8__CpuProfiler__Get(Isolate* isolate);
void v8__CpuProfiler__StartProfiling(CpuProfiler* self, const String* title);
const CpuProfile* v8__CpuProfiler__StopProfiling(CpuProfiler* self, const String* title);
void v8__CpuProfiler__UseDetailedSourcePositionsForProfiling(Isolate* isolate);
void v8__CpuProfile__Delete(const CpuProfile* self);
const CpuProfileNode* v8__CpuProfile__GetTopDownRoot(const CpuProfile* self);
const String* v8__CpuProfile__Serialize(const CpuProfile* self, Isolate* isolate);

// HeapProfiler
// ------------

typedef struct HeapProfiler HeapProfiler;
typedef struct HeapSnapshot HeapSnapshot;
typedef struct AllocationProfile AllocationProfile;
typedef void (*ActivityControlCallback)(int, int);

HeapProfiler* v8__HeapProfiler__Get(Isolate* isolate);
const HeapSnapshot* v8__HeapProfiler__TakeHeapSnapshot(HeapProfiler* self, ActivityControlCallback callback);
void v8__HeapProfiler__StartTrackingHeapObjects(HeapProfiler* self, bool track_allocations);
void v8__HeapProfiler__StopTrackingHeapObjects(HeapProfiler* self);
void v8__HeapProfiler__StartSamplingHeapProfiler(HeapProfiler* self, uint64_t sample_interval, int stack_depth);
void v8__HeapProfiler__StopSamplingHeapProfiler(HeapProfiler* self);
AllocationProfile* v8__HeapProfiler__GetAllocationProfile(HeapProfiler* self);
const String* v8__HeapProfiler__GetHeapStats(HeapProfiler* self, Isolate* isolate);
void v8__HeapProfiler__DeleteAllHeapSnapshots(HeapProfiler* self);
int v8__HeapProfiler__GetSnapshotCount(HeapProfiler* self);
const HeapSnapshot* v8__HeapProfiler__GetHeapSnapshot(HeapProfiler* self, int index);
void v8__HeapSnapshot__Delete(const HeapSnapshot* self);
const String* v8__HeapSnapshot__Serialize(const HeapSnapshot* self, Isolate* isolate);
void v8__AllocationProfile__Delete(AllocationProfile* self);
const String* v8__AllocationProfile__Serialize(AllocationProfile* self, Isolate* isolate);

// Inspector
// ---------

typedef enum ClientTrustLevel {
  kUntrusted,
  kFullyTrusted,
} ClientTrustLevel;

typedef struct StringView StringView;

// InspectorChannel

typedef struct InspectorChannel InspectorChannel;
typedef struct InspectorChannelImpl {
  void* data;
} InspectorChannelImpl;
InspectorChannelImpl *v8_inspector__Channel__IMPL__CREATE(Isolate *isolate);
void v8_inspector__Channel__IMPL__DELETE(InspectorChannelImpl *self);
void v8_inspector__Channel__IMPL__SET_DATA(InspectorChannelImpl* self, void *data);

void v8_inspector__Channel__IMPL__sendResponse(
    InspectorChannelImpl *self, void *data,
    int callId, char *message, size_t length);
void v8_inspector__Channel__IMPL__sendNotification(
    InspectorChannelImpl *self, void *data,
    char *message, size_t length);
void v8_inspector__Channel__IMPL__flushProtocolNotifications(
    InspectorChannelImpl *self, void *data);

// InspectorClient

typedef struct InspectorClient InspectorClient;
typedef struct InspectorClientImpl {
  void* data;
} InspectorClientImpl;
InspectorClientImpl *v8_inspector__Client__IMPL__CREATE();
void v8_inspector__Client__IMPL__DELETE(InspectorClientImpl *self);
void v8_inspector__Client__IMPL__SET_DATA(InspectorClientImpl* self, void *data);

int64_t v8_inspector__Client__IMPL__generateUniqueId(InspectorClientImpl *self);
void v8_inspector__Client__IMPL__runMessageLoopOnPause(
    InspectorClientImpl *self, int contextGroupId);
void v8_inspector__Client__IMPL__quitMessageLoopOnPause(
    InspectorClientImpl *self);
void v8_inspector__Client__IMPL__runIfWaitingForDebugger(
    InspectorClientImpl *self, int contextGroupId);
void v8_inspector__Client__IMPL__consoleAPIMessage(
    InspectorClientImpl *self, int contextGroupId, MessageErrorLevel level,
    StringView *message, StringView *url, unsigned lineNumber,
    unsigned columnNumber, StackTrace *StackTrace);
const Context* v8_inspector__Client__IMPL__ensureDefaultContextInGroup(
    InspectorClientImpl* self, void* data, int contextGroupId);
char* v8_inspector__Client__IMPL__valueSubtype(
    InspectorClientImpl* self, Value value);
char* v8_inspector__Client__IMPL__descriptionForValueSubtype(
    InspectorClientImpl* self, Context context, Value value);


// RemoteObject
typedef struct RemoteObject RemoteObject;
typedef struct WebDriverValue WebDriverValue;
typedef struct ObjectPreview ObjectPreview;
typedef struct CustomPreview CustomPreview;

// InspectorSession

typedef struct InspectorSession InspectorSession;
void v8_inspector__Session__DELETE(InspectorSession *self);
void v8_inspector__Session__stop(InspectorSession *session);
void v8_inspector__Session__resume(InspectorSession *session);
void v8_inspector__Session__dispatchProtocolMessage(InspectorSession *session, Isolate *isolate, const char* msg, usize msg_len);
RemoteObject* v8_inspector__Session__wrapObject(
    InspectorSession *session, Isolate *isolate,
    const Context* ctx, const Value* val,
    const char *grpname, usize grpname_len, bool generatepreview);

bool v8_inspector__Session__unwrapObject(
    InspectorSession *session,
    const void* allocator,
    CZigString* out_error,
    CZigString in_objectId,
    Value** out_value,
    Context** out_context,
    CZigString* out_objectGroup
);

// Inspector
typedef struct Inspector Inspector;
Inspector* v8_inspector__Inspector__Create(Isolate* isolate, InspectorClientImpl* client);
void v8_inspector__Inspector__DELETE(Inspector *self);

InspectorSession* v8_inspector__Inspector__Connect(
    Inspector *self, int contextGroupId,
    InspectorChannelImpl *channel,
    ClientTrustLevel level);
void v8_inspector__Inspector__ContextCreated(Inspector *self, const char *name,
                                             usize name_len, const char *origin,
                                             usize origin_len,
                                             const char *auxData, const usize auxData_len,
                                             int contextGroupId,
    const Context* context);

void v8_inspector__Inspector__ContextDestroyed(Inspector *self, const Context *ctx);

void v8_inspector__Inspector__ResetContextGroup(Inspector *self, int contextGroupId);

int v8__inspector__executionContextId(const Context* context);

// RemoteObject
void v8_inspector__RemoteObject__DELETE(RemoteObject *self);

// RemoteObject - Type
bool v8_inspector__RemoteObject__getType(RemoteObject* self, const void* allocator, CZigString* out_type);
void v8_inspector__RemoteObject__setType(RemoteObject* self, CZigString type);

// RemoteObject - Subtype
bool v8_inspector__RemoteObject__hasSubtype(RemoteObject* self);
bool v8_inspector__RemoteObject__getSubtype(RemoteObject* self, const void* allocator, CZigString* out_subtype);
void v8_inspector__RemoteObject__setSubtype(RemoteObject* self, CZigString subtype);

// RemoteObject - ClassName
bool v8_inspector__RemoteObject__hasClassName(RemoteObject* self);
bool v8_inspector__RemoteObject__getClassName(RemoteObject* self, const void* allocator, CZigString* out_className);
void v8_inspector__RemoteObject__setClassName(RemoteObject* self, CZigString className);

// RemoteObject - Value
bool v8_inspector__RemoteObject__hasValue(RemoteObject* self);
// Commented as these for now as the type should likely be the existing Value TBD
// v8_inspector::protocol::Value* v8_inspector__RemoteObject__getValue(Rem;eObject* self);
// void v8_inspector__RemoteObject__setValue(RemoteObject* self, v8_inspector::protocol::Value* value);

//RemoteObject - UnserializableValue
bool v8_inspector__RemoteObject__hasUnserializableValue(RemoteObject* self);
bool v8_inspector__RemoteObject__getUnserializableValue(RemoteObject* self, const void* allocator, CZigString* out_unserializableValue);
void v8_inspector__RemoteObject__setUnserializableValue(RemoteObject* self, CZigString unserializableValue);

// RemoteObject - Description
bool v8_inspector__RemoteObject__hasDescription(RemoteObject* self);
bool v8_inspector__RemoteObject__getDescription(RemoteObject* self, const void* allocator, CZigString* out_description);
void v8_inspector__RemoteObject__setDescription(RemoteObject* self, CZigString description);

// RemoteObject - WebDriverValue
bool v8_inspector__RemoteObject__hasWebDriverValue(RemoteObject* self);
WebDriverValue* v8_inspector__RemoteObject__getWebDriverValue(RemoteObject* self);
void v8_inspector__RemoteObject__setWebDriverValue(RemoteObject* self, WebDriverValue* webDriverValue);

// RemoteObject - ObjectId
bool v8_inspector__RemoteObject__hasObjectId(RemoteObject* self);
bool v8_inspector__RemoteObject__getObjectId(RemoteObject* self, const void* allocator, CZigString* out_objectId);
void v8_inspector__RemoteObject__setObjectId(RemoteObject* self, CZigString objectId);

// RemoteObject - Preview
bool v8_inspector__RemoteObject__hasPreview(RemoteObject* self);
const ObjectPreview* v8_inspector__RemoteObject__getPreview(RemoteObject* self);
void v8_inspector__RemoteObject__setPreview(RemoteObject* self, ObjectPreview* preview);

// RemoteObject - CustomPreview
bool v8_inspector__RemoteObject__hasCustomPreview(RemoteObject* self);
const CustomPreview* v8_inspector__RemoteObject__getCustomPreview(RemoteObject* self);
void v8_inspector__RemoteObject__setCustomPreview(RemoteObject* self, CustomPreview* customPreview);

// SnapshotCreator
typedef struct SnapshotCreator SnapshotCreator;

SnapshotCreator* v8__SnapshotCreator__CREATE(const CreateParams*);
Isolate* v8__SnapshotCreator__getIsolate(SnapshotCreator*);
void v8__SnapshotCreator__setDefaultContext(SnapshotCreator*, const Context*);
size_t v8__SnapshotCreator__AddContext(SnapshotCreator*, const Context*);
size_t v8__SnapshotCreator__AddData(SnapshotCreator*, const Data* data);
size_t v8__SnapshotCreator__AddData2(SnapshotCreator*, const Context* ctx, const Data* data);
StartupData v8__SnapshotCreator__createBlob(SnapshotCreator*, FunctionCodeHandling);
void v8__SnapshotCreator__DESTRUCT(SnapshotCreator*);
bool v8__StartupData__IsValid(StartupData);
void v8__StartupData__DELETE(const char* data);

// Private
Private* v8__Private__New(Isolate* isolate, const String* key);

// ValueSerializer
// ---------------
// Used for structured cloning (e.g., structuredClone, postMessage)

typedef struct ValueSerializer ValueSerializer;

// Delegate callbacks for ValueSerializer
typedef void (*ValueSerializerThrowDataCloneErrorCallback)(void* data, const String* message);
typedef MaybeBool (*ValueSerializerWriteHostObjectCallback)(void* data, Isolate* isolate, const Object* object);
typedef bool (*ValueSerializerGetSharedArrayBufferIdCallback)(void* data, Isolate* isolate, const SharedArrayBuffer* sab, uint32_t* id_out);

typedef struct ValueSerializerDelegateCallbacks {
    void* data;
    ValueSerializerThrowDataCloneErrorCallback throw_data_clone_error;
    ValueSerializerWriteHostObjectCallback write_host_object;
    ValueSerializerGetSharedArrayBufferIdCallback get_shared_array_buffer_id;
} ValueSerializerDelegateCallbacks;

ValueSerializer* v8__ValueSerializer__New(Isolate* isolate, const ValueSerializerDelegateCallbacks* callbacks);
void v8__ValueSerializer__DELETE(ValueSerializer* self);
void v8__ValueSerializer__WriteHeader(ValueSerializer* self);
void v8__ValueSerializer__WriteValue(ValueSerializer* self, const Context* ctx, const Value* value, MaybeBool* out);
// Returns ownership of the buffer - caller must free with v8__ValueSerializer__FreeBuffer
uint8_t* v8__ValueSerializer__Release(ValueSerializer* self, size_t* size_out);
void v8__ValueSerializer__FreeBuffer(uint8_t* buffer);
void v8__ValueSerializer__TransferArrayBuffer(ValueSerializer* self, uint32_t transfer_id, const ArrayBuffer* array_buffer);
void v8__ValueSerializer__WriteUint32(ValueSerializer* self, uint32_t value);
void v8__ValueSerializer__WriteUint64(ValueSerializer* self, uint64_t value);
void v8__ValueSerializer__WriteDouble(ValueSerializer* self, double value);
void v8__ValueSerializer__WriteRawBytes(ValueSerializer* self, const void* source, size_t length);

// ValueDeserializer
// -----------------

typedef struct ValueDeserializer ValueDeserializer;

// Delegate callbacks for ValueDeserializer
typedef const Object* (*ValueDeserializerReadHostObjectCallback)(void* data, Isolate* isolate);
typedef const SharedArrayBuffer* (*ValueDeserializerGetSharedArrayBufferFromIdCallback)(void* data, Isolate* isolate, uint32_t id);

typedef struct ValueDeserializerDelegateCallbacks {
    void* data;
    ValueDeserializerReadHostObjectCallback read_host_object;
    ValueDeserializerGetSharedArrayBufferFromIdCallback get_shared_array_buffer_from_id;
} ValueDeserializerDelegateCallbacks;

ValueDeserializer* v8__ValueDeserializer__New(Isolate* isolate, const uint8_t* data, size_t size, const ValueDeserializerDelegateCallbacks* callbacks);
void v8__ValueDeserializer__DELETE(ValueDeserializer* self);
void v8__ValueDeserializer__ReadHeader(ValueDeserializer* self, const Context* ctx, MaybeBool* out);
const Value* v8__ValueDeserializer__ReadValue(ValueDeserializer* self, const Context* ctx);
void v8__ValueDeserializer__TransferArrayBuffer(ValueDeserializer* self, uint32_t transfer_id, const ArrayBuffer* array_buffer);
bool v8__ValueDeserializer__ReadUint32(ValueDeserializer* self, uint32_t* out);
bool v8__ValueDeserializer__ReadUint64(ValueDeserializer* self, uint64_t* out);
bool v8__ValueDeserializer__ReadDouble(ValueDeserializer* self, double* out);
bool v8__ValueDeserializer__ReadRawBytes(ValueDeserializer* self, size_t length, const void** out);
