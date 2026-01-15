# BCA Connect - College Association Management App

A modern Flutter application for managing college association activities, events, resources, and community engagement.

## 📱 Features

### Core Features
- **Dashboard**: Clean home screen with notices, quick actions, and upcoming events
- **Events Management**: Browse, register, and manage college events with detailed information
- **AI Assistant**: Integrated AI chatbot for student queries and support
- **Forum**: Discussion platform for students with categories and threading
- **Resources**: Access and download study materials and documents
- **Certificates**: View and download event participation certificates
- **Notices**: Important announcements and updates
- **Profile Management**: User profiles with achievements and XP system

### Key Highlights
- 🎨 Modern Material Design 3 UI
- 🌙 Dark mode support
- 🔔 Push notifications
- 📱 Responsive design
- 🔐 Secure authentication
- 💾 Offline support
- 🎯 Gamification (XP & Levels)

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Riverpod** - State management
- **Go Router** - Navigation
- **Google Fonts** - Typography (Inter font)

### Backend & Services
- **Supabase** - Backend as a Service
  - PostgreSQL database
  - Authentication
  - Real-time subscriptions
  - Storage
- **Firebase** - Push notifications

### UI/UX
- **Material Design 3** - Design system
- **Iconsax** - Modern icon pack
- **Custom orange theme** (#DA7809)

### Key Packages
```yaml
- flutter_riverpod: ^2.6.1
- go_router: ^14.8.1
- supabase_flutter: ^2.9.5
- google_fonts: ^6.3.3
- iconsax: ^0.0.8
- intl: ^0.19.0
- cached_network_image: ^3.4.1
- flutter_markdown: ^0.7.7+1
- image_picker: ^1.1.2
- share_plus: ^10.1.4
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/          # App configuration
│   ├── theme/           # Theme and styling
│   └── utils/           # Utility functions
├── data/
│   ├── models/          # Data models
│   └── repositories/    # Data repositories
├── presentation/
│   ├── providers/       # Riverpod providers
│   ├── routes/          # Navigation routes
│   ├── screens/         # App screens
│   │   ├── home/
│   │   ├── events/
│   │   ├── forum/
│   │   ├── resources/
│   │   ├── certificates/
│   │   ├── ai/
│   │   ├── auth/
│   │   ├── profile/
│   │   └── settings/
│   └── widgets/         # Reusable widgets
└── main.dart           # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.5.0)
- Dart SDK (>=3.5.0)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/hehewhy321-afk/bca-connect-ai-app.git
cd bca_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment**
Copy `.env.example` to `.env` and fill in your credentials:
```bash
cp .env.example .env
```

Edit `.env` file:
```env
SUPABASE_URL=https://xtpkzqeylypdsxspmbmg.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

4. **Run the app**
```bash
flutter run
```

### Build for Production

**Android APK**
```bash
flutter build apk --release
```

**Android App Bundle**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

## 🗄️ Database Setup

The app uses Supabase as the backend. Required tables:

- `profiles` - User profiles
- `events` - College events
- `event_registrations` - Event registrations
- `forum_posts` - Forum discussions
- `forum_replies` - Forum replies
- `resources` - Study materials
- `certificates` - Event certificates
- `announcements` - Notices and announcements

Refer to `supabase/` directory for SQL schemas.

## 🎨 Design System

### Colors
- **Primary**: Orange (#DA7809)
- **Secondary**: Dark Orange (#FF9500)
- **Background**: Dynamic (Light/Dark mode)

### Typography
- **Font Family**: Inter (Google Fonts)
- **Weights**: 400, 500, 600, 700, 900

### Components
- Material Design 3 components
- Custom gradient buttons
- Bento grid layouts
- Card-based UI

## 📋 To-Do / Roadmap

### High Priority
- [ ] Implement actual event registration flow
- [ ] Add file upload for resources

### Medium Priority
- [ ] Add calendar integration
- [ ] Implement event reminders
- [ ] Add social sharing features
- [ ] Create admin dashboard
- [ ] Add analytics and reporting

### Low Priority
- [ ] Add multiple language support
- [ ] Implement voice search
- [ ] Add AR features for campus navigation
- [ ] Create widget for home screen
- [ ] Add biometric authentication

## 🐛 Known Issues

- Hero widget tag conflict warning (non-critical)
- Some analyzer warnings for unused imports
- Certificate screen needs enhancement

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer

**Developed by:** hehewhy321-afk
- GitHub: [@hehewhy321-afk](https://github.com/hehewhy321-afk)
- Repository: [BCA Connect AI App](https://github.com/hehewhy321-afk/bca-connect-ai-app)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Material Design team for design guidelines
- All open-source contributors

## 📞 Support

For support, create an issue on [GitHub Issues](https://github.com/hehewhy321-afk/bca-connect-ai-app/issues).

## 🔗 Links

- [Repository](https://github.com/hehewhy321-afk/bca-connect-ai-app)
- [Issue Tracker](https://github.com/hehewhy321-afk/bca-connect-ai-app/issues)
- [Releases](https://github.com/hehewhy321-afk/bca-connect-ai-app/releases)

---

**Made with ❤️ using Flutter**

*Last Updated: January 2026*
