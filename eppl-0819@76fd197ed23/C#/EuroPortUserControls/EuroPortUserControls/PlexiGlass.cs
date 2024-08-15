using System;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;

namespace EuroPortUserControls
{

    public class Plexiglass : Form
    {
        public bool ClosesOnClick { get; set; }

        public Plexiglass(Form tocover)
        {
            this.ClosesOnClick = true;

            this.BackColor = Color.FromArgb(255,64,64,64);
            this.Opacity = 0.5;     
            this.FormBorderStyle = FormBorderStyle.None;
            this.ControlBox = false;
            this.ShowInTaskbar = false;
            this.StartPosition = FormStartPosition.Manual;
            this.AutoScaleMode = AutoScaleMode.None;
            this.Location = tocover.PointToScreen(Point.Empty);
            this.ClientSize = tocover.ClientSize;
            tocover.LocationChanged += Cover_LocationChanged;
            tocover.ClientSizeChanged += Cover_ClientSizeChanged;
            this.Show(tocover);
            tocover.Focus();
            this.Click += Cover_Click;
            
            // Disable Aero transitions, the plexiglass gets too visible
            if (Environment.OSVersion.Version.Major >= 6)
            {
                int value = 1;
                DwmSetWindowAttribute(tocover.Handle, DWMWA_TRANSITIONS_FORCEDISABLED, ref value, 4);
            }
        }

        private void Cover_LocationChanged(object sender, EventArgs e)
        {
            // Ensure the plexiglass follows the owner
            this.Location = this.Owner.PointToScreen(Point.Empty);
        }

        private void Cover_ClientSizeChanged(object sender, EventArgs e)
        {
            // Ensure the plexiglass keeps the owner covered
            this.ClientSize = this.Owner.ClientSize;
        }

        private void Cover_Click(object sender, EventArgs e)
        {
            if (this.ClosesOnClick) this.Close();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            // Restore owner
            this.Owner.LocationChanged -= Cover_LocationChanged;
            this.Owner.ClientSizeChanged -= Cover_ClientSizeChanged;
            this.Owner.Click -= Cover_Click;
            if (!this.Owner.IsDisposed && Environment.OSVersion.Version.Major >= 6)
            {
                int value = 1;
                DwmSetWindowAttribute(this.Owner.Handle, DWMWA_TRANSITIONS_FORCEDISABLED, ref value, 4);
            }
            base.OnFormClosing(e);
        }

        protected override void OnActivated(EventArgs e)
        {
            // Always keep the owner activated instead
            this.BeginInvoke(new Action(() => this.Owner.Activate()));
        }

        private const int DWMWA_TRANSITIONS_FORCEDISABLED = 3;
        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr hWnd, int attr, ref int value, int attrLen);
    }
}
