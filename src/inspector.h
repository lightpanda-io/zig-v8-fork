#include "include/v8-inspector.h"

#ifndef V8INSPECTORIMPL_H
#define V8INSPECTORIMPL_H

// InspectorChannel Implementation
struct v8_inspector__Channel__IMPL
  : public v8_inspector::V8Inspector::Channel {
  using v8_inspector::V8Inspector::Channel::Channel;

public:
  v8::Isolate *isolate;  
  void *data;

private:  
  void sendResponse(int callId,
		    std::unique_ptr<v8_inspector::StringBuffer> message) override;
  void sendNotification(std::unique_ptr<v8_inspector::StringBuffer> message) override;
  void flushProtocolNotifications() override;
};

// InspectorClient Implementation
class v8_inspector__Client__IMPL
  : public v8_inspector::V8InspectorClient {
  using v8_inspector::V8InspectorClient::V8InspectorClient;

public:
  void *data;

private:
  int64_t generateUniqueId() override;
  void runMessageLoopOnPause(int contextGroupId) override;
  void quitMessageLoopOnPause() override;
  void runIfWaitingForDebugger(int contextGroupId) override;
  void consoleAPIMessage(int contextGroupId,
                         v8::Isolate::MessageErrorLevel level,
                         const v8_inspector::StringView& message,
                         const v8_inspector::StringView& url,
                         unsigned lineNumber, unsigned columnNumber,
                         v8_inspector::V8StackTrace* stackTrace) override;
};

#endif // V8INSPECTORIMPL_H
