// Mock data models & sample data for Shiksha Verse
// Replace with real API calls when backend is ready.

// ── Content Type ──────────────────────────────────────────────────────────────

enum ContentType { video, note, mindmap, formula }

extension ContentTypeLabel on ContentType {
  String get label {
    switch (this) {
      case ContentType.video:   return '🎬 Videos';
      case ContentType.note:    return '📝 Notes';
      case ContentType.mindmap: return '🗺️ Mind Maps';
      case ContentType.formula: return '📐 Formulas';
    }
  }
  String get apiKey {
    switch (this) {
      case ContentType.video:   return 'video';
      case ContentType.note:    return 'note';
      case ContentType.mindmap: return 'mindmap';
      case ContentType.formula: return 'formula';
    }
  }
}

// ── Subject Model ─────────────────────────────────────────────────────────────

class SubjectModel {
  final String id;
  final String name;
  final String icon;       // emoji
  final String colorHex;  // e.g. '#4F46E5'
  final int chapterCount;
  final int videoCount;
  final int noteCount;
  final int mindmapCount;
  final int formulaCount;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.chapterCount,
    this.videoCount   = 0,
    this.noteCount    = 0,
    this.mindmapCount = 0,
    this.formulaCount = 0,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
    id:            json['id']             as String,
    name:          json['name']           as String,
    icon:          json['icon']           as String? ?? '📚',
    colorHex:      json['color_hex']      as String? ?? '#4F46E5',
    chapterCount:  int.tryParse(json['chapter_count'].toString()) ?? 0,
    videoCount:    int.tryParse(json['video_count'].toString())   ?? 0,
    noteCount:     int.tryParse(json['note_count'].toString())    ?? 0,
    mindmapCount:  int.tryParse(json['mindmap_count'].toString()) ?? 0,
    formulaCount:  int.tryParse(json['formula_count'].toString()) ?? 0,
  );
}

// ── Chapter Model ─────────────────────────────────────────────────────────────

class ChapterModel {
  final String id;
  final String subjectId;
  final String title;
  final int order;
  final int videosCount;
  final int notesCount;
  final int mindMapsCount;
  final int formulasCount;

  const ChapterModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
    this.videosCount   = 0,
    this.notesCount    = 0,
    this.mindMapsCount = 0,
    this.formulasCount = 0,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) => ChapterModel(
    id:            json['id']              as String,
    subjectId:     json['subject_id']      as String,
    title:         json['title']           as String,
    order:         json['chapter_order']   as int? ?? 0,
    videosCount:   int.tryParse(json['videos_count'].toString())    ?? 0,
    notesCount:    int.tryParse(json['notes_count'].toString())     ?? 0,
    mindMapsCount: int.tryParse(json['mindmaps_count'].toString())  ?? 0,
    formulasCount: int.tryParse(json['formulas_count'].toString())  ?? 0,
  );
}

// ── Content Item Model ────────────────────────────────────────────────────────

class ContentItemModel {
  final String id;
  final String chapterId;
  final ContentType type;
  final String title;
  final String? description;
  final String? url;
  final String? thumbnailUrl;
  final int? durationMin;
  final String? content;

  const ContentItemModel({
    required this.id,
    required this.chapterId,
    required this.type,
    required this.title,
    this.description,
    this.url,
    this.thumbnailUrl,
    this.durationMin,
    this.content,
  });

  factory ContentItemModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'note';
    final type = ContentType.values.firstWhere(
      (t) => t.apiKey == typeStr,
      orElse: () => ContentType.note,
    );
    return ContentItemModel(
      id:          json['id']            as String,
      chapterId:   json['chapter_id']    as String,
      type:        type,
      title:       json['title']         as String,
      description: json['description']   as String?,
      url:         json['url']           as String?,
      thumbnailUrl:json['thumbnail_url'] as String?,
      durationMin: json['duration_min']  as int?,
      content:     json['content']       as String?,
    );
  }
}

// ── Legacy: CourseModel (still used for Continue Learning card) ───────────────

class CourseModel {
  final String id;
  final String title;
  final String instructor;
  final String subject;
  final String duration;
  final double progress; // 0.0 – 1.0
  final String thumbnailUrl;
  final int lessons;
  final String difficulty;
  final bool isLive;
  final String? videoUrl;

  const CourseModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.subject,
    required this.duration,
    required this.progress,
    required this.thumbnailUrl,
    required this.lessons,
    required this.difficulty,
    this.isLive = false,
    this.videoUrl,
  });
}

class ShortModel {
  final String id;
  final String title;
  final String instructor;
  final String subject;
  final String duration;
  final String thumbnailUrl;
  final int views;
  final bool isLiked;

  const ShortModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.subject,
    required this.duration,
    required this.thumbnailUrl,
    required this.views,
    this.isLiked = false,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class UserModel {
  final String name;
  final String username;
  final String avatarUrl;
  final String grade;
  final int streakDays;
  final int xp;
  final int rank;
  final List<String> subjects;

  const UserModel({
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.grade,
    required this.streakDays,
    required this.xp,
    required this.rank,
    required this.subjects,
  });
}

// ── Sample Data ───────────────────────────────────────────────────────────────

final mockUser = UserModel(
  name: 'Aarav Singh',
  username: '@aarav.sv',
  avatarUrl: 'https://i.pravatar.cc/150?img=3',
  grade: 'Class 12',
  streakDays: 14,
  xp: 3840,
  rank: 42,
  subjects: ['Physics', 'Mathematics', 'Chemistry', 'Biology'],
);

// Subjects
final mockSubjects = [
  const SubjectModel(id: 'sub1', name: 'Physics',     icon: '⚛️',  colorHex: '#4F46E5', chapterCount: 4, videoCount: 4, noteCount: 3, mindmapCount: 2, formulaCount: 4),
  const SubjectModel(id: 'sub2', name: 'Mathematics', icon: '📐',  colorHex: '#7C3AED', chapterCount: 4, videoCount: 4, noteCount: 3, mindmapCount: 2, formulaCount: 4),
  const SubjectModel(id: 'sub3', name: 'Chemistry',   icon: '🧪',  colorHex: '#059669', chapterCount: 3, videoCount: 3, noteCount: 3, mindmapCount: 1, formulaCount: 3),
  const SubjectModel(id: 'sub4', name: 'Biology',     icon: '🌱',  colorHex: '#D97706', chapterCount: 3, videoCount: 3, noteCount: 3, mindmapCount: 2, formulaCount: 1),
];

// Chapters per subject
final mockChapters = {
  'sub1': [
    const ChapterModel(id: 'ch1', subjectId: 'sub1', title: 'Laws of Motion',       order: 0, videosCount: 1, notesCount: 1, mindMapsCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch2', subjectId: 'sub1', title: 'Work, Energy & Power', order: 1, videosCount: 1, notesCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch3', subjectId: 'sub1', title: 'Waves & Oscillations', order: 2, videosCount: 1, mindMapsCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch4', subjectId: 'sub1', title: 'Electrostatics',       order: 3, videosCount: 1, notesCount: 1, formulasCount: 1),
  ],
  'sub2': [
    const ChapterModel(id: 'ch5', subjectId: 'sub2', title: 'Limits & Continuity',     order: 0, videosCount: 1, notesCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch6', subjectId: 'sub2', title: 'Differentiation',          order: 1, videosCount: 1, mindMapsCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch7', subjectId: 'sub2', title: 'Integration',              order: 2, videosCount: 1, notesCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch8', subjectId: 'sub2', title: 'Matrices & Determinants',  order: 3, videosCount: 1),
  ],
  'sub3': [
    const ChapterModel(id: 'ch9',  subjectId: 'sub3', title: 'Atomic Structure',       order: 0, videosCount: 1, notesCount: 1, mindMapsCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch10', subjectId: 'sub3', title: 'Chemical Bonding',       order: 1, videosCount: 1, notesCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch11', subjectId: 'sub3', title: 'Organic Chemistry Basics', order: 2, videosCount: 1),
  ],
  'sub4': [
    const ChapterModel(id: 'ch12', subjectId: 'sub4', title: 'Cell: Structure & Function', order: 0, videosCount: 1, notesCount: 1, mindMapsCount: 1),
    const ChapterModel(id: 'ch13', subjectId: 'sub4', title: 'Genetics & Heredity',        order: 1, videosCount: 1, notesCount: 1, formulasCount: 1),
    const ChapterModel(id: 'ch14', subjectId: 'sub4', title: 'Human Physiology',            order: 2, videosCount: 1, notesCount: 1, mindMapsCount: 1),
  ],
};

// Content items per chapter
final mockContent = {
  'ch1': [
    const ContentItemModel(id: 'ci1',  chapterId: 'ch1', type: ContentType.video,   title: "Newton's 3 Laws — Full Lecture",    durationMin: 28, thumbnailUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600'),
    const ContentItemModel(id: 'ci2',  chapterId: 'ch1', type: ContentType.note,    title: 'Laws of Motion — Revision Notes',   content: "Newton's 1st Law: Inertia\nNewton's 2nd Law: F = ma\nNewton's 3rd Law: Action-Reaction"),
    const ContentItemModel(id: 'ci3',  chapterId: 'ch1', type: ContentType.mindmap, title: 'Laws of Motion Mind Map'),
    const ContentItemModel(id: 'ci4',  chapterId: 'ch1', type: ContentType.formula, title: 'Key Formulae — Laws of Motion',     content: 'F = ma\nImpulse J = FΔt = Δp\nFriction f = μN'),
  ],
  'ch2': [
    const ContentItemModel(id: 'ci5',  chapterId: 'ch2', type: ContentType.video,   title: 'Work-Energy Theorem Explained',     durationMin: 35, thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600'),
    const ContentItemModel(id: 'ci6',  chapterId: 'ch2', type: ContentType.note,    title: 'Energy Conservation Notes',         content: 'KE = ½mv²\nPE = mgh\nKE + PE = constant'),
    const ContentItemModel(id: 'ci7',  chapterId: 'ch2', type: ContentType.formula, title: 'Work & Power Formulae',             content: 'W = Fd cosθ\nP = W/t = Fv'),
  ],
  'ch5': [
    const ContentItemModel(id: 'ci8',  chapterId: 'ch5', type: ContentType.video,   title: 'Limits from First Principles',      durationMin: 31),
    const ContentItemModel(id: 'ci9',  chapterId: 'ch5', type: ContentType.note,    title: "L'Hôpital's Rule Notes",            content: 'Use when 0/0 or ∞/∞ form.\nlim f(x)/g(x) = lim f\'(x)/g\'(x)'),
    const ContentItemModel(id: 'ci10', chapterId: 'ch5', type: ContentType.formula, title: 'Standard Limits',                   content: 'lim(x→0) sinx/x = 1\nlim(x→0)(1+x)^(1/x) = e'),
  ],
  'ch7': [
    const ContentItemModel(id: 'ci11', chapterId: 'ch7', type: ContentType.video,   title: 'Integration by Parts — Full Guide', durationMin: 52),
    const ContentItemModel(id: 'ci12', chapterId: 'ch7', type: ContentType.note,    title: 'Integration Techniques Notes',      content: 'By Parts: ∫u dv = uv - ∫v du\nSubstitution: ∫f(g(x))g\'(x)dx'),
    const ContentItemModel(id: 'ci13', chapterId: 'ch7', type: ContentType.formula, title: 'Standard Integrals',               content: '∫xⁿdx = xⁿ⁺¹/(n+1)\n∫sinx dx = -cosx\n∫eˣdx = eˣ'),
  ],
  'ch9': [
    const ContentItemModel(id: 'ci14', chapterId: 'ch9', type: ContentType.video,   title: 'Bohr Model & Quantum Numbers',      durationMin: 29),
    const ContentItemModel(id: 'ci15', chapterId: 'ch9', type: ContentType.note,    title: 'Quantum Numbers — Quick Reference', content: 'n: principal\nl: azimuthal (0 to n-1)\nm: magnetic (-l to +l)\ns: spin (±½)'),
    const ContentItemModel(id: 'ci16', chapterId: 'ch9', type: ContentType.mindmap, title: 'Atomic Models Timeline'),
    const ContentItemModel(id: 'ci17', chapterId: 'ch9', type: ContentType.formula, title: 'Atomic Structure Formulae',         content: 'E = -13.6/n² eV\nλ = h/mv (de Broglie)'),
  ],
  'ch12': [
    const ContentItemModel(id: 'ci18', chapterId: 'ch12', type: ContentType.video,   title: 'Plant vs Animal Cell',            durationMin: 26),
    const ContentItemModel(id: 'ci19', chapterId: 'ch12', type: ContentType.note,    title: 'Cell Organelles Notes',           content: 'Mitochondria: ATP production\nRibosome: protein synthesis\nNucleus: DNA storage'),
    const ContentItemModel(id: 'ci20', chapterId: 'ch12', type: ContentType.mindmap, title: 'Cell Organelles Mind Map'),
  ],
};

// Continue Learning card — one in-progress course (kept for home screen)
const mockResumeCourse = CourseModel(
  id: 'c1',
  title: 'Waves & Optics: Complete Crash Course',
  instructor: 'Dr. Priya Sharma',
  subject: 'Physics',
  duration: '4h 20m',
  progress: 0.62,
  thumbnailUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600',
  lessons: 18,
  difficulty: 'Advanced',
);

final mockCourses = [
  const CourseModel(
    id: 'c1',
    title: 'Waves & Optics: Complete Crash Course',
    instructor: 'Dr. Priya Sharma',
    subject: 'Physics',
    duration: '4h 20m',
    progress: 0.62,
    thumbnailUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600',
    lessons: 18,
    difficulty: 'Advanced',
  ),
  const CourseModel(
    id: 'c2',
    title: 'Integral Calculus Mastery',
    instructor: 'Prof. Rajan Mehta',
    subject: 'Mathematics',
    duration: '6h 15m',
    progress: 0.35,
    thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=600',
    lessons: 24,
    difficulty: 'Intermediate',
  ),
  const CourseModel(
    id: 'c3',
    title: 'Organic Chemistry: Reactions',
    instructor: 'Dr. Sunita Rao',
    subject: 'Chemistry',
    duration: '3h 45m',
    progress: 0.10,
    thumbnailUrl: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=600',
    lessons: 14,
    difficulty: 'Advanced',
  ),
  const CourseModel(
    id: 'c4',
    title: 'Human Physiology Deep Dive',
    instructor: 'Dr. Ankit Gupta',
    subject: 'Biology',
    duration: '5h 00m',
    progress: 0.78,
    thumbnailUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=600',
    lessons: 20,
    difficulty: 'Intermediate',
  ),
];

final mockShorts = [
  const ShortModel(id: 's1', title: "Newton's 3rd Law in 60 seconds", instructor: 'Dr. Priya Sharma', subject: 'Physics',     duration: '1:02', thumbnailUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400', views: 24800),
  const ShortModel(id: 's2', title: 'Why does ice float? Quick Explain', instructor: 'Dr. Sunita Rao',  subject: 'Chemistry', duration: '0:58', thumbnailUrl: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=400', views: 18500, isLiked: true),
  const ShortModel(id: 's3', title: 'Integration by Parts — 90 seconds', instructor: 'Prof. Rajan Mehta', subject: 'Mathematics', duration: '1:28', thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400', views: 31200),
  const ShortModel(id: 's4', title: 'Mitosis vs Meiosis explained fast', instructor: 'Dr. Ankit Gupta', subject: 'Biology',   duration: '1:15', thumbnailUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400', views: 15600),
  const ShortModel(id: 's5', title: 'Thermodynamics Laws — Visual',      instructor: 'Dr. Priya Sharma', subject: 'Physics',   duration: '1:45', thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400', views: 42100, isLiked: true),
];

final mockQuizQuestions = [
  const QuizQuestion(question: 'What is the SI unit of electric charge?', options: ['Ampere', 'Coulomb', 'Volt', 'Farad'], correctIndex: 1),
  const QuizQuestion(question: 'Which law states the total electric flux through a closed surface is proportional to the enclosed charge?', options: ["Faraday's Law", "Ampere's Law", "Gauss's Law", "Coulomb's Law"], correctIndex: 2),
  const QuizQuestion(question: 'The speed of light in vacuum is approximately:', options: ['3 × 10⁶ m/s', '3 × 10⁸ m/s', '3 × 10¹⁰ m/s', '3 × 10⁴ m/s'], correctIndex: 1),
  const QuizQuestion(question: 'Which of the following is a vector quantity?', options: ['Mass', 'Temperature', 'Velocity', 'Electric potential'], correctIndex: 2),
  const QuizQuestion(question: "Bernoulli's principle is based on conservation of:", options: ['Mass', 'Momentum', 'Energy', 'Charge'], correctIndex: 2),
];

const List<String> subjectTags = [
  'All', 'Physics', 'Mathematics', 'Chemistry', 'Biology', 'History', 'English',
];
