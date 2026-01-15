import '../models/forum_post.dart';
import '../models/certificate.dart';
import '../models/resource.dart';
import '../models/event.dart';

class MockData {
  // Mock Forum Posts
  static List<ForumPost> getMockForumPosts() {
    return [
      ForumPost(
        id: '1',
        userId: 'user1',
        userName: 'John Doe',
        title: 'Welcome to BCA MMAMC Forum!',
        content: 'This is a sample forum post. Feel free to discuss anything related to BCA studies, events, and more!',
        category: 'general',
        tags: ['welcome', 'introduction'],
        upvotes: 15,
        commentsCount: 5,
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ForumPost(
        id: '2',
        userId: 'user2',
        userName: 'Jane Smith',
        title: 'Tips for Data Structures Exam',
        content: 'Here are some important topics to focus on for the upcoming Data Structures exam...',
        category: 'academic',
        tags: ['exam', 'data-structures'],
        upvotes: 23,
        commentsCount: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ForumPost(
        id: '3',
        userId: 'user3',
        userName: 'Mike Johnson',
        title: 'Upcoming Tech Fest - Registration Open',
        content: 'Don\'t miss out on our annual tech fest! Register now for exciting competitions and workshops.',
        category: 'events',
        tags: ['tech-fest', 'registration'],
        upvotes: 45,
        commentsCount: 18,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  // Mock Certificates
  static List<Certificate> getMockCertificates() {
    final now = DateTime.now();
    return [
      Certificate(
        id: '1',
        userId: 'user1',
        title: 'Web Development Workshop',
        description: 'Successfully completed the Web Development Workshop',
        eventDate: now.subtract(const Duration(days: 30)),
        issueDate: now.subtract(const Duration(days: 30)),
        verificationCode: 'CERT-2024-001',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Certificate(
        id: '2',
        userId: 'user1',
        title: 'Hackathon 2024',
        description: 'Participated in Hackathon 2024',
        eventDate: now.subtract(const Duration(days: 15)),
        issueDate: now.subtract(const Duration(days: 15)),
        verificationCode: 'CERT-2024-002',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Certificate(
        id: '3',
        userId: 'user1',
        title: 'AI/ML Seminar',
        description: 'Attended AI/ML Seminar',
        eventDate: now.subtract(const Duration(days: 7)),
        issueDate: now.subtract(const Duration(days: 7)),
        verificationCode: 'CERT-2024-003',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  // Mock Resources
  static List<Resource> getMockResources() {
    return [
      Resource(
        id: '1',
        title: 'Data Structures Notes - Complete Guide',
        description: 'Comprehensive notes covering all topics in Data Structures including arrays, linked lists, trees, and graphs.',
        category: 'Notes',
        type: 'study_material',
        fileUrl: 'https://example.com/ds-notes.pdf',
        downloads: 245,
        views: 1200,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Resource(
        id: '2',
        title: 'Java Programming Tutorial Series',
        description: 'Complete video tutorial series for Java programming from basics to advanced concepts.',
        category: 'Videos',
        type: 'article',
        externalUrl: 'https://youtube.com/playlist',
        downloads: 189,
        views: 850,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Resource(
        id: '3',
        title: 'Database Management System - PPT',
        description: 'PowerPoint presentation covering DBMS concepts, SQL queries, and normalization.',
        category: 'Presentations',
        type: 'study_material',
        fileUrl: 'https://example.com/dbms-ppt.pdf',
        downloads: 156,
        views: 620,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Resource(
        id: '4',
        title: 'Previous Year Question Papers',
        description: 'Collection of previous year question papers for all subjects.',
        category: 'Question Papers',
        type: 'past_paper',
        fileUrl: 'https://example.com/question-papers.pdf',
        downloads: 412,
        views: 1500,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Resource(
        id: '5',
        title: 'Web Development Resources',
        description: 'Curated list of web development resources, tutorials, and tools.',
        category: 'Links',
        type: 'article',
        externalUrl: 'https://github.com/resources',
        downloads: 98,
        views: 340,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  // Mock Events (in case events aren't loading)
  static List<Event> getMockEvents() {
    final now = DateTime.now();
    return [
      Event(
        id: '1',
        title: 'Annual Tech Fest 2024',
        description: 'Join us for the biggest tech event of the year featuring workshops, competitions, and guest speakers.',
        category: 'technical',
        startDate: now.add(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 17)),
        location: 'MMAMC Campus',
        registrationFee: 500,
        maxAttendees: 200,
        imageUrl: null,
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      Event(
        id: '2',
        title: 'Web Development Workshop',
        description: 'Learn modern web development with React, Node.js, and MongoDB in this hands-on workshop.',
        category: 'workshop',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 7)),
        location: 'Computer Lab',
        registrationFee: 200,
        maxAttendees: 50,
        imageUrl: null,
        isFeatured: false,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
      Event(
        id: '3',
        title: 'Hackathon 2024',
        description: '24-hour coding marathon to build innovative solutions for real-world problems.',
        category: 'competition',
        startDate: now.add(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 31)),
        location: 'Main Auditorium',
        registrationFee: 300,
        maxAttendees: 100,
        imageUrl: null,
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }
}
