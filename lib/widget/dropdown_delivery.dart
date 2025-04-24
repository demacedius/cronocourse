import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeliveryZoneDropdown extends StatelessWidget {
  final String? selectedCity;
  final Function(String city, double courseFee, double restaurantFee) onChanged;

  const DeliveryZoneDropdown({
    super.key,
    required this.selectedCity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('delivery_zone').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final zones = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Ville de livraison"),
          items: zones.map<DropdownMenuItem<String>>((zone) {
            final data = zone.data();
            return DropdownMenuItem<String>(
              value: data['name'],
              child: Text(
                "${data['name']} - Courses: ${data['price']} € / Resto: ${data['restaurant_fees']} €",
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final selected = zones.firstWhere((z) => z.data()['name'] == value).data();
            final courseFee = (selected['price'] as num).toDouble();
            final restaurantFee = (selected['restaurant_fees'] as num).toDouble();

            onChanged(value, courseFee, restaurantFee);
          },
          value: selectedCity,
        );
      },
    );
  }
}
