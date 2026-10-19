using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("PrioStack Desktop")]
[assembly: AssemblyDescription("PrioStack - Cockpit de Gestion de la Charge Mentale & Agenda")]
[assembly: AssemblyCompany("DamelIT")]
[assembly: AssemblyProduct("PrioStack")]
[assembly: AssemblyVersion("1.2.1.0")]
[assembly: AssemblyFileVersion("1.2.1.0")]

namespace PrioStackLauncher
{
    static class Program
    {
        private static TcpListener _tcpServer;
        private static volatile bool _running = true;
        private static string _wwwRoot;
        private static int _port = 8098;
        private static Mutex _singleInstanceMutex;

        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            _wwwRoot = Path.Combine(baseDir, "app");
            if (!Directory.Exists(_wwwRoot))
            {
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

            bool createdNew;
            _singleInstanceMutex = new Mutex(true, "Local\\PrioStackDesktopServerMutex", out createdNew);

            if (!createdNew)
            {
                // Server already running in background! Find which port it is listening on and open a window
                int activePort = FindExistingPrioStackPort(8098);
                LaunchAppWindow(string.Format("http://127.0.0.1:{0}/", activePort));
                return;
            }

            _port = StartTcpServer(8098);
            string url = string.Format("http://127.0.0.1:{0}/", _port);

            Thread serverThread = new Thread(AcceptLoop);
            serverThread.IsBackground = true;
            serverThread.Start();

            // Create system tray icon so the server stays alive even when msedge delegates to an existing process
            using (NotifyIcon trayIcon = new NotifyIcon())
            {
                try
                {
                    trayIcon.Icon = Icon.ExtractAssociatedIcon(Assembly.GetExecutingAssembly().Location);
                }
                catch
                {
                    trayIcon.Icon = SystemIcons.Application;
                }
                trayIcon.Text = string.Format("PrioStack v1.2 (127.0.0.1:{0})", _port);
                trayIcon.Visible = true;

                ContextMenu menu = new ContextMenu();
                menu.MenuItems.Add("Ouvrir PrioStack", (s, e) => LaunchAppWindow(url));
                menu.MenuItems.Add("-");
                menu.MenuItems.Add("Quitter PrioStack", (s, e) =>
                {
                    _running = false;
                    try { _tcpServer.Stop(); } catch { }
                    trayIcon.Visible = false;
                    Application.Exit();
                });
                trayIcon.ContextMenu = menu;
                trayIcon.DoubleClick += (s, e) => LaunchAppWindow(url);

                // Launch the dedicated app window after server is listening
                LaunchAppWindow(url);

                // Keep WinForms message loop alive
                Application.Run();
            }
        }

        private static int FindExistingPrioStackPort(int startPort)
        {
            for (int p = startPort; p < startPort + 30; p++)
            {
                try
                {
                    using (TcpClient client = new TcpClient())
                    {
                        IAsyncResult res = client.BeginConnect(IPAddress.Loopback, p, null, null);
                        bool success = res.AsyncWaitHandle.WaitOne(TimeSpan.FromMilliseconds(150));
                        if (success && client.Connected)
                        {
                            return p;
                        }
                    }
                }
                catch { }
            }
            return startPort;
        }

        private static int StartTcpServer(int preferredPort)
        {
            for (int p = preferredPort; p < preferredPort + 50; p++)
            {
                try
                {
                    _tcpServer = new TcpListener(IPAddress.Loopback, p);
                    _tcpServer.Start();
                    return p;
                }
                catch { }
            }
            _tcpServer = new TcpListener(IPAddress.Loopback, 0);
            _tcpServer.Start();
            return ((IPEndPoint)_tcpServer.LocalEndpoint).Port;
        }

        private static void AcceptLoop()
        {
            while (_running)
            {
                try
                {
                    Socket clientSocket = _tcpServer.AcceptSocket();
                    ThreadPool.QueueUserWorkItem(HandleClientSocket, clientSocket);
                }
                catch
                {
                    if (!_running) break;
                }
            }
        }

        private static void HandleClientSocket(object state)
        {
            Socket socket = (Socket)state;
            try
            {
                socket.ReceiveTimeout = 5000;
                socket.SendTimeout = 10000;

                byte[] buffer = new byte[8192];
                int received = socket.Receive(buffer);
                if (received <= 0)
                {
                    socket.Close();
                    return;
                }

                string requestText = Encoding.ASCII.GetString(buffer, 0, received);
                string[] lines = requestText.Split(new string[] { "\r\n", "\n" }, StringSplitOptions.None);
                if (lines.Length == 0)
                {
                    socket.Close();
                    return;
                }

                string[] firstLineParts = lines[0].Split(' ');
                if (firstLineParts.Length < 2)
                {
                    socket.Close();
                    return;
                }

                string rawUrl = firstLineParts[1];
                int qIndex = rawUrl.IndexOf('?');
                string urlPath = qIndex >= 0 ? rawUrl.Substring(0, qIndex) : rawUrl;
                urlPath = Uri.UnescapeDataString(urlPath.TrimStart('/'));

                if (string.IsNullOrEmpty(urlPath))
                {
                    urlPath = "index.html";
                }

                string rootFull = Path.GetFullPath(_wwwRoot);
                string candidateFull = Path.GetFullPath(Path.Combine(rootFull, urlPath.Replace('/', Path.DirectorySeparatorChar)));

                // Prevent directory traversal & SPA fallback to index.html
                if (!candidateFull.StartsWith(rootFull, StringComparison.OrdinalIgnoreCase) || !File.Exists(candidateFull))
                {
                    // If requesting an unknown file extension, return 404; otherwise SPA index.html
                    if (Path.HasExtension(candidateFull) && !File.Exists(candidateFull))
                    {
                        byte[] notFoundBody = Encoding.UTF8.GetBytes("404 Not Found");
                        SendHttpResponse(socket, "404 Not Found", "text/plain; charset=utf-8", notFoundBody);
                        socket.Close();
                        return;
                    }
                    candidateFull = Path.Combine(rootFull, "index.html");
                }

                byte[] fileBytes = File.ReadAllBytes(candidateFull);
                string mimeType = GetMimeType(Path.GetExtension(candidateFull));
                SendHttpResponse(socket, "200 OK", mimeType, fileBytes);
            }
            catch { }
            finally
            {
                try { socket.Shutdown(SocketShutdown.Both); } catch { }
                try { socket.Close(); } catch { }
            }
        }

        private static void SendHttpResponse(Socket socket, string status, string contentType, byte[] body)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("HTTP/1.1 {0}\r\n", status);
            sb.AppendFormat("Content-Type: {0}\r\n", contentType);
            sb.AppendFormat("Content-Length: {0}\r\n", body.Length);
            sb.Append("Cache-Control: no-cache, no-store, must-revalidate\r\n");
            sb.Append("Access-Control-Allow-Origin: *\r\n");
            sb.Append("Connection: close\r\n\r\n");

            byte[] headerBytes = Encoding.ASCII.GetBytes(sb.ToString());
            socket.Send(headerBytes);
            if (body.Length > 0)
            {
                socket.Send(body);
            }
        }

        private static void LaunchAppWindow(string url)
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
                "AppProfile"
            );
            Directory.CreateDirectory(userDataDir);

            foreach (string exe in candidates)
            {
                if (File.Exists(exe))
                {
                    ProcessStartInfo psi = new ProcessStartInfo();
                    psi.FileName = exe;
                    psi.Arguments = string.Format(
                        "--app=\"{0}\" --window-size=1480,920 --user-data-dir=\"{1}\" --no-first-run --no-default-browser-check",
                        url,
                        userDataDir
                    );
                    psi.UseShellExecute = false;
                    Process.Start(psi);
                    return;
                }
            }

            Process.Start(url);
        }

        private static string GetMimeType(string ext)
        {
            switch (ext.ToLowerInvariant())
            {
                case ".html": return "text/html; charset=utf-8";
                case ".js":
                case ".mjs": return "application/javascript; charset=utf-8";
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
                case ".frag": return "application/octet-stream";
                default: return "application/octet-stream";
            }
        }
    }
}
