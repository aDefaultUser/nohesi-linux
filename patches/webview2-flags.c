/* Stands in for msedgewebview2.exe and starts the real one with the flags WebView2 needs under Wine,
 * so the No Hesi Launcher's own files never have to change.
 *
 * Under Wine, WebView2 crashes on DirectComposition and can't start sandboxed page processes.
 * The launcher sets its own browser flags and ignores the usual overrides, so they're added here.
 * The real executable's path comes from NOHESI_REAL_WEBVIEW2, which the launch wrapper sets. */
#include <windows.h>
#include <stdio.h>
#include <wchar.h>

#define EXTRA_FLAGS L"--no-sandbox --disable-gpu --in-process-gpu"

/* Skips the first argument of a command line, which may be quoted. */
static const wchar_t *skip_program(const wchar_t *cmd)
{
    if (*cmd == L'"') {
        cmd++;
        while (*cmd && *cmd != L'"') cmd++;
        if (*cmd) cmd++;
    } else {
        while (*cmd && *cmd != L' ' && *cmd != L'\t') cmd++;
    }
    while (*cmd == L' ' || *cmd == L'\t') cmd++;
    return cmd;
}

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE prev, PWSTR args, int show)
{
    wchar_t real[MAX_PATH];
    const wchar_t *rest = skip_program(GetCommandLineW());
    size_t size;
    wchar_t *cmd;
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    DWORD code = 1;

    if (!GetEnvironmentVariableW(L"NOHESI_REAL_WEBVIEW2", real, MAX_PATH))
        return 1;
    size = wcslen(real) + wcslen(EXTRA_FLAGS) + wcslen(rest) + 8;
    cmd = HeapAlloc(GetProcessHeap(), 0, size * sizeof(wchar_t));
    if (!cmd)
        return 1;
    swprintf(cmd, size, L"\"%ls\" %ls %ls", real, EXTRA_FLAGS, rest);

    if (!CreateProcessW(real, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi))
        return 1;
    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &code);
    return code;
}
