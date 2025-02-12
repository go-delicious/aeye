import 'package:flutter/material.dart';
import '../services/llm_service.dart';

class ModelDetailView extends StatelessWidget {
  final ModelInfo model;
  final bool isSelected;
  final VoidCallback onSelect;
  final bool isImageModel;

  const ModelDetailView({
    super.key,
    required this.model,
    required this.isSelected,
    required this.onSelect,
    this.isImageModel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'model_name_${model.id}',
          child: Text(model.name),
        ),
        actions: [
          if (isSelected)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            TextButton(
              onPressed: () {
                onSelect();
                Navigator.of(context).pop();
              },
              child: Text('Select as ${isImageModel ? 'Image Model' : 'Main Model'}'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model ID',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(model.id),
            const SizedBox(height: 16),
            
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(model.description),
            const SizedBox(height: 16),

            Text(
              'Context Length',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('${model.contextLength.toInt()} tokens'),
            const SizedBox(height: 16),

            Text(
              'Pricing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Prompt: \$${model.promptPrice.toStringAsFixed(6)} per token\n'
              'Completion: \$${model.completionPrice.toStringAsFixed(6)} per token',
            ),
            const SizedBox(height: 16),

            if (model.tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: model.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                )).toList(),
              ),
            ],

            if (model.capabilities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Capabilities',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: model.capabilities.map((cap) => Chip(
                  label: Text(cap),
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                )).toList(),
              ),
            ],

            if (model.supportsVision) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.image, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Supports Vision/Image Input',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 