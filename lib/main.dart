import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For loading image assets
import 'package:flutter_blue/flutter_blue.dart'; // flutter_blue import
import 'bluetooth_service.dart' as CustomBluetoothService; // Alias for your custom BluetoothService

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final CustomBluetoothService.BluetoothService _bluetoothService = CustomBluetoothService.BluetoothService();
  List<BluetoothDevice> _devicesList = [];

  void _scanForDevices() {
    _bluetoothService.startScan((devices) {
      setState(() {
        _devicesList = devices;
      });
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    await _bluetoothService.connectToDevice(device);
    setState(() {
      // Update the UI if necessary after connecting
    });
  }

  Future<void> _sendImage() async {
    const imagePath = 'assets/sample_image.png'; // Update this path to your image location
    final byteData = await rootBundle.load(imagePath);
    final base64Image = base64Encode(byteData.buffer.asUint8List());

    final Uint8List imageData = await _bluetoothService.base64ToUint8List(base64Image);
    await _bluetoothService.sendData(imageData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Demo'),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: _scanForDevices,
            child: Text('Start Scanning'),
          ),
          ElevatedButton(
            onPressed: _sendImage,
            child: Text('Send Image'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
                  subtitle: Text(device.id.toString()),
                  onTap: () {
                    _connectToDevice(device);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
