import 'package:flutter/material.dart';

class SwitchButtons extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const SwitchButtons({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton("course", context),
        _buildButton("restaurant", context),
      ],
    );
  }

  Widget _buildButton(String label, BuildContext context) {
    final bool isSelected = selected == label;

    return GestureDetector(
      onTap: () => onChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black),
        ),
        child: Row(
          children: [
            Icon(
              label == "course" ? Icons.shopping_cart : Icons.delivery_dining,
              color: isSelected ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              label == "course" ? "Courses" : "Restaurants",
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
