#include <flutter/dart_project.h>
#include <flutter/flutter_engine.h>
#include <flutter/generated_plugin_registrant.h>

#include "utils.h"
#include "window_file_drop.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(GetCommandLineArguments());

  // The Flutter engine is shared by every native window. Dart's
  // WindowManager creates the launcher and workspace windows.
  auto const engine{std::make_shared<flutter::FlutterEngine>(project)};
  RegisterPlugins(engine.get());
  auto window_file_drop = std::make_unique<WindowFileDrop>(engine.get());
  engine->Run();

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  window_file_drop.reset();
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
