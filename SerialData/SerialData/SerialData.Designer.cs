namespace SerialData
{
    partial class SerialData
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            An1TimerCheckBox = new CheckBox();
            DigitalOutputLabel = new Label();
            OutputTextBox = new TextBox();
            ComListBox = new ListBox();
            PortsComboBox = new ComboBox();
            label1 = new Label();
            StatusStrip = new StatusStrip();
            StatusLabel = new ToolStripStatusLabel();
            SerialTextBox = new TextBox();
            WriteButton = new Button();
            ReadButton = new Button();
            ConnectButton = new Button();
            ExitButton = new Button();
            FramingErrorButton = new Button();
            ADCButton = new Button();
            IDButton = new Button();
            StatusTimer = new System.Windows.Forms.Timer(components);
            ServoTrackBar = new TrackBar();
            ServoLabel = new Label();
            TemperatureLabel = new Label();
            PortLabel = new Label();
            VrefNumericUpDown = new NumericUpDown();
            ServoDegreeLabel = new Label();
            StatusStrip.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)ServoTrackBar).BeginInit();
            ((System.ComponentModel.ISupportInitialize)VrefNumericUpDown).BeginInit();
            SuspendLayout();
            // 
            // An1TimerCheckBox
            // 
            An1TimerCheckBox.AutoSize = true;
            An1TimerCheckBox.Location = new Point(19, 73);
            An1TimerCheckBox.Name = "An1TimerCheckBox";
            An1TimerCheckBox.Size = new Size(144, 24);
            An1TimerCheckBox.TabIndex = 24;
            An1TimerCheckBox.Text = "An1Timer Enable";
            An1TimerCheckBox.UseVisualStyleBackColor = true;
            // 
            // DigitalOutputLabel
            // 
            DigitalOutputLabel.AutoSize = true;
            DigitalOutputLabel.Location = new Point(181, 17);
            DigitalOutputLabel.Name = "DigitalOutputLabel";
            DigitalOutputLabel.Size = new Size(104, 20);
            DigitalOutputLabel.TabIndex = 23;
            DigitalOutputLabel.Text = "Digital Output";
            // 
            // OutputTextBox
            // 
            OutputTextBox.Location = new Point(181, 40);
            OutputTextBox.Name = "OutputTextBox";
            OutputTextBox.Size = new Size(151, 27);
            OutputTextBox.TabIndex = 22;
            // 
            // ComListBox
            // 
            ComListBox.FormattingEnabled = true;
            ComListBox.Location = new Point(385, 6);
            ComListBox.Name = "ComListBox";
            ComListBox.Size = new Size(403, 344);
            ComListBox.TabIndex = 21;
            // 
            // PortsComboBox
            // 
            PortsComboBox.FormattingEnabled = true;
            PortsComboBox.Location = new Point(12, 6);
            PortsComboBox.Name = "PortsComboBox";
            PortsComboBox.Size = new Size(151, 28);
            PortsComboBox.TabIndex = 20;
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Location = new Point(124, 240);
            label1.Name = "label1";
            label1.Size = new Size(0, 20);
            label1.TabIndex = 19;
            // 
            // StatusStrip
            // 
            StatusStrip.ImageScalingSize = new Size(20, 20);
            StatusStrip.Items.AddRange(new ToolStripItem[] { StatusLabel });
            StatusStrip.Location = new Point(0, 424);
            StatusStrip.Name = "StatusStrip";
            StatusStrip.Size = new Size(800, 26);
            StatusStrip.TabIndex = 18;
            StatusStrip.Text = "statusStrip1";
            // 
            // StatusLabel
            // 
            StatusLabel.Name = "StatusLabel";
            StatusLabel.Size = new Size(85, 20);
            StatusLabel.Text = "StatusLabel";
            // 
            // SerialTextBox
            // 
            SerialTextBox.Location = new Point(12, 40);
            SerialTextBox.Name = "SerialTextBox";
            SerialTextBox.Size = new Size(151, 27);
            SerialTextBox.TabIndex = 17;
            // 
            // WriteButton
            // 
            WriteButton.Location = new Point(385, 366);
            WriteButton.Name = "WriteButton";
            WriteButton.Size = new Size(94, 53);
            WriteButton.TabIndex = 16;
            WriteButton.Text = "Write";
            WriteButton.UseVisualStyleBackColor = true;
            WriteButton.Click += WriteButton_Click;
            // 
            // ReadButton
            // 
            ReadButton.Location = new Point(485, 366);
            ReadButton.Name = "ReadButton";
            ReadButton.Size = new Size(94, 53);
            ReadButton.TabIndex = 15;
            ReadButton.Text = "Read";
            ReadButton.UseVisualStyleBackColor = true;
            ReadButton.Click += ReadButton_Click;
            // 
            // ConnectButton
            // 
            ConnectButton.Location = new Point(585, 366);
            ConnectButton.Name = "ConnectButton";
            ConnectButton.Size = new Size(94, 53);
            ConnectButton.TabIndex = 14;
            ConnectButton.Text = "Connect";
            ConnectButton.UseVisualStyleBackColor = true;
            ConnectButton.Click += ConnectButton_Click;
            // 
            // ExitButton
            // 
            ExitButton.Location = new Point(685, 365);
            ExitButton.Name = "ExitButton";
            ExitButton.Size = new Size(103, 54);
            ExitButton.TabIndex = 13;
            ExitButton.Text = "E&xit";
            ExitButton.UseVisualStyleBackColor = true;
            ExitButton.Click += ExitButton_Click;
            // 
            // FramingErrorButton
            // 
            FramingErrorButton.Location = new Point(12, 103);
            FramingErrorButton.Name = "FramingErrorButton";
            FramingErrorButton.Size = new Size(151, 47);
            FramingErrorButton.TabIndex = 25;
            FramingErrorButton.Text = "Framing Error";
            FramingErrorButton.UseVisualStyleBackColor = true;
            FramingErrorButton.Click += FramingErrorButton_Click;
            // 
            // ADCButton
            // 
            ADCButton.Location = new Point(12, 156);
            ADCButton.Name = "ADCButton";
            ADCButton.Size = new Size(151, 48);
            ADCButton.TabIndex = 26;
            ADCButton.Text = "ADC";
            ADCButton.UseVisualStyleBackColor = true;
            ADCButton.Click += ADCButton_Click;
            // 
            // IDButton
            // 
            IDButton.Location = new Point(12, 210);
            IDButton.Name = "IDButton";
            IDButton.Size = new Size(151, 50);
            IDButton.TabIndex = 27;
            IDButton.Text = "ID";
            IDButton.UseVisualStyleBackColor = true;
            IDButton.Click += IDButton_Click;
            // 
            // ServoTrackBar
            // 
            ServoTrackBar.Location = new Point(12, 363);
            ServoTrackBar.Name = "ServoTrackBar";
            ServoTrackBar.Size = new Size(367, 56);
            ServoTrackBar.TabIndex = 28;
            // 
            // ServoLabel
            // 
            ServoLabel.AutoSize = true;
            ServoLabel.Location = new Point(180, 105);
            ServoLabel.Name = "ServoLabel";
            ServoLabel.Size = new Size(86, 20);
            ServoLabel.TabIndex = 29;
            ServoLabel.Text = "Servo Label";
            // 
            // TemperatureLabel
            // 
            TemperatureLabel.AutoSize = true;
            TemperatureLabel.Location = new Point(180, 135);
            TemperatureLabel.Name = "TemperatureLabel";
            TemperatureLabel.Size = new Size(133, 20);
            TemperatureLabel.TabIndex = 30;
            TemperatureLabel.Text = "Temperature Label";
            // 
            // PortLabel
            // 
            PortLabel.AutoSize = true;
            PortLabel.Location = new Point(180, 163);
            PortLabel.Name = "PortLabel";
            PortLabel.Size = new Size(75, 20);
            PortLabel.TabIndex = 31;
            PortLabel.Text = "Port Label";
            // 
            // VrefNumericUpDown
            // 
            VrefNumericUpDown.Location = new Point(181, 186);
            VrefNumericUpDown.Name = "VrefNumericUpDown";
            VrefNumericUpDown.Size = new Size(150, 27);
            VrefNumericUpDown.TabIndex = 32;
            // 
            // ServoDegreeLabel
            // 
            ServoDegreeLabel.AutoSize = true;
            ServoDegreeLabel.Location = new Point(127, 340);
            ServoDegreeLabel.Name = "ServoDegreeLabel";
            ServoDegreeLabel.Size = new Size(139, 20);
            ServoDegreeLabel.TabIndex = 33;
            ServoDegreeLabel.Text = "Servo Degree Label";
            // 
            // SerialData
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(800, 450);
            Controls.Add(ServoDegreeLabel);
            Controls.Add(VrefNumericUpDown);
            Controls.Add(PortLabel);
            Controls.Add(TemperatureLabel);
            Controls.Add(ServoLabel);
            Controls.Add(ServoTrackBar);
            Controls.Add(IDButton);
            Controls.Add(ADCButton);
            Controls.Add(FramingErrorButton);
            Controls.Add(An1TimerCheckBox);
            Controls.Add(DigitalOutputLabel);
            Controls.Add(OutputTextBox);
            Controls.Add(ComListBox);
            Controls.Add(PortsComboBox);
            Controls.Add(label1);
            Controls.Add(StatusStrip);
            Controls.Add(SerialTextBox);
            Controls.Add(WriteButton);
            Controls.Add(ReadButton);
            Controls.Add(ConnectButton);
            Controls.Add(ExitButton);
            Name = "SerialData";
            Text = "Form1";
            StatusStrip.ResumeLayout(false);
            StatusStrip.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)ServoTrackBar).EndInit();
            ((System.ComponentModel.ISupportInitialize)VrefNumericUpDown).EndInit();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private CheckBox An1TimerCheckBox;
        private Label DigitalOutputLabel;
        private TextBox OutputTextBox;
        private ListBox ComListBox;
        private ComboBox PortsComboBox;
        private Label label1;
        private StatusStrip StatusStrip;
        private ToolStripStatusLabel StatusLabel;
        private TextBox SerialTextBox;
        private Button WriteButton;
        private Button ReadButton;
        private Button ConnectButton;
        private Button ExitButton;
        private Button FramingErrorButton;
        private Button ADCButton;
        private Button IDButton;
        private System.Windows.Forms.Timer StatusTimer;
        private TrackBar ServoTrackBar;
        private Label ServoLabel;
        private Label TemperatureLabel;
        private Label PortLabel;
        private NumericUpDown VrefNumericUpDown;
        private Label ServoDegreeLabel;
    }
}
