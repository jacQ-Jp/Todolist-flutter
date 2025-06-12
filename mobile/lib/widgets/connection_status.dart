import 'package:flutter/material.dart';
import '../main.dart';

class ConnectionStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (ConnectionStatus.isServerAvailable) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Online', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Demo Mode', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
    }
  }
}