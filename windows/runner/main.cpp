#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <psapi.h>

#include "flutter_window.h"
#include "utils.h"

// Helper function: Get the file path of a process
std::wstring GetProcessPath(DWORD processId) {
  HANDLE hProcess = OpenProcess(PROCESS_QUERY_INFORMATION |
                                   PROCESS_VM_READ,
                                   FALSE, processId);
  if (hProcess == NULL)
    return L"";

  wchar_t path[MAX_PATH];
  DWORD size = MAX_PATH;

  // Try to get the full image name
  if (QueryFullProcessImageName(hProcess, 0, path, &size)) {
    CloseHandle(hProcess);
    return std::wstring(path);
  }

  CloseHandle(hProcess);
  return L"";
}

// Structure to pass data to the callback function
struct EnumData {
    DWORD currentPid;
    std::wstring currentPath;
    HWND foundHwnd;
};

// Callback function for EnumWindows
BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
  EnumData* data = reinterpret_cast<EnumData*>(lParam);

  // Get process ID of the window
  DWORD windowPid = 0;
  GetWindowThreadProcessId(hwnd, &windowPid);

  // Skip if it's the current new process itself
  if (windowPid == data->currentPid) {
    return TRUE; // Continue enumeration
  }

  // Get the file path of that window's process
  std::wstring windowPath = GetProcessPath(windowPid);

  // Check if the path matches our app's path
  if (!windowPath.empty() && windowPath == data->currentPath) {
    // Optional: Check if it is a Flutter window class
    wchar_t className[256];
    if (GetClassName(hwnd, className, 256) > 0) {
      if (std::wstring(className) == L"FLUTTER_RUNNER_WIN32_WINDOW") {
        data->foundHwnd = hwnd;
        return FALSE; //Found it, Stop searching.
      }
    }
  }

  return TRUE; // Continue searching
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // --- SINGLE INSTANCE LOGIC START ---

  // Create a unique Mutex name
  const std::wstring kMutexName = L"Local\\com.devode.lite_view_mutex";
  HANDLE hMutex = CreateMutex(NULL, FALSE, kMutexName.c_str());

  // Check if another instance is already running
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    EnumData data;
    data.currentPid = GetCurrentProcessId();
    data.foundHwnd = NULL;

    // Get current app path
    wchar_t selfPath[MAX_PATH];
    GetModuleFileName(NULL, selfPath, MAX_PATH);
    data.currentPath = std::wstring(selfPath);

    // Search for the old window
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&data));

    if (data.foundHwnd != NULL) {
      // Activate the old window
      if (IsIconic(data.foundHwnd)) {
        ShowWindow(data.foundHwnd, SW_RESTORE); // Restore if minimized
      }
      SetForegroundWindow(data.foundHwnd);                // Bring to front
      SetFocus(data.foundHwnd);                           // Focus
    }

    // Exit this new instance immediately
    return 0;
  }
  // --- SINGLE INSTANCE LOGIC END ---

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"lite_view", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();

  // Release mutex handle
  ReleaseMutex(hMutex);
  CloseHandle(hMutex);

  return EXIT_SUCCESS;
}
