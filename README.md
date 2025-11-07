# ACEest Fitness & Gym 🏋️

A modern Flask web application for tracking fitness and gym workouts with a complete CI/CD pipeline.

## 🎯 Features

- **Workout Tracking**: Log exercises with duration and category (Warm-up, Workout, Cool-down)
- **Real-time Statistics**: View workout analytics and progress
- **RESTful API**: Complete REST API for programmatic access
- **Responsive UI**: Beautiful Bootstrap-based web interface
- **Health Check**: Built-in health monitoring endpoint

## 📋 Version 1.0

**Current Features:**
- Basic workout logging
- Category-based organization
- Statistics dashboard
- REST API endpoints
- Web UI with Bootstrap

## 🚀 Quick Start

### Prerequisites

- Python 3.9+
- pip

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Solution
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment**
   - Windows:
     ```bash
     venv\Scripts\activate
     ```
   - Linux/Mac:
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

5. **Run the application**
   ```bash
   python app.py
   ```

6. **Open your browser**
   ```
   http://localhost:5000
   ```

## 📚 API Documentation

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/api/workouts` | Get all workouts |
| `POST` | `/api/workouts` | Add new workout |
| `GET` | `/api/workouts/stats` | Get statistics |
| `DELETE` | `/api/workouts/clear` | Clear all workouts |

### Example API Usage

**Add a workout:**
```bash
curl -X POST http://localhost:5000/api/workouts \
  -H "Content-Type: application/json" \
  -d '{"exercise": "Push-ups", "duration": 15, "category": "Workout"}'
```

**Get all workouts:**
```bash
curl http://localhost:5000/api/workouts
```

**Get statistics:**
```bash
curl http://localhost:5000/api/workouts/stats
```

## 🧪 Testing

Run the test suite:
```bash
pytest
```

Run with coverage:
```bash
pytest --cov=app --cov-report=html
```

## 📁 Project Structure

```
Solution/
├── app/
│   ├── __init__.py          # Flask app factory
│   ├── routes.py            # API & Web routes
│   ├── models.py            # Data models
│   ├── templates/           # HTML templates
│   │   ├── base.html
│   │   ├── index.html
│   │   └── workouts.html
│   └── static/              # CSS, JS, images
│       ├── css/
│       │   └── style.css
│       └── js/
│           └── main.js
├── tests/                   # Test suite
├── app.py                   # Application entry point
├── config.py                # Configuration
├── requirements.txt         # Dependencies
├── Dockerfile              # Docker configuration
└── README.md               # This file
```

## 🐳 Docker

Build the image:
```bash
docker build -t aceest-fitness:v1.0 .
```

Run the container:
```bash
docker run -p 5000:5000 aceest-fitness:v1.0
```

## 🔄 CI/CD Pipeline

This project includes a complete CI/CD pipeline with:
- ✅ Jenkins for continuous integration
- ✅ Pytest for automated testing
- ✅ SonarQube for code quality
- ✅ Docker for containerization
- ✅ Kubernetes for orchestration

## 📝 Development

### Running in Development Mode

```bash
export FLASK_DEBUG=True
python app.py
```

### Code Quality

Format code with Black:
```bash
black app/
```

Lint with Flake8:
```bash
flake8 app/
```

## 🚢 Deployment Strategies

The application supports multiple Kubernetes deployment strategies:
- Blue-Green Deployment
- Canary Release
- Rolling Update
- A/B Testing
- Shadow Deployment

## 📄 License

Educational project for DevOps CI/CD assignment.

## 👨‍💻 Author

DevOps Assignment - ACEest Fitness & Gym

## 🔗 Links

- GitHub Repository: [Link]
- Docker Hub: [Link]
- Live Demo: [Link]

---

**Version**: 1.0  
**Last Updated**: November 2025
