#ifndef RUNNER_WINDOW_FILE_DROP_H_
#define RUNNER_WINDOW_FILE_DROP_H_

#include <flutter/flutter_engine.h>
#include <memory>

class WindowFileDrop {
 public:
  explicit WindowFileDrop(flutter::FlutterEngine* engine);
  ~WindowFileDrop();
  WindowFileDrop(const WindowFileDrop&) = delete;
  WindowFileDrop& operator=(const WindowFileDrop&) = delete;

 private:
  class Impl;
  std::unique_ptr<Impl> impl_;
};

#endif
