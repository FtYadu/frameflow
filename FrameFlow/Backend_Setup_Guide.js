// Backend Setup Instructions for FrameFlow
// 
// This file contains the Node.js backend structure that works with the iOS app
// 
// SETUP INSTRUCTIONS:
// 1. Create a new directory called 'backend'
// 2. Run: npm init -y
// 3. Install dependencies: npm install express cors helmet morgan dotenv bcryptjs jsonwebtoken
// 4. Install dev dependencies: npm install -D nodemon
// 5. Create the files below in your backend directory
//
// PROJECT STRUCTURE:
// backend/
// ├── src/
// │   ├── server.js
// │   ├── config/
// │   │   └── supabase.js
// │   ├── middleware/
// │   │   └── auth.js
// │   ├── routes/
// │   │   ├── auth.js
// │   │   ├── agents.js
// │   │   ├── tasks.js
// │   │   ├── leads.js
// │   │   └── posts.js
// │   └── agents/
// │       ├── ScoutAgent.js
// │       └── MarketingAgent.js
// ├── package.json
// └── .env

/* 
===== package.json =====
{
  "name": "frameflow-backend",
  "version": "1.0.0",
  "description": "AI agent automation backend for photographers",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "echo \"Error: no test specified\" && exit 1"
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
    "@anthropic-ai/sdk": "^0.9.1",
    "node-cron": "^3.0.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}

===== .env =====
PORT=3000
NODE_ENV=development

# Supabase
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_role_key

# JWT
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# Claude AI
ANTHROPIC_API_KEY=your_anthropic_api_key

# Email (optional for notifications)
SENDGRID_API_KEY=your_sendgrid_api_key
FROM_EMAIL=noreply@frameflow.app

===== src/server.js =====
*/

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

// Import routes
const authRoutes = require('./routes/auth');
const agentRoutes = require('./routes/agents');
const taskRoutes = require('./routes/tasks');
const leadRoutes = require('./routes/leads');
const postRoutes = require('./routes/posts');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
    origin: ['http://localhost:3000', 'capacitor://localhost', 'http://localhost'],
    credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/agents', agentRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/leads', leadRoutes);
app.use('/api/posts', postRoutes);

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
});

/*
===== src/config/supabase.js =====
*/

const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error('Missing Supabase configuration');
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

module.exports = supabase;

/*
===== src/middleware/auth.js =====
*/

const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');

const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Fetch user from database
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

module.exports = { authenticateToken };

/*
===== src/routes/auth.js =====
*/

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Generate JWT tokens
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

// Sign Up
router.post('/signup', async (req, res) => {
    try {
        const { email, password, full_name, instagram_handle, niche } = req.body;

        // Validate input
        if (!email || !password || !full_name) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 12);

        // Create user
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
            console.error('Signup error:', error);
            return res.status(400).json({ error: 'Email already exists' });
        }

        // Create default agents
        const { error: agentError } = await supabase
            .from('agents')
            .insert([
                { user_id: user.id, agent_type: 'scout' },
                { user_id: user.id, agent_type: 'marketing' }
            ]);

        if (agentError) {
            console.error('Agent creation error:', agentError);
        }

        // Generate tokens
        const { accessToken, refreshToken } = generateTokens(user.id);

        // Remove password hash from response
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
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate input
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password required' });
        }

        // Find user
        const { data: user, error } = await supabase
            .from('users')
            .select('*')
            .eq('email', email)
            .single();

        if (error || !user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Check password
        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Generate tokens
        const { accessToken, refreshToken } = generateTokens(user.id);

        // Remove password hash from response
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

// Get current user
router.get('/me', authenticateToken, (req, res) => {
    res.json(req.user);
});

// Refresh token
router.post('/refresh', async (req, res) => {
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

module.exports = router;

// 
// To continue building the backend, create the remaining route files:
// - src/routes/agents.js (handles agent management)
// - src/routes/tasks.js (handles task approval flow)
// - src/routes/leads.js (handles lead management)
// - src/routes/posts.js (handles post creation/scheduling)
// - src/agents/ScoutAgent.js (AI lead finder)
// - src/agents/MarketingAgent.js (AI caption generator)
//
// Then set up the Supabase database with the SQL schema provided in the original prompt.
//
// DEPLOYMENT:
// 1. Deploy to Vercel, Railway, or similar platform
// 2. Set environment variables in your deployment platform
// 3. Update the Config.swift file in the iOS app with your API URL
//
// This backend structure provides:
// ✅ JWT Authentication with refresh tokens
// ✅ User registration and login
// ✅ Supabase integration
// ✅ Error handling and security
// ✅ CORS setup for mobile app
// ✅ Ready for agent integration
//