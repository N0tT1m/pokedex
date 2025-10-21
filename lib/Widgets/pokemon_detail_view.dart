import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/saved_pokemon.dart';

class PokemonDetailView extends StatelessWidget {
  final SavedPokemon pokemon;

  const PokemonDetailView({Key? key, required this.pokemon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.displayName),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildBasicInfo(),
            _buildStats(),
            _buildIVsSection(),
            _buildEVsSection(),
            if (pokemon.moves != null && pokemon.moves!.isNotEmpty)
              _buildMovesSection(),
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Column(
        children: [
          if (pokemon.spriteUrl != null)
            CachedNetworkImage(
              imageUrl: pokemon.spriteUrl!,
              width: 120,
              height: 120,
              errorWidget: (context, url, error) => const Icon(
                Icons.catching_pokemon,
                size: 120,
              ),
            )
          else
            const Icon(Icons.catching_pokemon, size: 120),
          const SizedBox(height: 16),
          Text(
            pokemon.displayName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (pokemon.nickname != null)
            Text(
              pokemon.speciesName[0].toUpperCase() + pokemon.speciesName.substring(1),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (pokemon.isShiny) ...[
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
              ],
              if (pokemon.gender != null) ...[
                Icon(
                  pokemon.gender == 'Male'
                      ? Icons.male
                      : pokemon.gender == 'Female'
                          ? Icons.female
                          : Icons.transgender,
                  color: pokemon.gender == 'Male'
                      ? Colors.blue
                      : pokemon.gender == 'Female'
                          ? Colors.pink
                          : Colors.grey,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Level', '${pokemon.level}'),
            _buildInfoRow('Nature', pokemon.nature),
            if (pokemon.ability != null)
              _buildInfoRow('Ability', pokemon.ability!),
            if (pokemon.game != null)
              _buildInfoRow('Game', pokemon.game!),
            if (pokemon.location != null)
              _buildInfoRow('Caught at', pokemon.location!),
            if (pokemon.pokeball != null)
              _buildInfoRow('Pokeball', pokemon.pokeball!),
            _buildInfoRow('Caught on', dateFormat.format(pokemon.caughtDate)),
            if (pokemon.friendship != null)
              _buildInfoRow('Friendship', '${pokemon.friendship}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...pokemon.calculatedStats.entries.map((entry) {
              final baseStat = pokemon.baseStats[entry.key] ?? 0;
              final maxStat = entry.key == 'HP' ? 714 : 614; // Approximate max
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / maxStat,
                      backgroundColor: Colors.grey.shade200,
                      color: _getStatColor(entry.value, baseStat),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Base: $baseStat',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getStatColor(int stat, int baseStat) {
    if (stat >= baseStat * 2) return Colors.purple;
    if (stat >= baseStat * 1.5) return Colors.blue;
    if (stat >= baseStat * 1.2) return Colors.green;
    return Colors.orange;
  }

  Widget _buildIVsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Individual Values (IVs)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${pokemon.totalIVs}/186 (${pokemon.ivPercentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getIVColor(pokemon.ivPercentage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pokemon.ivs.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Row(
                      children: [
                        Text(
                          '${entry.value}/31',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getIVColor((entry.value / 31) * 100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: entry.value / 31,
                            backgroundColor: Colors.grey.shade200,
                            color: _getIVColor((entry.value / 31) * 100),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getIVColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEVsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Effort Values (EVs)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${pokemon.totalEVs}/510',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pokemon.evs.entries.map((entry) {
              if (entry.value == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Row(
                      children: [
                        Text(
                          '${entry.value}/252',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: entry.value / 252,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.blue,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            if (pokemon.totalEVs == 0)
              const Center(
                child: Text(
                  'No EVs trained',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovesSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Moves',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...pokemon.moves!.map((move) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Text(move),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Pokemon ID', pokemon.id),
            _buildInfoRow('Species', pokemon.speciesName),
            if (pokemon.isShiny)
              _buildInfoRow('Shiny', 'Yes ✨'),
          ],
        ),
      ),
    );
  }
}
