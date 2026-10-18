using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("PrioStack Setup")]
[assembly: AssemblyDescription("Installateur Windows pour PrioStack v1.2")]
[assembly: AssemblyCompany("DamelIT")]
[assembly: AssemblyProduct("PrioStack Setup")]
[assembly: AssemblyVersion("1.2.0.0")]
[assembly: AssemblyFileVersion("1.2.0.0")]

namespace PrioStackSetup
{
    public class InstallerForm : Form
    {
        private Label _titleLabel;
        private Label _subtitleLabel;
        private Label _pathLabel;
        private TextBox _pathBox;
        private CheckBox _desktopShortcutCheck;
        private CheckBox _startMenuCheck;
        private CheckBox _launchAfterInstallCheck;
        private ProgressBar _progressBar;
        private Label _statusLabel;
        private Button _installBtn;
        private Button _cancelBtn;

        public InstallerForm()
        {
            this.Text = "Installation de PrioStack v1.2 (Windows 64-bit)";
            this.Size = new Size(540, 390);
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(17, 19, 25);
            this.ForeColor = Color.FromArgb(243, 244, 246);
            this.Font = new Font("Segoe UI", 9.5F, FontStyle.Regular);

            _titleLabel = new Label();
            _titleLabel.Text = "PrioStack — Installation Windows";
            _titleLabel.Font = new Font("Segoe UI", 15F, FontStyle.Bold);
            _titleLabel.ForeColor = Color.FromArgb(243, 244, 246);
            _titleLabel.Location = new Point(24, 22);
            _titleLabel.AutoSize = true;
            this.Controls.Add(_titleLabel);

            _subtitleLabel = new Label();
            _subtitleLabel.Text = "Cockpit de gestion de la charge mentale, Pile Active (PUSH/POP) & Calendrier.";
            _subtitleLabel.Font = new Font("Segoe UI", 9.5F, FontStyle.Regular);
            _subtitleLabel.ForeColor = Color.FromArgb(156, 163, 175);
            _subtitleLabel.Location = new Point(24, 54);
            _subtitleLabel.AutoSize = true;
            this.Controls.Add(_subtitleLabel);

            _pathLabel = new Label();
            _pathLabel.Text = "Dossier d'installation :";
            _pathLabel.Location = new Point(24, 92);
            _pathLabel.AutoSize = true;
            this.Controls.Add(_pathLabel);

            string defaultDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Programs",
                "PrioStack"
            );

            _pathBox = new TextBox();
            _pathBox.Text = defaultDir;
            _pathBox.Location = new Point(24, 116);
            _pathBox.Size = new Size(476, 26);
            _pathBox.BackColor = Color.FromArgb(23, 25, 33);
            _pathBox.ForeColor = Color.FromArgb(243, 244, 246);
            _pathBox.BorderStyle = BorderStyle.FixedSingle;
            this.Controls.Add(_pathBox);

            _desktopShortcutCheck = new CheckBox();
            _desktopShortcutCheck.Text = "Créer un raccourci sur le Bureau Windows";
            _desktopShortcutCheck.Checked = true;
            _desktopShortcutCheck.Location = new Point(24, 158);
            _desktopShortcutCheck.AutoSize = true;
            this.Controls.Add(_desktopShortcutCheck);

            _startMenuCheck = new CheckBox();
            _startMenuCheck.Text = "Ajouter PrioStack au Menu Démarrer";
            _startMenuCheck.Checked = true;
            _startMenuCheck.Location = new Point(24, 186);
            _startMenuCheck.AutoSize = true;
            this.Controls.Add(_startMenuCheck);

            _launchAfterInstallCheck = new CheckBox();
            _launchAfterInstallCheck.Text = "Démarrer PrioStack immédiatement après l'installation";
            _launchAfterInstallCheck.Checked = true;
            _launchAfterInstallCheck.Location = new Point(24, 214);
            _launchAfterInstallCheck.AutoSize = true;
            this.Controls.Add(_launchAfterInstallCheck);

            _statusLabel = new Label();
            _statusLabel.Text = "Prêt à installer.";
            _statusLabel.ForeColor = Color.FromArgb(156, 163, 175);
            _statusLabel.Location = new Point(24, 252);
            _statusLabel.AutoSize = true;
            this.Controls.Add(_statusLabel);

            _progressBar = new ProgressBar();
            _progressBar.Location = new Point(24, 274);
            _progressBar.Size = new Size(476, 16);
            _progressBar.Value = 0;
            this.Controls.Add(_progressBar);

            _installBtn = new Button();
            _installBtn.Text = "Installer PrioStack";
            _installBtn.Font = new Font("Segoe UI", 9.5F, FontStyle.Bold);
            _installBtn.BackColor = Color.FromArgb(59, 130, 246);
            _installBtn.ForeColor = Color.White;
            _installBtn.FlatStyle = FlatStyle.Flat;
            _installBtn.FlatAppearance.BorderSize = 0;
            _installBtn.Size = new Size(165, 36);
            _installBtn.Location = new Point(335, 304);
            _installBtn.Click += OnInstallClick;
            this.Controls.Add(_installBtn);

            _cancelBtn = new Button();
            _cancelBtn.Text = "Fermer";
            _cancelBtn.BackColor = Color.FromArgb(30, 33, 43);
            _cancelBtn.ForeColor = Color.FromArgb(243, 244, 246);
            _cancelBtn.FlatStyle = FlatStyle.Flat;
            _cancelBtn.FlatAppearance.BorderSize = 0;
            _cancelBtn.Size = new Size(100, 36);
            _cancelBtn.Location = new Point(225, 304);
            _cancelBtn.Click += (s, e) => this.Close();
            this.Controls.Add(_cancelBtn);
        }

        private void OnInstallClick(object sender, EventArgs e)
        {
            _installBtn.Enabled = false;
            try
            {
                string targetDir = _pathBox.Text.Trim();
                _statusLabel.Text = "Création du répertoire d'installation...";
                _progressBar.Value = 15;
                Application.DoEvents();

                if (Directory.Exists(targetDir))
                {
                    try { Directory.Delete(targetDir, true); } catch { }
                }
                Directory.CreateDirectory(targetDir);

                _statusLabel.Text = "Extraction des fichiers de PrioStack...";
                _progressBar.Value = 45;
                Application.DoEvents();

                string tempZip = Path.Combine(Path.GetTempPath(), "priostack_payload.zip");
                using (Stream resStream = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
                {
                    if (resStream == null)
                    {
                        throw new Exception("Archive intégrée payload.zip introuvable.");
                    }
                    using (FileStream fs = new FileStream(tempZip, FileMode.Create, FileAccess.Write))
                    {
                        resStream.CopyTo(fs);
                    }
                }

                ZipFile.ExtractToDirectory(tempZip, targetDir);
                try { File.Delete(tempZip); } catch { }

                string exePath = Path.Combine(targetDir, "PrioStack.exe");

                _statusLabel.Text = "Création des raccourcis Windows...";
                _progressBar.Value = 80;
                Application.DoEvents();

                if (_desktopShortcutCheck.Checked)
                {
                    string desktopLink = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                        "PrioStack.lnk"
                    );
                    CreateShortcut(desktopLink, exePath, targetDir);
                }

                if (_startMenuCheck.Checked)
                {
                    string startMenuLink = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.Programs),
                        "PrioStack.lnk"
                    );
                    CreateShortcut(startMenuLink, exePath, targetDir);
                }

                RegisterUninstaller(targetDir, exePath);

                _progressBar.Value = 100;
                _statusLabel.Text = "Installation terminée avec succès !";
                _statusLabel.ForeColor = Color.FromArgb(16, 185, 129);
                Application.DoEvents();

                if (_launchAfterInstallCheck.Checked && File.Exists(exePath))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = exePath,
                        WorkingDirectory = targetDir,
                        UseShellExecute = true
                    });
                }

                MessageBox.Show(
                    "PrioStack v1.2 a été installé avec succès dans :\n" + targetDir,
                    "Installation terminée",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
                this.Close();
            }
            catch (Exception ex)
            {
                _installBtn.Enabled = true;
                _statusLabel.Text = "Erreur lors de l'installation.";
                MessageBox.Show(
                    "Erreur lors de l'installation : " + ex.Message,
                    "PrioStack Setup",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
            }
        }

        private static void CreateShortcut(string shortcutPath, string targetExe, string workingDir)
        {
            try
            {
                Type shellType = Type.GetTypeFromProgID("WScript.Shell");
                dynamic shell = Activator.CreateInstance(shellType);
                dynamic shortcut = shell.CreateShortcut(shortcutPath);
                shortcut.TargetPath = targetExe;
                shortcut.WorkingDirectory = workingDir;
                shortcut.Description = "PrioStack - Cockpit de Gestion de la Charge Mentale";
                shortcut.Save();
            }
            catch { }
        }

        private static void RegisterUninstaller(string installDir, string exePath)
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.CreateSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Uninstall\PrioStack"))
                {
                    if (key != null)
                    {
                        key.SetValue("DisplayName", "PrioStack v1.2");
                        key.SetValue("DisplayVersion", "1.2.0");
                        key.SetValue("Publisher", "DamelIT");
                        key.SetValue("InstallLocation", installDir);
                        key.SetValue("DisplayIcon", exePath);
                        key.SetValue("UninstallString", "cmd.exe /c rmdir /s /q \"" + installDir + "\"");
                        key.SetValue("NoModify", 1, RegistryValueKind.DWord);
                        key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
                    }
                }
            }
            catch { }
        }

        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new InstallerForm());
        }
    }
}
