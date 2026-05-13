// Mock data models & sample data for Shiksha Verse
// Replace with real API calls when backend is ready.

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

// ── Sample Data ──────────────────────────────────────────────────────────────

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
  const ShortModel(
    id: 's1',
    title: 'Newton\'s 3rd Law in 60 seconds',
    instructor: 'Dr. Priya Sharma',
    subject: 'Physics',
    duration: '1:02',
    thumbnailUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400',
    views: 24800,
  ),
  const ShortModel(
    id: 's2',
    title: 'Why does ice float? Quick Explain',
    instructor: 'Dr. Sunita Rao',
    subject: 'Chemistry',
    duration: '0:58',
    thumbnailUrl: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=400',
    views: 18500,
    isLiked: true,
  ),
  const ShortModel(
    id: 's3',
    title: 'Integration by Parts — 90 seconds',
    instructor: 'Prof. Rajan Mehta',
    subject: 'Mathematics',
    duration: '1:28',
    thumbnailUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400',
    views: 31200,
  ),
  const ShortModel(
    id: 's4',
    title: 'Mitosis vs Meiosis explained fast',
    instructor: 'Dr. Ankit Gupta',
    subject: 'Biology',
    duration: '1:15',
    thumbnailUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400',
    views: 15600,
  ),
  const ShortModel(
    id: 's5',
    title: 'Thermodynamics Laws — Visual',
    instructor: 'Dr. Priya Sharma',
    subject: 'Physics',
    duration: '1:45',
    thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
    views: 42100,
    isLiked: true,
  ),
];

final mockQuizQuestions = [
  const QuizQuestion(
    question: 'What is the SI unit of electric charge?',
    options: ['Ampere', 'Coulomb', 'Volt', 'Farad'],
    correctIndex: 1,
  ),
  const QuizQuestion(
    question: 'Which law states that the total electric flux through a closed surface is proportional to the enclosed charge?',
    options: ['Faraday\'s Law', 'Ampere\'s Law', 'Gauss\'s Law', 'Coulomb\'s Law'],
    correctIndex: 2,
  ),
  const QuizQuestion(
    question: 'The speed of light in vacuum is approximately:',
    options: ['3 × 10⁶ m/s', '3 × 10⁸ m/s', '3 × 10¹⁰ m/s', '3 × 10⁴ m/s'],
    correctIndex: 1,
  ),
  const QuizQuestion(
    question: 'Which of the following is a vector quantity?',
    options: ['Mass', 'Temperature', 'Velocity', 'Electric potential'],
    correctIndex: 2,
  ),
  const QuizQuestion(
    question: 'Bernoulli\'s principle is based on conservation of:',
    options: ['Mass', 'Momentum', 'Energy', 'Charge'],
    correctIndex: 2,
  ),
];

const List<String> subjectTags = [
  'All', 'Physics', 'Mathematics', 'Chemistry', 'Biology', 'History', 'English',
];
