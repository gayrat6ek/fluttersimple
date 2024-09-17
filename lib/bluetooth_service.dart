import 'dart:convert'; // For Base64 encoding
import 'dart:typed_data'; // For handling byte data
import 'package:flutter/services.dart'; // For loading image assets
import 'package:flutter_blue/flutter_blue.dart';
import 'package:image/image.dart' as img; // For handling image processing
import 'package:esc_pos_utils/esc_pos_utils.dart'; // For ESC/POS commands

class BluetoothService {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;

  // Function to start scanning for Bluetooth devices
  void startScan(Function(List<BluetoothDevice>) onScanResult) {
    devicesList.clear(); // Clear the list of devices before scanning

    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        final device = result.device;
        if (!devicesList.contains(device)) {
          devicesList.add(device);
        }
      }
      onScanResult(devicesList); // Pass the list of devices back to the UI
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

    // Write data to the Bluetooth device
    final services = await connectedDevice!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          try {
            await characteristic.write(data);
            print('Data sent successfully');
          } catch (e) {
            print('Failed to send data: $e');
          }
          return;
        }
      }
    }
    print('No writable characteristic found');
  }

  // Function to convert image to Base64 and then to Uint8List
  Future<Uint8List> imageToUint8List(String imagePath) async {
    final byteData = await rootBundle.load(imagePath);
    return byteData.buffer.asUint8List();
  }

  // Function to print image as bitmap using ESC/POS commands
  Future<void> printImage(String imagePath) async {
    if (connectedDevice == null) {
      print('No device connected');
      return;
    }

    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();

    // Convert the image to a format the printer can understand (Monochrome)
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      print('Failed to load image');
      return;
    }

    // Convert the image to monochrome (black and white)
    final img.Image resizedImage = img.copyResize(image, width: 384); // Resize to printer's width
    final img.Image monoImage = img.grayscale(resizedImage);

    // Prepare ESC/POS commands
    final profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm80, profile);
    final List<int> escPosCommands = [];

    escPosCommands.addAll(generator.imageRaster(monoImage));

    // Send the ESC/POS commands to the Bluetooth device
    await sendData(Uint8List.fromList(escPosCommands));
  }
}
