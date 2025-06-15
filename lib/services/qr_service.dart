import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:my_tool_shed/models/tool.dart';

class QRService {
  static String generateToolQRData(Tool tool) {
    final Map<String, dynamic> qrData = {
      'id': tool.id,
      'name': tool.name,
      'type': 'tool_shed_item',
    };
    return jsonEncode(qrData);
  }

  static Widget generateToolQRCode(Tool tool) {
    final String qrData = generateToolQRData(tool);
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
    );
  }

  static Tool? parseToolQRData(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);
      if (data['type'] != 'tool_shed_item') return null;
      return Tool(
        id: data['id'],
        name: data['name'],
      );
    } catch (e) {
      return null;
    }
  }
}
