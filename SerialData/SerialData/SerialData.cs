using System;
using System.IO.Ports;
using System.Xml.Serialization;
using System.Windows.Forms;
using static System.Windows.Forms.VisualStyles.VisualStyleElement;

namespace SerialData
{
    public partial class SerialData : Form
    {
        public SerialData()
        {
            InitializeComponent();
            UpdatePortSelection();
        }

        SerialPort _serialPort = new SerialPort();
        void SerialPortSetup()
        {
            _serialPort.Close();
            _serialPort = new SerialPort();
            _serialPort.PortName = "COM9"; // Set your COM port here
            _serialPort.BaudRate = 9600; // Set your baud rate here
            _serialPort.DataBits = 8;
            _serialPort.Parity = Parity.None;
            //_serialPort.StopBits = StopBits.One;

        }

        void SerialConnect()
        {
            _serialPort.Close();
            _serialPort.Open();
        }

        void SerialSend(byte[] data)
        {
            _serialPort.Write(OutputTextBox.Text);
        }

        void SerialRead()
        {
            //SerialTextBox.Text = _serialPort.ReadExisting();
            byte[] RXJim = new byte[_serialPort.BytesToRead];
            int byteNumber = 0;
            _serialPort.Read(RXJim, 0, RXJim.Length);

            foreach (byte b in RXJim)
            {
                byteNumber++;
                ComListBox.Items.Add($"{byteNumber}: {b} : {b:X2} {(char)b}");
            }
        }

        string[] GetSerialPorts()
        {
            return SerialPort.GetPortNames();
        }

        void UpdatePortSelection()
        {
            foreach (string port in GetSerialPorts())
            {
                PortsComboBox.Items.Add(port);
            }

            if (PortsComboBox.Items.Count > 0)
            {
                PortsComboBox.SelectedIndex = 0; // Select the first port by default
            }

        }

        byte[] AN1Read()
        {
            byte[] command = { 0x51 };
            return command;
        }

        // Event Handlers Below Here ---------------------------------------------
        private void ExitButton_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void ConnectButton_Click(object sender, EventArgs e)
        {
            SerialPortSetup();
            SerialConnect();
        }

        private void WriteButton_Click(object sender, EventArgs e)
        {
            SerialSend(AN1Read());
        }

        private void ReadButton_Click(object sender, EventArgs e)
        {
            SerialRead();
        }

        private void StatusStrip_ItemClicked(object sender, ToolStripItemClickedEventArgs e)
        {
            // Do nothing for now
        }

    }
}