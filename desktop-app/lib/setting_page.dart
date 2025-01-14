import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _masterVolume = 75; // Default Master Volume
  double _microphoneVolume = 60; // Default Microphone Volume

  String _selectedAudioInput = 'Default Microphone';
  String _selectedAudioOutput = 'Headphones (High Definition Audio)';

  final List<String> _audioInputs = [
    'Default Microphone',
    'External USB Microphone',
    'Built-in Microphone',
  ];

  final List<String> _audioOutputs = [
    'Headphones (High Definition Audio)',
    'Speakers',
    'Bluetooth Audio',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Audio Input Dropdown-----------------------------------------------
          const Text(
            'Audio Input',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1E1E2E),
            value: _selectedAudioInput,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(255, 18, 19, 27),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _audioInputs.map((input) {
              return DropdownMenuItem(
                value: input,
                child: Text(input, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAudioInput = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // Audio Output Dropdown----------------------------------------------
          const Text(
            'Audio Output',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1E1E2E),
            value: _selectedAudioOutput,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(255, 18, 19, 27),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _audioOutputs.map((output) {
              return DropdownMenuItem(
                value: output,
                child: Text(output, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAudioOutput = value!;
              });
            },
          ),
          const SizedBox(height: 30),

          // Master Volume Slider-----------------------------------------------
          const Text(
            'Master Volume',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white),
              Expanded(
                child: Slider(
                  value: _masterVolume,
                  min: 0,
                  max: 100,
                  activeColor: const Color(0xFF4E46E4),
                  inactiveColor: Colors.grey,
                  onChanged: (value) {
                    setState(() {
                      _masterVolume = value;
                    });
                  },
                ),
              ),
              Text(
                '${_masterVolume.round()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Microphone Volume Slider-------------------------------------------
          const Text(
            'Microphone Volume',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              const Icon(Icons.mic, color: Colors.white),
              Expanded(
                child: Slider(
                  value: _microphoneVolume,
                  min: 0,
                  max: 100,
                  activeColor: const Color(0xFF4E46E4),
                  inactiveColor: Colors.grey,
                  onChanged: (value) {
                    setState(() {
                      _microphoneVolume = value;
                    });
                  },
                ),
              ),
              Text(
                '${_microphoneVolume.round()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
