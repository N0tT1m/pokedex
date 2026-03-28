import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../nuzlocke/nuzlocke_tracker_screen.dart';
import '../favorites_screen.dart';
import '../News.dart';
import '../databases/walkthrough_screen.dart';

class MoreHub extends StatelessWidget {
  const MoreHub({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More'), backgroundColor: Colors.red),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _tile(context, 'Favorites', Icons.favorite, Colors.red, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
          }),
          _tile(context, 'Nuzlocke Tracker', Icons.catching_pokemon, Colors.deepOrange, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NuzlockeTrackerScreen()));
          }),
          _tile(context, 'Walkthrough Checklist', Icons.checklist, Colors.green, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WalkthroughScreen()));
          }),
          _tile(context, 'News & Events', Icons.newspaper, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const News()));
          }),
          const Divider(),
          _tile(context, 'Dark Mode', Icons.dark_mode, Colors.indigo, () {
            _toggleDarkMode(context);
          }),
          _tile(context, 'Clear Cache', Icons.delete_sweep, Colors.grey, () {
            _clearCache(context);
          }),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _toggleDarkMode(BuildContext context) async {
    final box = await Hive.openBox('settings');
    final current = box.get('darkMode', defaultValue: false);
    await box.put('darkMode', !current);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dark mode ${!current ? "enabled" : "disabled"}. Restart app to apply.')),
      );
    }
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached API data. Your saved Pokemon and teams will not be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Clear the PokeAPI in-memory cache
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
