class MedicalReferenceLink {
  final String title;
  final String subtitle;
  final String url;

  const MedicalReferenceLink({
    required this.title,
    required this.subtitle,
    required this.url,
  });
}

const String dietMedicalDisclaimer =
    'Diet recommendations in CPT are educational only and are not a '
    'diagnosis, treatment, or emergency-care substitute. Please consult a '
    'qualified physician or registered dietitian before making major diet or '
    'supplement changes.';

const List<MedicalReferenceLink> dietMedicalReferenceLinks =
    <MedicalReferenceLink>[
  MedicalReferenceLink(
    title: 'WHO Healthy Diet',
    subtitle: 'World Health Organization healthy-diet guidance',
    url: 'https://www.who.int/en/news-room/fact-sheets/detail/healthy-diet',
  ),
  MedicalReferenceLink(
    title: 'Dietary Guidelines',
    subtitle: 'USDA and HHS Dietary Guidelines for Americans',
    url: 'https://www.dietaryguidelines.gov/home',
  ),
  MedicalReferenceLink(
    title: 'NIH Supplements',
    subtitle: 'NIH Office of Dietary Supplements fact sheets',
    url: 'https://ods.od.nih.gov/factsheets/list-all/',
  ),
];
