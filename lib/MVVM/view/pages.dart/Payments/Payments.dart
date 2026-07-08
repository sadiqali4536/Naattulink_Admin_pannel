import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final List<Map<String, String>> transactions = List.generate(
    10,
    (index) => {
      'transactionId': '#${index + 1}',
      'amount': '\$${[800, 1000, 500, 600, 800, 600, 800, 500, 400, 500][index]}',
      'bookingId': '#0${(index + 1)}',
      'status': 'Paid',
      'dateTime': '02 Feb 25, 5:15:10',
    },
  );

  PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Button Top Right
            Align(
              alignment: Alignment.topRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.filter_list),
                label: const Text('Filter'),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 16),

            // Transaction Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: Text('Transaction ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Date&Time', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const Divider(height: 0),

                  // Rows
                  ...transactions.map(
                    (tx) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(child: Text(tx['transactionId']!)),
                              Expanded(child: Text(tx['amount']!)),
                              Expanded(child: Text(tx['bookingId']!)),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 20,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tx['status']!,
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Expanded(child: Text(tx['dateTime']!)),
                            ],
                          ),
                        ),
                        const Divider(height: 0),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      
    );
  }
}
