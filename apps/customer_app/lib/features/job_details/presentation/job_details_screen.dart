import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String bookingId;

  const JobDetailsScreen({super.key, required this.booking, required this.bookingId});

  Future<void> _cancelBooking(BuildContext context) async {
       final confirm = await showDialog<bool>(
           context: context, 
           builder: (_) => AlertDialog(
               title: const Text("Cancel Booking?"),
               content: const Text("Are you sure? Cancellation fees may apply."),
               actions: [
                   TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
                   TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Cancel")),
               ],
           )
       );
       
       if(confirm != true) return;

       try {
            if (bookingId.isEmpty) {
              debugPrint('[PATH GUARD] blocked empty id in _cancelBooking');
              return;
            }
            debugPrint('[WRITE GUARD] Direct write blocked in _cancelBooking');
            final callable = FirebaseFunctions.instance.httpsCallable('cancelBooking');
            await callable.call({'bookingId': bookingId});
            
            if(context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Cancelled")));
                 Navigator.pop(context);
            }
       } catch(e) {
           debugPrint('❌ [Booking] Cancel failed: $e');
           if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
       }
  }

  Future<void> _downloadInvoice(BuildContext context) async {
      try {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating Invoice...")));
          final res = await FirebaseFunctions.instance.httpsCallable('generateInvoicePDF').call({'bookingId': bookingId});
          final url = res.data['pdfUrl'];
          if(url != null) {
              launchUrl(Uri.parse(url));
          } else {
              if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invoice generation failed.")));
          }
      } catch(e) {
          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
  }
  
  void _raiseDispute(BuildContext context) {
      showDialog(context: context, builder: (_) => _DisputeDialog(bookingId: bookingId, customerId: booking['customerId']));
  }

  @override
  Widget build(BuildContext context) {
      final status = booking['status'] ?? 'pending';
      final isCompleted = status == 'completed';
      final isCancellable = ['pending', 'payment_pending', 'confirmed', 'assigned'].contains(status);

      return Scaffold(
          appBar: AppBar(title: const Text("Booking Details")),
          body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(booking['serviceTitle'] ?? 'Service', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Status: ${status.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 20),
                      Text("Scheduled: ${booking['scheduledTime']}"),
                       // If Timestamp, format it
                      const Divider(),
                      const SizedBox(height: 20),
                      if(isCompleted) 
                          ElevatedButton.icon(
                              onPressed: () => _downloadInvoice(context), 
                              icon: const Icon(Icons.download), 
                              label: const Text("Download Invoice")
                          ),
                      
                      const Spacer(),
                      if(isCancellable)
                          SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                  onPressed: () => _cancelBooking(context),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text("Cancel Booking"),
                              )
                          ),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () => _raiseDispute(context),
                          child: const Text("Need Help? Raise an Issue"),
                      )
                  ]
              )
          )
      );
  }
}

class _DisputeDialog extends StatefulWidget {
    final String bookingId;
    final String customerId;
    const _DisputeDialog({required this.bookingId, required this.customerId});
    
    @override
    State<_DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<_DisputeDialog> {
    final _controller = TextEditingController();
    String _type = 'service_quality';
    bool _loading = false;

    Future<void> _submit() async {
        if(_controller.text.isEmpty) return;
        setState(() => _loading = true);
        try {
            debugPrint('[WRITE GUARD] Direct write blocked in _submit dispute');
            final callable = FirebaseFunctions.instance.httpsCallable('reportIssueCallable');
            await callable.call({
                'bookingId': widget.bookingId,
                'customerId': widget.customerId,
                'issueType': _type,
                'description': _controller.text,
            });
            if(mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Issue Reported")));
            }
        } catch(e) {
             debugPrint('❌ [Dispute] Submission failed: $e');
             if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Report an Issue"),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    DropdownButtonFormField<String>(
                        value: _type,
                        items: const [
                            DropdownMenuItem(value: 'service_quality', child: Text("Service Quality")),
                            DropdownMenuItem(value: 'technician_behavior', child: Text("Technician Behavior")),
                            DropdownMenuItem(value: 'payment_issue', child: Text("Payment Issue")),
                            DropdownMenuItem(value: 'other', child: Text("Other")),
                        ],
                        onChanged: (v) => setState(() => _type = v!),
                        decoration: const InputDecoration(labelText: "Issue Type"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _controller,
                        decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                        maxLines: 3,
                    )
                ]
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: _loading ? null : _submit, 
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Submit")
                )
            ]
        );
    }
}
