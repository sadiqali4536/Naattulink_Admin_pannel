// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class Bookings extends StatelessWidget {
//   Bookings({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('bookings')
//           .where('status', isEqualTo: 'requested')
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Center(child: Text("Something went wrong"));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final bookings = snapshot.data!.docs;

//         if (bookings.isEmpty) {
//           return const Center(child: Text("No pending worker requests."));
//         }

//         return ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: bookings.length,
//           itemBuilder: (context, index) {
//             final doc = bookings[index];
//             final data = doc.data() as Map<String, dynamic>;

//             return Card(
//               margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               elevation: 4,
//               child: ListTile(
//                 title: Text(data['serviceTitle'] ?? 'No Title'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Category: ${data['category'] ?? ''}"),
//                     Text("Requested by: ${data['workerName'] ?? 'Unknown'}"),
//                     Text("Price: ₹${data['discountPrice'] ?? '0'}"),
//                   ],
//                 ),
//                 trailing: ElevatedButton(
//                   onPressed: () async {
//                     try {
//                       await FirebaseFirestore.instance
//                           .collection('bookings')
//                           .doc(doc.id)
//                           .update({'status': 'approved'});

//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("✅ Work approved"),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("⚠️ Failed to approve work"),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                   child: const Text("Accept"),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Bookings extends StatelessWidget {
  const Bookings({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'requested')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data?.docs ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text("No pending worker requests."));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 4,
              child: ListTile(
                title: Text(data['serviceTitle'] ?? 'No Title'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Category: ${data['category'] ?? ''}"),
                    Text("Requested by: ${data['workerName'] ?? 'Unknown'}"),
                    Text("Price: ₹${data['discountPrice'] ?? '0'}"),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      final docId = doc.id; 
                      debugPrint("Approving booking with ID: $docId");

                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(docId)
                          .update({'status': 'approved'});

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Work approved"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error approving booking: $e");

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("⚠️ Failed to approve work"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Accept"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
