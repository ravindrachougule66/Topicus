using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace EuroPortUserControls
{
    public partial class FiveStateRange : UserControl
    {
        int rowIndex;
        private int _value;
        public int Value { 
            get {
                return this._value;
            }
            set {
                // simple boundary checking
                if (value >= 1 && value <= 5)
                {
                    this._value = value;
                    this.Invalidate();
                }
            } 
        }
        
        private float widthSingleItem;
        private Color[] colors;

        public FiveStateRange(int selectedItem)
            : base()
        {
            Init(selectedItem);           
            InitializeComponent();
        }

        public FiveStateRange()
        {
            Init(null);
        }

        private void Init(int? selectedItem)
        { 
            this.Size = new System.Drawing.Size(64, 12);            
            colors = new Color[]
            {
                Color.FromArgb(255,210,63,63),
                Color.FromArgb(255,255,228,136),
                Color.FromArgb(255,57,189,130),
                Color.FromArgb(255,255,228,136),
                Color.FromArgb(255,210,63,63)
            };
            this.widthSingleItem = ((this.Width - 24) / 4) * 99 / 100;
            if (selectedItem == null)
                this._value = 1;
            else
                this._value = (int)selectedItem;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Graphics G = this.CreateGraphics();
            G.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            G.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
            G.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            var tempIndex = this._value >= 1 ? this._value - 1 : 0;
            SolidBrush sBrush = new SolidBrush(this.colors[tempIndex]);

            for (int i = 0; i <= 4; i++)
            {
                RectangleF R = new RectangleF((i*4) + (i*this.widthSingleItem), 0, this.widthSingleItem, (this.Height) * 99 / 100);
                RectangleF outerRect = new RectangleF(R.X, R.Y, R.Width, R.Height);
                Rectangle innerRect = new Rectangle((int)R.X, (int)R.Y, (int)R.Width, (int)R.Height);

                G.DrawEllipse(new Pen(Color.FromArgb(255, 111, 111, 111), 1), outerRect);
                if (this._value - 1 == i) G.FillEllipse(sBrush, innerRect);
            }
        }

        private void DrawCircle(RectangleF rect, Graphics g)
        {
            SolidBrush sBrush = new SolidBrush(this.colors[this._value]);
            Rectangle outerRect = new Rectangle((int)rect.X + 1, (int)rect.Y + 1, (int)rect.Width - 1, (int)rect.Height - 1);
            Rectangle innerRect = new Rectangle((int)rect.X + 2, (int)rect.Y + 2, (int)rect.Width - 2, (int)rect.Height - 2);

            g.DrawEllipse(new Pen(Color.FromArgb(255, 111, 111, 111), 2), outerRect);
            g.FillEllipse(sBrush, innerRect);

        }
    }
}