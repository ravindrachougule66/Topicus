using System;
using System.Drawing;
using System.Windows.Forms;

namespace EuroPortUserControls
{
    public partial class ThreeStateCheckBox : CheckBox
    {
        public bool IsFlat { get; set; }
                            
        public ThreeStateCheckBox()
            : base()
        {
            InitializeComponent(); 
            this.ThreeState = true; 
            this.CheckState = CheckState.Indeterminate;
        }
        
        protected override void OnPaint(PaintEventArgs pEvent)
        {   
            Graphics G = pEvent.Graphics;

            G.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            G.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
            G.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            RectangleF R = new RectangleF(G.ClipBounds.X, G.ClipBounds.Y, this.Width, this.Height);
     
            if (!IsFlat) DrawBorder(G, R);
          
            G.FillRectangle(new SolidBrush(Color.FromArgb(255, 221, 221, 221)), R);
            R.Width-=3;
            R.Height-=3;
            
            if (this.CheckState == System.Windows.Forms.CheckState.Indeterminate) {
                // todo?
            }
            else if (this.Checked)
            {
                Brush greenBrush = new SolidBrush(Color.Green);
                Pen greenPen = new Pen(greenBrush, 2f);
                G.DrawLine(greenPen, new Point(3, (int)R.Height / 2), new Point((int)R.Width / 2, (int)R.Height - 3));
                G.DrawLine(greenPen, new Point((int)R.Width / 2 - 1, (int)R.Height - 3), new Point((int)R.Width - 3, 3));
            }
            else
            {
                Brush redBrush = new SolidBrush(Color.Red);
                Pen redPen = new Pen(redBrush,2f);
                G.DrawLine(redPen, new Point(3, 3), new Point((int)R.Width - 3, (int)R.Height - 3));
                G.DrawLine(redPen, new Point(3, (int)R.Height - 3), new Point((int)R.Width - 3, 3));                
            }
        }

        private void DrawBorder(Graphics gr, RectangleF rect)
        {
            Color[] colors;
            colors = new Color[]
            {
                SystemColors.ControlDark,
                SystemColors.ControlDarkDark,
                SystemColors.ControlLightLight,
                SystemColors.ControlLight
            };
            
            using (Pen p = new Pen(colors[0]))
            {
                gr.DrawLine(p, rect.X, rect.Bottom - 1,
                    rect.X, rect.Y);
                gr.DrawLine(p, rect.X, rect.Y,
                    rect.Right - 1, rect.Y);
            }
            
            using (Pen p = new Pen(colors[1]))
            {
                gr.DrawLine(p, rect.X + 1, rect.Bottom - 2,
                    rect.X + 1, rect.Y + 1);
                gr.DrawLine(p, rect.X + 1, rect.Y + 1,
                    rect.Right - 2, rect.Y + 1);
            }
             
            using (Pen p = new Pen(colors[2]))
            {
                gr.DrawLine(p, rect.X, rect.Bottom - 1,
                    rect.Right - 1, rect.Bottom - 1);
                gr.DrawLine(p, rect.Right - 1, rect.Bottom - 1,
                    rect.Right - 1, rect.Y);
            }
                        
            using (Pen p = new Pen(colors[3]))
            {
                gr.DrawLine(p, rect.X + 1, rect.Bottom - 2,
                    rect.Right - 2, rect.Bottom - 2);
                gr.DrawLine(p, rect.Right - 2, rect.Bottom - 2,
                    rect.Right - 2, rect.Y + 1);
            }
        }
    }
}