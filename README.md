# EasyDo CRM

A comprehensive CRM solution for WhatsApp business management with automated workflows, campaign execution, and customer support features.

## 🚀 Features

- **WhatsApp Business Integration**: Complete WhatsApp Business API integration
- **Automated Campaigns**: Create and execute marketing campaigns via WhatsApp
- **Customer Support Hub**: Real-time customer support management
- **Workflow Automation**: Template-based flows for automated responses
- **Queue Management**: Efficient message queuing and processing
- **Analytics & Reporting**: Campaign statistics and performance metrics
- **Webhook Support**: External integrations via webhooks

## 📁 Project Structure

```
easydo-crm/
├── node-backend-whatsapp/     # Node.js backend API
├── react-whatsapp-web/        # React frontend application
├── customer-support-hub/      # Customer support interface
├── docker-compose.yml         # Local development setup
├── docker-compose.swarm.yml   # Production deployment
├── schema.sql                 # Database schema
└── init-db.sh                 # Database initialization
```

## 🛠️ Tech Stack

- **Backend**: Node.js, TypeScript, Express, PostgreSQL
- **Frontend**: React, TypeScript, Vite, Tailwind CSS
- **Database**: PostgreSQL with custom migrations
- **Deployment**: Docker, Docker Compose, Swarm
- **Communication**: WebSocket, REST APIs

## 🚀 Getting Started

### Prerequisites

- Docker & Docker Compose
- Node.js 18+
- PostgreSQL 13+

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/MoatazNoaman2001/easydo-crm.git
   cd easydo-crm
   ```

2. **Initialize submodules**
   ```bash
   git submodule update --init --recursive
   ```

3. **Start with Docker**
   ```bash
   # For development
   docker-compose up -d

   # For production
   docker stack deploy -c docker-compose.swarm.yml easydo
   ```

4. **Manual setup (alternative)**

   **Backend Setup:**
   ```bash
   cd node-backend-whatsapp
   npm install
   npm run build
   npm start
   ```

   **Frontend Setup:**
   ```bash
   cd react-whatsapp-web
   npm install
   npm run dev
   ```

## 🔧 Configuration

### Environment Variables

Create `.env` files in respective directories with necessary configuration:

- Database connection strings
- WhatsApp Business API credentials
- JWT secrets
- External service API keys

### Database Setup

```bash
# Initialize database
./init-db.sh

# Run migrations
cd node-backend-whatsapp
npm run migrate
```

## 📊 Key Components

### Backend Services
- **Campaign Management**: Automated WhatsApp campaigns
- **Template Flows**: Dynamic message templates
- **Queue Processing**: Message queuing and delivery
- **Webhook Handling**: External integrations
- **Real-time Socket**: Live updates and notifications

### Frontend Applications
- **WhatsApp Web Interface**: Message management and campaign control
- **Customer Support Hub**: Agent dashboard for customer interactions
- **Analytics Dashboard**: Campaign performance and metrics

## 🔒 Security Features

- JWT authentication
- Webhook signature validation
- Rate limiting
- Input validation and sanitization
- Secure key management for WhatsApp API

## 📈 API Documentation

API documentation is available at `/api/docs` when the backend is running.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## 📝 License

This project is proprietary software. All rights reserved.

## 🆘 Support

For support and questions, please contact the development team.
