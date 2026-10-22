/// Modèle d'entrée pour la création de micro-jalons initiaux lors de la création d'une tâche de fond
class MilestoneInput {
  final String title;
  final int durationMinutes;

  const MilestoneInput({
    required this.title,
    this.durationMinutes = 30,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'durationMinutes': durationMinutes,
      };

  factory MilestoneInput.fromJson(Map<String, dynamic> json) => MilestoneInput(
        title: json['title'] as String,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      );
}
