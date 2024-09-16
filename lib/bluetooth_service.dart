import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/services.dart'; // For loading image assets

class BluetoothService {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;

  // Function to start scanning for Bluetooth devices
  void startScan(Function(List<BluetoothDevice>) onScanResult) {
    devicesList.clear();

    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        final device = result.device;
        if (!devicesList.contains(device)) {
          devicesList.add(device);
        }
      }
      onScanResult(devicesList);
    });

    flutterBlue.stopScan();
  }

  // Function to connect to a specific device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
      print('Connected to device: ${device.name}');
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  // Function to disconnect from a device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await device.disconnect();
    connectedDevice = null;
    print('Disconnected from device: ${device.name}');
  }

  // Function to send data to the connected Bluetooth device
  Future<void> sendData(Uint8List data) async {
    if (connectedDevice == null) {
      print('No device connected');
      return;
    }

    final services = await connectedDevice!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          try {
            await characteristic.write(data);
            print('Data sent successfully');
            // Read the response if the characteristic supports notifications or reading
            if (characteristic.properties.read || characteristic.properties.notify) {
              await _readResponse(characteristic);
            }
          } catch (e) {
            print('Failed to send data: $e');
          }
          return;
        }
      }
    }
    print('No writable characteristic found');
  }

  // Function to read response from a Bluetooth characteristic
  Future<void> _readResponse(BluetoothCharacteristic characteristic) async {
    try {
      // Read the data from the characteristic
      final response = await characteristic.read();
      final responseString = utf8.decode(response);
      print('Response received: $responseString');
    } catch (e) {
      print('Failed to read response: $e');
    }
  }

  // Function to convert image to Base64 and then to Uint8List
  Future<Uint8List> imageToUint8List(String imagePath) async {
    final byteData = await rootBundle.load(imagePath);
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> base64ToUint8List(String base64String) async {
    final bytes = base64Decode(base64String);
    return Uint8List.fromList(bytes);
  }
}
