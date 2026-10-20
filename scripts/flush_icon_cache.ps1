$code = @"
using System;
using System.Runtime.InteropServices;

public class ShellNotify {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);

    public static void FlushIconCache() {
        // SHCNE_ASSOCCHANGED = 0x08000000, SHCNF_FLUSHNOWAIT = 0x2000 | SHCNF_IDLIST = 0
        SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero);
    }
}
"@

Add-Type -TypeDefinition $code
[ShellNotify]::FlushIconCache()
Write-Host "Shell icon notification broadcasted successfully!"
