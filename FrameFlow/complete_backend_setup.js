//
// FrameFlow Backend - Complete Node.js + Express Implementation
// 
// DEPLOYMENT INSTRUCTIONS:
// 
// 1. Create directory and install:
//    mkdir frameflow-backend && cd frameflow-backend
//    npm init -y
//    npm install express cors helmet morgan dotenv bcryptjs jsonwebtoken @supabase/supabase-js @anthropic-ai/sdk
//    npm install -D nodemon
//
// 2. Create these files in your backend directory
// 
// 3. Deploy to Vercel:
//    npm install -g vercel
//    vercel --prod
//
// 4. Update iOS Config.swift with your Vercel URL

/* ===== package.json ===== */
{
  "name": "frameflow-backend",
  "version": "1.0.0",
  "description": "FrameFlow AI agent backend for photographers",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5", 
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "@supabase/supabase-js": "^2.38.0",
    "@anthropic-ai/sdk": "^0.9.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}

/* ===== .env ===== */
PORT=3000
NODE_ENV=development

# Supabase Configuration
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_SERVICE_KEY=your_supabase_service_role_key_here

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# AI Provider Keys (Add your actual keys here)
ANTHROPIC_API_KEY=sk-ant-api03-your_claude_key_here
OPENAI_API_KEY=sk-your_openai_key_here
GOOGLE_API_KEY=your_gemini_key_here

/* ===== server.js ===== */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// Middleware
app.use(helmet());
app.use(cors({
  origin: ['http://localhost:3000', 'capacitor://localhost', 'http://localhost'],
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Authentication Middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', decoded.userId)
      .single();

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

// Utility Functions
const generateTokens = (userId) => {
  const accessToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );

  const refreshToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN }
  );

  return { accessToken, refreshToken };
};

// Health Check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// AUTHENTICATION ROUTES
// Sign Up
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { email, password, full_name, instagram_handle, niche } = req.body;

    if (!email || !password || !full_name) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const { data: user, error } = await supabase
      .from('users')
      .insert([{
        email,
        password_hash: hashedPassword,
        full_name,
        instagram_handle,
        niche
      }])
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    // Create default agents
    const { error: agentError } = await supabase
      .from('agents')
      .insert([
        { user_id: user.id, agent_type: 'scout', is_active: true, status: 'idle' },
        { user_id: user.id, agent_type: 'marketing', is_active: true, status: 'idle' }
      ]);

    if (agentError) {
      console.error('Agent creation error:', agentError);
    }

    const { accessToken, refreshToken } = generateTokens(user.id);

    delete user.password_hash;

    res.status(201).json({
      user,
      access_token: accessToken,
      refresh_token: refreshToken
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single();

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const { accessToken, refreshToken } = generateTokens(user.id);

    delete user.password_hash;

    res.json({
      user,
      access_token: accessToken,
      refresh_token: refreshToken
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get Current User
app.get('/api/auth/me', authenticateToken, (req, res) => {
  const user = { ...req.user };
  delete user.password_hash;
  res.json(user);
});

// Refresh Token
app.post('/api/auth/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return res.status(401).json({ error: 'Refresh token required' });
    }

    const decoded = jwt.verify(refresh_token, process.env.JWT_SECRET);
    const { accessToken, refreshToken } = generateTokens(decoded.userId);

    res.json({
      access_token: accessToken,
      refresh_token: refreshToken
    });
  } catch (error) {
    res.status(403).json({ error: 'Invalid refresh token' });
  }
});

// AGENTS ROUTES
// Get All Agents
app.get('/api/agents', authenticateToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('agents')
      .select('*')
      .eq('user_id', req.user.id);

    if (error) throw error;

    res.json(data || []);
  } catch (error) {
    console.error('Error fetching agents:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Toggle Agent
app.patch('/api/agents/:type/toggle', authenticateToken, async (req, res) => {
  try {
    const { type } = req.params;
    const { is_active } = req.body;

    const { data, error } = await supabase
      .from('agents')
      .update({ 
        is_active,
        last_activity_at: new Date().toISOString()
      })
      .eq('user_id', req.user.id)
      .eq('agent_type', type)
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (error) {
    console.error('Error toggling agent:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Trigger Agent
app.post('/api/agents/:type/trigger', authenticateToken, async (req, res) => {
  try {
    const { type } = req.params;
    const { action } = req.body;

    // Update agent status
    await supabase
      .from('agents')
      .update({ 
        status: 'working',
        current_task: `Executing ${action}`,
        last_activity_at: new Date().toISOString()
      })
      .eq('user_id', req.user.id)
      .eq('agent_type', type);

    // Create mock task for demo
    if (type === 'scout' && action === 'find_leads') {
      // Mock lead creation
      const mockLeads = [
        {
          user_id: req.user.id,
          company_name: "The Rooftop Cafe",
          contact_email: "events@rooftopcafe.com",
          instagram_handle: "@rooftopcafe",
          lead_score: 85,
          reasoning: "High-end restaurant with frequent events, good social media presence",
          source: "AI Scout Agent"
        },
        {
          user_id: req.user.id,
          company_name: "Modern Fitness Studio",
          contact_email: "marketing@modernfit.com", 
          instagram_handle: "@modernfitstudio",
          lead_score: 78,
          reasoning: "Growing fitness brand, needs lifestyle photography",
          source: "AI Scout Agent"
        }
      ];

      await supabase.from('leads').insert(mockLeads);

      // Create approval task
      await supabase
        .from('agent_tasks')
        .insert([{
          user_id: req.user.id,
          agent_id: (await supabase.from('agents').select('id').eq('user_id', req.user.id).eq('agent_type', type).single()).data.id,
          task_type: 'lead_approval',
          status: 'pending',
          requires_approval: true,
          input_data: { action: 'find_leads' },
          output_data: { leads_found: mockLeads.length }
        }]);
    }

    // Reset agent status
    setTimeout(async () => {
      await supabase
        .from('agents')
        .update({ 
          status: 'idle',
          current_task: null,
          last_activity_at: new Date().toISOString()
        })
        .eq('user_id', req.user.id)
        .eq('agent_type', type);
    }, 3000);

    res.json({ success: true });
  } catch (error) {
    console.error('Error triggering agent:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// TASKS ROUTES
// Get All Tasks
app.get('/api/tasks', authenticateToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('agent_tasks')
      .select('*')
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json(data || []);
  } catch (error) {
    console.error('Error fetching tasks:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Approve Task
app.patch('/api/tasks/:id/approve', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { approved } = req.body;

    const { data, error } = await supabase
      .from('agent_tasks')
      .update({ 
        approved_by_user: approved,
        status: approved ? 'approved' : 'rejected'
      })
      .eq('id', id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (error) {
    console.error('Error approving task:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// LEADS ROUTES
// Get All Leads
app.get('/api/leads', authenticateToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('leads')
      .select('*')
      .eq('user_id', req.user.id)
      .order('discovered_at', { ascending: false });

    if (error) throw error;

    res.json(data || []);
  } catch (error) {
    console.error('Error fetching leads:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update Lead Status
app.patch('/api/leads/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    const { data, error } = await supabase
      .from('leads')
      .update({ status, notes })
      .eq('id', id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (error) {
    console.error('Error updating lead:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POSTS ROUTES
// Get All Posts
app.get('/api/posts', authenticateToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('posts')
      .select('*')
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json(data || []);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create Post
app.post('/api/posts', authenticateToken, async (req, res) => {
  try {
    const { caption, image_url, hashtags, platform, scheduled_for } = req.body;

    const { data, error } = await supabase
      .from('posts')
      .insert([{
        user_id: req.user.id,
        caption,
        image_url,
        hashtags: hashtags || [],
        platform: platform || 'instagram',
        scheduled_for,
        status: scheduled_for ? 'scheduled' : 'draft'
      }])
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Generate Caption (Mock Implementation)
app.post('/api/posts/generate-caption', authenticateToken, async (req, res) => {
  try {
    const { topic, brand_voice, target_audience } = req.body;

    // Mock caption generation
    const captions = [
      "Capturing moments that tell your story ✨ Every frame holds a memory worth preserving.",
      "Behind the lens lies endless possibilities 📸 Creating art, one shot at a time.",
      "Light, shadow, and everything in between. This is where magic happens.",
      "Every photograph is a story waiting to be told. What's yours?",
      "In a world full of snapshots, be a photograph 🎯"
    ];

    const hashtags = [
      "photography", "photographer", "photooftheday", "capture", "moment", 
      "artistic", "creative", "storytelling", "memories", "professional"
    ];

    const randomCaption = captions[Math.floor(Math.random() * captions.length)];
    const randomHashtags = hashtags.sort(() => 0.5 - Math.random()).slice(0, 5);

    res.json({
      caption: randomCaption,
      hashtags: randomHashtags
    });
  } catch (error) {
    console.error('Error generating caption:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// NOTIFICATIONS ROUTES
// Get All Notifications
app.get('/api/notifications', authenticateToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json(data || []);
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mark Notification as Read
app.patch('/api/notifications/:id/read', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong!'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Not Found',
    message: 'The requested resource was not found'
  });
});

app.listen(PORT, () => {
  console.log(`FrameFlow Backend running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

// Export for Vercel
module.exports = app;

/* ===== vercel.json (for Vercel deployment) ===== */
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ]
}

/* 
===== SUPABASE DATABASE SETUP SQL =====
Run this in your Supabase SQL Editor:
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    instagram_handle VARCHAR(100),
    niche VARCHAR(100),
    location JSONB,
    subscription_tier VARCHAR(50) DEFAULT 'free',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Agents table
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    agent_type VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    status VARCHAR(50) DEFAULT 'idle',
    current_task TEXT,
    last_activity_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, agent_type)
);

-- Agent Tasks table
CREATE TABLE agent_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    task_type VARCHAR(100) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'pending',
    input_data JSONB,
    output_data JSONB,
    requires_approval BOOLEAN DEFAULT false,
    approved_by_user BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Leads table
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    company_name VARCHAR(255),
    contact_email VARCHAR(255),
    instagram_handle VARCHAR(100),
    lead_score INTEGER,
    reasoning TEXT,
    source VARCHAR(100),
    status VARCHAR(50) DEFAULT 'new',
    notes TEXT,
    discovered_at TIMESTAMP DEFAULT NOW()
);

-- Posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    caption TEXT,
    image_url TEXT,
    hashtags JSONB,
    platform VARCHAR(50) DEFAULT 'instagram',
    scheduled_for TIMESTAMP,
    status VARCHAR(50) DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Agent Briefs table
CREATE TABLE agent_briefs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    brief_type VARCHAR(20) NOT NULL,
    brief_date DATE NOT NULL,
    summary TEXT,
    action_items JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_agents_user_id ON agents(user_id);
CREATE INDEX idx_agent_tasks_user_id ON agent_tasks(user_id);
CREATE INDEX idx_leads_user_id ON leads(user_id);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);

/*
===== DEPLOYMENT STEPS =====

1. SUPABASE SETUP:
   - Go to supabase.com, create new project
   - Run the SQL above in SQL Editor
   - Copy your project URL and keys to .env

2. GET API KEYS:
   - Anthropic: console.anthropic.com ($5 free credit)
   - OpenAI: platform.openai.com (get API key)
   - Google: makersuite.google.com (get Gemini key)

3. LOCAL TESTING:
   - npm install
   - npm run dev
   - Test endpoints with Postman

4. VERCEL DEPLOYMENT:
   - npm install -g vercel
   - vercel --prod
   - Add environment variables in Vercel dashboard

5. UPDATE iOS CONFIG:
   - Update Config.swift with your Vercel URL
   - Test login/signup from iOS app
*/