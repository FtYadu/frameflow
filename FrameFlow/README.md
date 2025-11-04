# FrameFlow - AI Agent App for Photographers

FrameFlow is a complete iOS application built with SwiftUI that provides AI-powered automation for photographers and videographers. It features intelligent agents that help with lead generation, marketing content creation, and business management.

## 🚀 Features

### Phase 1 (MVP - Complete)
- **Authentication System**: Email/password signup and login with JWT tokens
- **AI Agent Management**: Scout and Marketing agents with toggle controls
- **Task Approval Flow**: Review and approve AI-generated tasks
- **Lead Management**: View and manage potential clients found by AI
- **Post Creation**: Create and schedule Instagram posts with AI-generated captions
- **Dashboard**: Real-time overview of agent activity and business metrics
- **Dark Mode UI**: Modern, photographer-friendly design

### AI Agents
- **Scout Agent**: Automatically finds potential photography clients
- **Marketing Agent**: Generates Instagram captions and schedules posts
- **Editor Agent** (Phase 2): Auto-edits videos
- **Finance Agent** (Phase 2): Handles invoices and payments

## 🛠 Tech Stack

### iOS App
- **SwiftUI** - Modern iOS UI framework
- **Combine** - Reactive programming for data flow
- **URLSession** - Network requests to backend API
- **Keychain Services** - Secure token storage
- **UserNotifications** - Push notifications for agent updates
- **PhotosUI** - Image selection for posts

### Backend (Node.js)
- **Express.js** - REST API server
- **Supabase** - PostgreSQL database and authentication
- **Claude API** - AI agent intelligence
- **JWT** - Token-based authentication
- **bcryptjs** - Password hashing

## 📱 App Structure

```
FrameFlow/
├── Models/                    # Data models
│   ├── User.swift
│   ├── Agent.swift
│   ├── AgentTask.swift
│   ├── Lead.swift
│   ├── Post.swift
│   └── Notification.swift
├── Views/                     # UI components
│   ├── Auth/
│   │   └── LoginView.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── AgentCardView.swift
│   │   └── StatsCardView.swift
│   ├── Tasks/
│   │   └── TaskRowView.swift
│   ├── Leads/
│   │   └── LeadsListView.swift
│   ├── Posts/
│   │   └── PostComposerView.swift
│   └── Notifications/
│       └── NotificationsView.swift
├── ViewModels/                # Business logic
│   ├── AuthViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── LeadViewModel.swift
│   └── PostViewModel.swift
├── Services/                  # API and system services
│   ├── APIService.swift
│   ├── AuthService.swift
│   ├── KeychainService.swift
│   └── NotificationService.swift
└── Utils/                     # Utilities and constants
    ├── Config.swift
    ├── Constants.swift
    └── Extensions.swift
```

## 🎨 Design System

### Color Palette
- **Background**: `#0F172A` (Dark blue-gray)
- **Surface**: `#1E293B` (Lighter gray)  
- **Primary**: `#3B82F6` (Blue)
- **Secondary**: `#A855F7` (Purple)
- **Success**: `#10B981` (Green)
- **Warning**: `#F59E0B` (Yellow)
- **Danger**: `#EF4444` (Red)

### Typography
- **Headers**: SF Pro Display, Bold, 24-28pt
- **Body**: SF Pro Text, Regular, 14-16pt
- **Captions**: SF Pro Text, Regular, 12pt

### Components
- **Cards**: Rounded corners (12-16px), subtle shadows
- **Buttons**: Gradient backgrounds with spring animations
- **Loading States**: Skeleton screens and progress indicators

## 🔧 Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ deployment target
- Node.js 18+
- Supabase account
- Anthropic Claude API key

### iOS App Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/frameflow.git
   cd frameflow
   ```

2. **Open in Xcode**
   ```bash
   open FrameFlow.xcodeproj
   ```

3. **Configure API endpoint**
   - Update `Config.swift` with your backend URL
   - For development: `http://localhost:3000/api`
   - For production: `https://your-api-domain.com/api`

4. **Build and run**
   - Select your target device/simulator
   - Press Cmd+R to build and run

### Backend Setup

1. **Create backend directory**
   ```bash
   mkdir frameflow-backend
   cd frameflow-backend
   ```

2. **Initialize Node.js project**
   ```bash
   npm init -y
   ```

3. **Install dependencies**
   ```bash
   npm install express cors helmet morgan dotenv bcryptjs jsonwebtoken @supabase/supabase-js @anthropic-ai/sdk node-cron
   npm install -D nodemon
   ```

4. **Copy backend files**
   - Follow the structure in `Backend_Setup_Guide.js`
   - Create all route files and agent logic

5. **Set environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

6. **Start development server**
   ```bash
   npm run dev
   ```

### Database Setup (Supabase)

1. **Create Supabase project**
   - Go to [supabase.com](https://supabase.com)
   - Create new project

2. **Run SQL schema**
   ```sql
   -- Copy the SQL from the original prompt
   -- Create all tables: users, agents, agent_tasks, leads, posts, notifications, agent_briefs
   ```

3. **Configure authentication**
   - Enable email authentication
   - Set up JWT tokens

## 📡 API Endpoints

### Authentication
```
POST /api/auth/signup     - Create new user account
POST /api/auth/login      - Login with email/password  
POST /api/auth/refresh    - Refresh JWT tokens
GET  /api/auth/me        - Get current user profile
```

### Agents
```
GET    /api/agents                - Get all user agents
PATCH  /api/agents/:type/toggle   - Activate/deactivate agent
POST   /api/agents/:type/trigger  - Trigger agent action
GET    /api/agents/briefs/:type   - Get daily brief
```

### Tasks
```
GET    /api/tasks              - Get all tasks requiring approval
PATCH  /api/tasks/:id/approve  - Approve/reject task
DELETE /api/tasks/:id          - Cancel task
```

### Leads
```
GET    /api/leads              - Get all leads
PATCH  /api/leads/:id          - Update lead status
POST   /api/leads/:id/outreach - Send outreach message
```

### Posts
```
GET    /api/posts                    - Get all posts
POST   /api/posts                    - Create new post
POST   /api/posts/generate-caption   - Generate AI caption
POST   /api/posts/:id/schedule       - Schedule post
```

## 🤖 AI Agent System

### Scout Agent
- **Purpose**: Find potential photography clients
- **Process**: 
  1. Searches web for businesses needing photography
  2. Scores leads 0-100 based on likelihood
  3. Generates personalized outreach messages
  4. Creates approval tasks for user review

### Marketing Agent  
- **Purpose**: Create Instagram content
- **Process**:
  1. Analyzes uploaded photos
  2. Generates captions matching brand voice
  3. Suggests relevant hashtags
  4. Schedules posts for optimal times

## 🔒 Security Features

- **JWT Authentication**: Secure token-based auth with refresh tokens
- **Keychain Storage**: Tokens stored securely in iOS Keychain
- **Password Hashing**: bcrypt with salt for password security
- **API Rate Limiting**: Prevents abuse of endpoints
- **Input Validation**: All inputs validated on client and server

## 📊 Analytics & Metrics

The dashboard shows key metrics:
- **Lead Generation**: New leads found, conversion rates
- **Content Performance**: Posts created, engagement rates  
- **Agent Activity**: Active agents, completed tasks
- **Revenue Tracking**: Monthly earnings (Phase 2)

## 🔄 State Management

- **ViewModels**: MVVM architecture with ObservableObject
- **Combine**: Reactive data flow between components
- **Loading States**: Proper loading/error/success state handling
- **Cache**: Optimistic updates with server sync

## 🎯 User Experience

### Onboarding
1. **Sign Up**: Email, name, Instagram handle, photography niche
2. **Agent Setup**: Agents auto-created and explained
3. **First Task**: Guided through approving first AI-generated task

### Daily Workflow
1. **Morning Brief**: Summary of overnight agent activity
2. **Task Review**: Approve/reject AI suggestions
3. **Content Creation**: Create posts with AI assistance
4. **Lead Management**: Follow up with prospects

### Notifications
- **Task Approvals**: When AI needs user approval
- **New Leads**: When Scout Agent finds prospects
- **Daily Briefs**: Morning/evening summaries
- **System Updates**: Agent status changes

## 🚧 Phase 2 Features (Roadmap)

- **Editor Agent**: Automated video editing with templates
- **Finance Agent**: Invoice generation and payment tracking
- **Calendar Integration**: Shoot scheduling and client meetings
- **Instagram Integration**: Direct posting to Instagram
- **Analytics Dashboard**: Detailed performance metrics
- **Team Collaboration**: Multi-user access and permissions

## 🧪 Testing

### Test User Accounts
```
Email: test@frameflow.app
Password: Test123!
```

### Test Scenarios
1. **User Registration**: Sign up → Agents auto-created
2. **Agent Trigger**: Scout Agent → Mock leads generated
3. **Task Approval**: Approve outreach → Simulated sending
4. **Post Creation**: Generate caption → AI response
5. **Notifications**: Mock task approval notifications

## 🚀 Deployment

### iOS App
1. **TestFlight**: Beta testing with photographers
2. **App Store**: Production release with ASO optimization

### Backend  
1. **Vercel/Railway**: Serverless deployment
2. **Environment Variables**: Production secrets configured
3. **Monitoring**: Error tracking and performance monitoring

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Email**: support@frameflow.app
- **Documentation**: [docs.frameflow.app](https://docs.frameflow.app)
- **Discord**: [FrameFlow Community](https://discord.gg/frameflow)

## 🙏 Acknowledgments

- **Claude AI**: Powering our intelligent agents
- **Supabase**: Backend-as-a-Service platform
- **SF Symbols**: Beautiful iOS iconography
- **SwiftUI**: Modern iOS development framework

---

Built with ❤️ for photographers who want to focus on creating amazing images instead of chasing leads and managing social media.