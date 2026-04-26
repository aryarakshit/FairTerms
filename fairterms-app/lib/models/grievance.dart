/// Model representing grievance letter and RTI template data.
library;

/// Full grievance document returned by GET /analysis/:id/grievance.
class GrievanceData {
  final GrievanceLetter grievanceLetter;
  final RtiTemplate rtiTemplate;
  final List<String> legalReferences;
  final String? pdfUrl;

  const GrievanceData({
    required this.grievanceLetter,
    required this.rtiTemplate,
    required this.legalReferences,
    this.pdfUrl,
  });

  /// Creates [GrievanceData] from a JSON map.
  factory GrievanceData.fromJson(Map<String, dynamic> json) {
    return GrievanceData(
      grievanceLetter: GrievanceLetter.fromJson(
          json['grievance_letter'] as Map<String, dynamic>),
      rtiTemplate: RtiTemplate.fromJson(
          json['rti_template'] as Map<String, dynamic>),
      legalReferences: (json['legal_references'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      pdfUrl: json['pdf_url'] as String?,
    );
  }

  /// Converts this data to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'grievance_letter': grievanceLetter.toJson(),
      'rti_template': rtiTemplate.toJson(),
      'legal_references': legalReferences,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
    };
  }
}

/// Formal grievance letter content.
class GrievanceLetter {
  final String subject;
  final String body;

  const GrievanceLetter({
    required this.subject,
    required this.body,
  });

  /// Creates a [GrievanceLetter] from a JSON map.
  factory GrievanceLetter.fromJson(Map<String, dynamic> json) {
    return GrievanceLetter(
      subject: json['subject'] as String,
      body: json['body'] as String,
    );
  }

  /// Converts this letter to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'body': body,
    };
  }
}

/// RTI (Right to Information) application template.
class RtiTemplate {
  final String subject;
  final String body;
  final bool applicable;
  final String? reasonIfNotApplicable;

  const RtiTemplate({
    required this.subject,
    required this.body,
    required this.applicable,
    this.reasonIfNotApplicable,
  });

  /// Creates an [RtiTemplate] from a JSON map.
  factory RtiTemplate.fromJson(Map<String, dynamic> json) {
    return RtiTemplate(
      subject: json['subject'] as String,
      body: json['body'] as String,
      applicable: json['applicable'] as bool,
      reasonIfNotApplicable: json['reason_if_not_applicable'] as String?,
    );
  }

  /// Converts this template to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'body': body,
      'applicable': applicable,
      if (reasonIfNotApplicable != null)
        'reason_if_not_applicable': reasonIfNotApplicable,
    };
  }
}
