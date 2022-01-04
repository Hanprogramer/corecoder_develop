#include "flutter_window.h"
#include <iostream>
#include <optional>

#include <windows.h> 
#include <tchar.h>
#include <stdio.h> 
#include <strsafe.h>

#include <shobjidl.h>

#include <cassert>
#include <memory>
#include <string>
#include <vector>


#define BUFSIZE 4096 

HANDLE g_hChildStd_IN_Rd = NULL;
HANDLE g_hChildStd_IN_Wr = NULL;
HANDLE g_hChildStd_OUT_Rd = NULL;
HANDLE g_hChildStd_OUT_Wr = NULL;

HANDLE g_hInputFile = NULL;

#include "flutter/generated_plugin_registrant.h"
using namespace std;

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

FlutterWindow::FlutterWindow(const flutter::DartProject& project, std::string run_args)
    : project_(project), run_argument(run_args) {}

FlutterWindow::~FlutterWindow() {}
bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  initMethodChannel(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

// Looks for |key| in |map|, returning the associated value if it is present, or
// a nullptr if not.
const EncodableValue* ValueOrNull(const EncodableMap& map, const char* key) {
    auto it = map.find(EncodableValue(key));
    if (it == map.end()) {
        return nullptr;
    }
    return &(it->second);
}

void FlutterWindow::initMethodChannel(flutter::FlutterEngine* flutter_instance) {
    // name your channel
    const static std::string channel_name("corecoder_develop");

    auto channel =
        std::make_unique<flutter::MethodChannel<>>(
            flutter_instance->messenger(), channel_name,
            &flutter::StandardMethodCodec::GetInstance());
    //channel->InvokeMethod
    channel->SetMethodCallHandler(
        [this](const flutter::MethodCall<>& call,
            std::unique_ptr<flutter::MethodResult<>> result) {

                // cheack method name called from dart
                if (call.method_name().compare("getRunArgs") == 0) {
                    // do whate ever you want
                    result->Success(EncodableValue(run_argument.c_str()));
                }
                else if (call.method_name().compare("startThreadAndPipeOutput") == 0) {

                    const auto* arguments =
                        std::get_if<flutter::EncodableMap>(call.arguments());
                    const EncodableMap& args = *arguments;

                    const auto* proc_name =
                        std::get_if<std::string>(ValueOrNull(args, "procName"));
                    const auto* working_directory =
                        std::get_if<std::string>(ValueOrNull(args, "workingDirectory"));
                    
                    CreateChildProcess((*proc_name).c_str(), {}, working_directory->c_str());
                    assert(arguments);
                    // do whate ever you want
                    result->Success(EncodableValue("Run thread successful"));
                }
                else {
                    result->NotImplemented();
                }
        });
}


string internetprotocol = "127.4.5.6";
wchar_t* convertCharArrayToLPCWSTR2(const char* charArray)
{
    wchar_t* wString = new wchar_t[4096];
    MultiByteToWideChar(CP_ACP, 0, charArray, -1, wString, 4096);
    return wString;
}
void FlutterWindow::CreateChildProcess(std::string cmd, std::string args[], std::string working_directory)
// Create a child process that uses the previously created pipes for STDIN and STDOUT.
{
    //const TCHAR* szCmdline = (const TCHAR*)cmd.c_str();
    PROCESS_INFORMATION piProcInfo;
    STARTUPINFO siStartInfo;
    BOOL bSuccess = FALSE;

    // Set up members of the PROCESS_INFORMATION structure. 

    ZeroMemory(&piProcInfo, sizeof(PROCESS_INFORMATION));

    // Set up members of the STARTUPINFO structure. 
    // This structure specifies the STDIN and STDOUT handles for redirection.

    ZeroMemory(&siStartInfo, sizeof(STARTUPINFO));
    siStartInfo.cb = sizeof(STARTUPINFO);
    siStartInfo.hStdError = g_hChildStd_OUT_Wr;
    siStartInfo.hStdOutput = g_hChildStd_OUT_Wr;
    siStartInfo.hStdInput = g_hChildStd_IN_Rd;
    siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

    // Create the child process. 

    bSuccess = CreateProcess(NULL,
        convertCharArrayToLPCWSTR2(cmd.c_str()),     // command line 
        NULL,          // process security attributes 
        NULL,          // primary thread security attributes 
        TRUE,          // handles are inherited 
        0,             // creation flags 
        NULL,          // use parent's environment 
        convertCharArrayToLPCWSTR2(working_directory.c_str()),          // use parent's current directory 
        &siStartInfo,  // STARTUPINFO pointer 
        &piProcInfo);  // receives PROCESS_INFORMATION 

     // If an error occurs, exit the application. 
    if (!bSuccess)
        ErrorExit(TEXT("CreateProcess"));
    else
    {
        // Close handles to the child process and its primary thread.
        // Some applications might keep these handles to monitor the status
        // of the child process, for example. 

        CloseHandle(piProcInfo.hProcess);
        CloseHandle(piProcInfo.hThread);

        // Close handles to the stdin and stdout pipes no longer needed by the child process.
        // If they are not explicitly closed, there is no way to recognize that the child process has ended.

        CloseHandle(g_hChildStd_OUT_Wr);
        CloseHandle(g_hChildStd_IN_Rd);
    }
}

void FlutterWindow::WriteToPipe(void)

// Read from a file and write its contents to the pipe for the child's STDIN.
// Stop when there is no more data. 
{
    DWORD dwRead, dwWritten;
    CHAR chBuf[BUFSIZE];
    BOOL bSuccess = FALSE;

    for (;;)
    {
        bSuccess = ReadFile(g_hInputFile, chBuf, BUFSIZE, &dwRead, NULL);
        if (!bSuccess || dwRead == 0) break;

        bSuccess = WriteFile(g_hChildStd_IN_Wr, chBuf, dwRead, &dwWritten, NULL);
        if (!bSuccess) break;
    }

    // Close the pipe handle so the child process stops reading. 

    if (!CloseHandle(g_hChildStd_IN_Wr))
        ErrorExit(TEXT("StdInWr CloseHandle"));
}

void FlutterWindow::ReadFromPipe(void)

// Read output from the child process's pipe for STDOUT
// and write to the parent process's pipe for STDOUT. 
// Stop when there is no more data. 
{
    DWORD dwRead, dwWritten;
    CHAR chBuf[BUFSIZE];
    BOOL bSuccess = FALSE;
    HANDLE hParentStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

    for (;;)
    {
        bSuccess = ReadFile(g_hChildStd_OUT_Rd, chBuf, BUFSIZE, &dwRead, NULL);
        if (!bSuccess || dwRead == 0) break;

        bSuccess = WriteFile(hParentStdOut, chBuf,
            dwRead, &dwWritten, NULL);
        if (!bSuccess) break;
    }
}

void FlutterWindow::ErrorExit(PTSTR lpszFunction)

// Format a readable error message, display a message box, 
// and exit from the application.
{
    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;
    DWORD dw = GetLastError();

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR)&lpMsgBuf,
        0, NULL);

    lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT,
        (lstrlen((LPCTSTR)lpMsgBuf) + lstrlen((LPCTSTR)lpszFunction) + 40) * sizeof(TCHAR));
    StringCchPrintf((LPTSTR)lpDisplayBuf,
        LocalSize(lpDisplayBuf) / sizeof(TCHAR),
        TEXT("%s failed with error %d: %s"),
        lpszFunction, dw, lpMsgBuf);
    MessageBox(NULL, (LPCTSTR)lpDisplayBuf, TEXT("Error"), MB_OK);

    LocalFree(lpMsgBuf);
    LocalFree(lpDisplayBuf);
    ExitProcess(1);
}