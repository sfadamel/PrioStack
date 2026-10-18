using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("PrioStack Desktop")]
[assembly: AssemblyDescription("PrioStack - Cockpit de Gestion de la Charge Mentale & Agenda")]
[assembly: AssemblyCompany("DamelIT")]
[assembly: AssemblyProduct("PrioStack")]
[assembly: AssemblyVersion("1.2.0.0")]
[assembly: AssemblyFileVersion("1.2.0.0")]

namespace PrioStackLauncher
{
    static class Program
    {
        private static HttpListener _listener;
        private static bool _running = true;
        private static string _wwwRoot;
        private static int _port = 8098;

        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            _wwwRoot = Path.Combine(baseDir, "app");
            if (!Directory.Exists(_wwwRoot))
            {
                // Fallback if launched directly next to build/web
                string altRoot = Path.Combine(baseDir, "build", "web");
                if (Directory.Exists(altRoot))
                {
                    _wwwRoot = altRoot;
                }
                else
                {
                    MessageBox.Show(
                        "Le dossier de ressources 'app' est introuvable dans : " + baseDir,
                        "PrioStack Desktop",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error
                    );
                    return;
                }
            }

            _port = FindAvailablePort(8098);
            string url = string.Format("http://127.0.0.1:{0}/", _port);

            Thread serverThread = new Thread(() => StartHttpServer(url));
            serverThread.IsBackground = true;
            serverThread.Start();

            Process appProcess = LaunchAppWindow(url);
            if (appProcess != null)
            {
                try
                {
                    appProcess.WaitForExit();
                }
                catch { }
            }
            else
            {
                // If browser launched asynchronously, keep server alive until user closes tray or for session
                Thread.Sleep(TimeSpan.FromHours(12));
            }

            _running = false;
            try { if (_listener != null) _listener.Stop(); } catch { }
        }

        private static int FindAvailablePort(int preferredPort)
        {
            for (int p = preferredPort; p < preferredPort + 50; p++)
            {
                try
                {
                    TcpListener tcp = new TcpListener(IPAddress.Loopback, p);
                    tcp.Start();
                    tcp.Stop();
                    return p;
                }
                catch { }
            }
            return preferredPort;
        }

        private static Process LaunchAppWindow(string url)
        {
            string[] candidates = new string[]
            {
                @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
                @"C:\Program Files\Google\Chrome\Application\chrome.exe",
                @"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
            };

            string userDataDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "PrioStack",
                "UserData"
            );
            Directory.CreateDirectory(userDataDir);

            foreach (string exe in candidates)
            {
                if (File.Exists(exe))
                {
                    ProcessStartInfo psi = new ProcessStartInfo();
                    psi.FileName = exe;
                    psi.Arguments = string.Format(
                        "--app=\"{0}\" --window-size=1480,920 --user-data-dir=\"{1}\"",
                        url,
                        userDataDir
                    );
                    psi.UseShellExecute = false;
                    return Process.Start(psi);
                }
            }

            Process.Start(url);
            return null;
        }

        private static void StartHttpServer(string prefix)
        {
            try
            {
                _listener = new HttpListener();
                _listener.Prefixes.Add(prefix);
                _listener.Start();

                while (_running)
                {
                    HttpListenerContext ctx = _listener.GetContext();
                    ThreadPool.QueueUserWorkItem((state) => HandleRequest((HttpListenerContext)state), ctx);
                }
            }
            catch { }
        }

        private static void HandleRequest(HttpListenerContext ctx)
        {
            try
            {
                string reqPath = ctx.Request.Url.AbsolutePath.TrimStart('/');
                if (string.IsNullOrEmpty(reqPath))
                {
                    reqPath = "index.html";
                }

                string fullPath = Path.GetFullPath(Path.Combine(_wwwRoot, reqPath.Replace('/', Path.DirectorySeparatorChar)));
                if (!fullPath.StartsWith(Path.GetFullPath(_wwwRoot), StringComparison.OrdinalIgnoreCase) || !File.Exists(fullPath))
                {
                    fullPath = Path.Combine(_wwwRoot, "index.html");
                }

                byte[] bytes = File.ReadAllBytes(fullPath);
                ctx.Response.ContentType = GetMimeType(Path.GetExtension(fullPath));
                ctx.Response.ContentLength64 = bytes.Length;
                ctx.Response.Headers["Cache-Control"] = "no-cache";
                ctx.Response.OutputStream.Write(bytes, 0, bytes.Length);
                ctx.Response.OutputStream.Close();
            }
            catch
            {
                try { ctx.Response.Abort(); } catch { }
            }
        }

        private static string GetMimeType(string ext)
        {
            switch (ext.ToLowerInvariant())
            {
                case ".html": return "text/html; charset=utf-8";
                case ".js": return "application/javascript; charset=utf-8";
                case ".css": return "text/css; charset=utf-8";
                case ".json": return "application/json; charset=utf-8";
                case ".wasm": return "application/wasm";
                case ".png": return "image/png";
                case ".jpg":
                case ".jpeg": return "image/jpeg";
                case ".svg": return "image/svg+xml";
                case ".ico": return "image/x-icon";
                case ".ttf": return "font/ttf";
                case ".otf": return "font/otf";
                case ".woff": return "font/woff";
                case ".woff2": return "font/woff2";
                default: return "application/octet-stream";
            }
        }
    }
}
