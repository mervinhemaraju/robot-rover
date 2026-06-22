import 'package:car_remote_controller/ui/widgets/placeholder_livefeed.dart';
import 'package:car_remote_controller/ui/widgets/status_chip.dart';
import 'package:flutter/material.dart';

class LivefeedWidget extends StatelessWidget {
  const LivefeedWidget({super.key});

  static const Color _green = Color(0xFF1E9E4F);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: Stack(
        children: [
          const Positioned.fill(child: PlaceholderLiveFeedWidget()),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                // TODO: wire link status and battery level to telemetry.
                const StatusChip(
                  icon: Icon(
                    Icons.signal_cellular_alt,
                    size: 18,
                    color: _green,
                  ),
                  label: "LINK",
                ),
                const SizedBox(width: 8),
                const StatusChip(
                  // Material battery icons are vertical; lay it flat.
                  icon: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(Icons.battery_full, size: 20, color: _green),
                  ),
                  label: "78%",
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0xFFE5E2DC), width: 1.5),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      print("Settings pressed");
                    },
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.settings,
                      size: 18,
                      color: Color(0xFF14181C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
