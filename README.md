# BCA Association - Mobile App

**Version:** 1.3.0  
**Build:** 5  
**Platform:** Android  
**Framework:** Flutter 3.10.4

A comprehensive mobile application for BCA students at MMAMC College, featuring AI-powered study assistance, event management, forum discussions, resource hub, study planner, finance tracker, algorithm learning game, and 13 fun arcade games.

---

## 📱 Features

### Core Features
- 📅 **Event Management** - Browse, register, and manage college events with real-time updates
- 📚 **Resource Hub** - Access and download study materials, past papers, and educational resources
- 💬 **Discussion Forum** - Create posts, comment, upvote, and engage with the community
- 📢 **Announcements & Notices** - Stay updated with college announcements and important notices
- 🎓 **Certificate Management** - View, manage, and showcase your certificates
- 📊 **Study Planner** - Organize your study schedule, subjects, and tasks
- 💰 **Finance Tracker** - Track income, expenses, and manage your budget
- ⏱️ **Pomodoro Timer** - Focus timer with customizable work/break sessions
- 🗓️ **Nepali Calendar** - Traditional calendar with events and A.D. date display
- 🤖 **AI Assistant** - Chat with AI, generate images, voice input, download conversations
- 🎮 **Algorithm Learning Game** - Interactive game to learn 23 algorithms with visual animations
- 🎪 **Fun Zone** - 13 arcade games for entertainment and timepass
- 👤 **User Profiles** - Manage your profile, skills, and academic information
- 📱 **Home Screen Widgets** - Quick access to app features from home screen

### Algorithm Learning Game Features
- 🎯 **23 Algorithms** - Complete collection across 4 categories
- 📊 **Sorting Algorithms** - Bubble, Selection, Insertion, Merge, Quick, Heap Sort
- 🔍 **Searching Algorithms** - Linear, Binary, Jump, Interpolation, Exponential Search
- 🗂️ **Data Structures** - Stack, Queue, Linked List, Binary Tree, Hash Table
- 🌐 **Graph Algorithms** - BFS, DFS, Dijkstra, Prim's, Kruskal's, Bellman-Ford
- 🎮 **Drag & Drop Gameplay** - Arrange algorithm steps in correct order
- ⭐ **3-Star Rating** - Based on time and accuracy
- 💡 **Hints System** - 3 hints per game
- 📈 **Progress Tracking** - Track completed algorithms
- 🎨 **Visual Animations** - Step-by-step animated visualizations for ALL algorithms
- 🎯 **Explanations** - Learn from mistakes with detailed explanations

### Fun Zone - 13 Arcade Games
- 🎨 **Color Match Madness** - Stroop effect game (60s timer, combo system)
- 👆 **Swipe Mania** - Directional swipe challenges (10 levels)
- ⚡ **Tap Master** - Reaction time test (5 rounds)
- 🐦 **Flappy Code** - Physics-based flying game
- 🧠 **Memory Match** - Card matching puzzle (16 cards)
- 🔢 **Number Rush** - Fast math challenges (60s timer)
- 🐍 **Snake Classic** - Classic snake game (20x20 grid)
- 🎲 **2048** - Sliding number puzzle with swipe controls
- 🧱 **Brick Breaker** - Break bricks with ball (3 lives)
- 🎯 **Target Shooter** - Tap targets before they disappear
- 🔄 **Spin Match** - Match spinning symbols to target
- 🎈 **Balloon Pop** - Pop balloons before they float away
- ⚔️ **Reflex Duel** - Quick reaction battle (10 rounds)

**Game Features:**
- 🏆 High score tracking for all games
- 📊 Play count statistics
- 🎮 Haptic feedback
- 🎨 Beautiful gradient themes
- 💾 Local score persistence
- 📴 Fully offline gameplay

### AI Assistant Features
- ✅ **Image Generation** - Create AI images with text prompts
- ✅ **Image Gallery** - View, search, filter, and download generated images
- ✅ **Chat Export** - Download conversations as beautiful HTML files
- ✅ **Dual Mode** - Switch between Chat and Image generation
- ✅ **Streaming Responses** - See AI responses in real-time
- ✅ **Provider Info** - Know which AI model answered your question

### Study Planner Features
- 📚 **Subject Management** - Add subjects with codes, teachers, and credits
- ✅ **Task Tracking** - Create and manage study tasks with priorities
- 📝 **Notes** - Take and organize study notes
- 🎯 **Progress Tracking** - Monitor your study progress and completion
- 🔔 **Reminders** - Set reminders for tasks and deadlines

### Finance Tracker Features
- 💵 **Income Tracking** - Record salary, freelance, investments, and gifts
- 💸 **Expense Tracking** - Track spending across multiple categories
- 📊 **Visual Analytics** - Charts and graphs for financial insights
- 📈 **Budget Management** - Set and monitor budgets
- 📤 **Export Data** - Share financial reports

### Resource Hub Features
- 📖 **Study Materials** - Access course materials and notes
- 📄 **Past Papers** - Download previous exam papers
- 💻 **Projects** - Browse project resources and examples
- 🎯 **Interview Prep** - Preparation materials for interviews
- 📰 **Articles** - Educational articles and guides
- 🔍 **Advanced Filters** - Filter by type, semester, and subject
- ⬇️ **Download Support** - Download resources for offline access

### Profile Features
- ✏️ **Edit Profile** - Update personal information, skills, and bio
- 🎨 **Avatar Upload** - Customize your profile picture
- 🏆 **Level & XP System** - Earn points and level up
- 📱 **Quick Actions** - Access certificates, events, and AI gallery
- 🌓 **Theme Toggle** - Switch between Light and Dark mode
- 🔐 **Privacy & Security** - Manage account settings
- 📞 **Contact Us** - Send messages and feedback to support
- 💡 **Request Features** - Submit feature requests and feedback
- 👨‍💻 **Developer Credits** - View developer information and social links

### Technical Features
- 🌓 **Dark/Light Theme** - Automatic and manual theme switching
- 📴 **Offline Functionality** - Access cached content without internet
- 🔄 **Real-time Sync** - Instant updates with Supabase backend
- 🎨 **Modern Material Design 3** - Beautiful, intuitive UI
- ⚡ **Optimized Performance** - Fast loading and smooth animations
- 🔒 **Secure Authentication** - Protected user accounts and data
- 🔔 **Local Notifications** - Reminders and alerts
- 📱 **Responsive Design** - Works on all screen sizes

---

## 🚀 Installation

### Requirements
- Android 7.0 (API 24) or higher
- Internet connection
- ~75 MB storage space

### Install APK
1. Download `BCA-Connect-AI-v1.1.0.apk`
2. Enable "Install from Unknown Sources" in Settings
3. Open the APK file and install
4. Launch the app

---

## 🔧 Setup & Configuration

### Environment Variables
Create a `.env` file in the root directory:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Permissions
The app requires the following permissions:
- **Internet** - Required for all features
- **Microphone** - Optional, for voice input in AI Assistant
- **Storage** - Optional, for downloading images and chat exports
- **Notifications** - Optional, for event and forum updates

---

## 📖 User Guide

### Getting Started
1. **Sign Up/Login** - Create an account or sign in
2. **Complete Profile** - Add your information
3. **Explore Features** - Navigate using bottom navigation bar

### AI Assistant
1. Tap the AI icon on home screen or bottom nav
2. **Chat Mode**: Ask questions about BCA studies
3. **Image Mode**: Toggle to generate images
4. **Voice Input**: Tap microphone to speak
5. **Gallery**: View all generated images
6. **Download**: Export chat as HTML

### Events
1. Browse upcoming events
2. Tap to view details
3. Register for events
4. View "My Events" for registered events

### Forum
1. Browse discussions
2. Create new posts
3. Comment and upvote
4. Filter by category

---

## 🏗️ Development

### Tech Stack
- **Framework**: Flutter 3.10.4
- **Language**: Dart
- **State Management**: Riverpod
- **Backend**: Supabase
- **UI**: Material Design 3
- **Animations**: Flutter Animate
- **Icons**: Iconsax

### Key Dependencies
```yaml
flutter_riverpod: ^2.6.1
supabase_flutter: ^2.9.1
go_router: ^14.6.2
speech_to_text: ^7.3.0
permission_handler: ^11.3.1
device_info_plus: ^11.2.0
cached_network_image: ^3.4.1
flutter_markdown: ^0.7.4+1
```

### Build Commands

**Development Build:**
```bash
flutter run
```

**Production Build:**
```bash
flutter build apk --release
```

**Build App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

---

## 🐛 Troubleshooting

### Common Issues

**App won't install:**
- Enable "Install from Unknown Sources"
- Check Android version (7.0+)
- Ensure sufficient storage

**AI Assistant not working:**
- Check internet connection
- Verify Supabase credentials
- Ensure you're logged in

**Voice input not working:**
- Grant microphone permission
- Check Google Speech Services (Android)
- Ensure internet connection

**Images not loading:**
- Check internet connection
- Pull to refresh
- Clear app cache

**Download permission error:**
- Grant storage permission when prompted
- For Android 13+, permission is automatic
- Check available storage space

---

## 📊 Version History

### v1.3.0 (Current)
**Release Date:** January 19, 2026

**New Features:**
- 🎮 **Algorithm Learning Game** - Interactive game with 23 algorithms
  - Complete visual animations for all algorithms
  - Drag & drop gameplay with hints system
  - 3-star rating based on performance
  - Progress tracking and explanations
- 🎪 **Fun Zone** - 13 arcade games for entertainment
  - Color Match, Swipe Mania, Tap Master, Flappy Code
  - Memory Match, Number Rush, Snake, 2048, Brick Breaker
  - Target Shooter, Spin Match, Balloon Pop, Reflex Duel
  - High scores, stats tracking, haptic feedback
- ✨ **Enhanced AI Assistant UI** - ChatGPT-style input area
  - Mode toggle for chat/image generation
  - Voice button inside input field
  - Dynamic send button colors
  - Improved suggestions layout

**Improvements:**
- 🔧 Fixed caching issues - Fresh data when online
- 🔧 Removed Connect Rooms feature (Agora dependencies)
- 🔧 Fixed 10 code analysis warnings
- 🔧 Optimized app size and performance
- 🔧 Production-ready codebase

**Bug Fixes:**
- 🐛 Fixed aggressive caching preventing data refresh
- 🐛 Fixed deprecated API usage in Switch widgets
- 🐛 Fixed BuildContext async gaps
- 🐛 Fixed speech recognition initialization

**Code Quality:**
- 📊 All code analysis issues resolved
- 📊 Optimized for production deployment
- 📊 Removed unnecessary documentation files

### v1.2.0
**Release Date:** January 17, 2026

**New Features:**
- ✨ Redesigned forgot password page with modern UI
- ✨ Contact Us page with database integration
- ✨ Request Feature/Feedback page
- ✨ Developer credits in profile with social links
- ✨ Resource page filters in modal (type & semester)
- ✨ Fixed splash screen icon centering
- ✨ Improved logout button design

**Improvements:**
- 🔧 Code optimization (74% reduction in issues)
- 🔧 Replaced all print statements with debugPrint
- 🔧 Fixed constant naming conventions
- 🔧 Improved error handling
- 🔧 Better async context management
- 🔧 Resource card header styling improvements
- 🔧 Dark theme consistency across pages

**Bug Fixes:**
- 🐛 Fixed icon centering in splash screen
- 🐛 Fixed resource card icon container shape
- 🐛 Fixed filter modal interactions
- 🐛 Fixed logout button arrow icon
- 🐛 Fixed unnecessary underscores in code

**Code Quality:**
- 📊 Reduced issues from 27 to 7 (96/100 quality score)
- 📊 Production-ready codebase
- 📊 All critical issues resolved

### v1.1.0
**Release Date:** January 2025

**New Features:**
- ✨ Real-time voice input with live transcription
- ✨ AI Image Gallery with search, filter, and download
- ✨ Chat export as beautiful HTML files
- ✨ Smart image display (base64 + URL support)
- ✨ Permission request dialogs with explanations
- ✨ Profile integration with AI Gallery

**Improvements:**
- 🚀 Instant image loading in gallery
- 🚀 Better permission handling
- 🚀 Removed back button from gallery (cleaner UI)
- 🚀 Fixed deprecation warnings
- 🚀 Optimized code for production

**Bug Fixes:**
- 🐛 Fixed image preview not showing
- 🐛 Fixed filename sanitization error
- 🐛 Fixed async gap warnings
- 🐛 Fixed Hero widget conflicts

### v1.0.0
**Release Date:** December 2024

**Initial Release:**
- Basic AI Assistant
- Event Management
- Forum Discussions
- Resource Library
- Profile Management

---

## 🔒 Security & Privacy

- All data is encrypted in transit (HTTPS)
- Passwords are hashed and never stored in plain text
- User data is stored securely in Supabase
- No data is shared with third parties
- AI conversations are private to your account

---

## 📞 Support

For issues, questions, or feedback:
- **Email**: mmamcbcaassociation@gmail.com
- **Phone**: +977-9800923746
- **Office Hours**: Sunday - Friday, 10:00 AM - 5:00 PM
- **Location**: MMAMC College, Biratnagar, Nepal
- **In-App**: Use Contact Us or Request Feature/Feedback in Profile

---

## 📄 License

Copyright © 2026 MMAMC College. All rights reserved.

This application is proprietary software developed for MMAMC College BCA students.

---

## 👥 Credits

**Developer:**
- **Saif Ali**
  - Instagram: [@me_saifali](https://www.instagram.com/me_saifali/)
  - GitHub: [@mesaifali](https://github.com/mesaifali)

**Powered By:**
- Flutter & Dart
- Supabase
- OpenAI / Anthropic / Google AI
- Pollinations AI
- Material Design 3

---

## 🎯 Roadmap

### Upcoming Features
- [ ] Offline mode for cached content
- [ ] Push notifications
- [ ] Dark mode improvements
- [ ] More AI models
- [ ] Study groups
- [ ] Assignment tracking
- [ ] Grade calculator

---

## 📱 Screenshots

*Screenshots will be added in future updates*

---

**Made with ❤️ for BCA Students at MMAMC College**
