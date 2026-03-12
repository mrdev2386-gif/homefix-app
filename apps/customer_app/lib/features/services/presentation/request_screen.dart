import 'package:flutter/material.dart';
import '../../custom_request/presentation/custom_request_screen.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  @override
  Widget build(BuildContext context) {
    // Directly show the CustomRequestScreen content
    return const CustomRequestScreen();
  }
}
