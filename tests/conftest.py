"""
Pytest configuration and fixtures for ACEest Fitness & Gym tests
"""
import pytest
from app import create_app
from app.models import workout_session


@pytest.fixture
def app():
    """Create and configure a test instance of the app"""
    app = create_app('testing')
    
    # Set up application context
    with app.app_context():
        yield app
    
    # Cleanup
    workout_session.clear_workouts()


@pytest.fixture
def client(app):
    """A test client for the app"""
    return app.test_client()


@pytest.fixture
def runner(app):
    """A test CLI runner for the app"""
    return app.test_cli_runner()


@pytest.fixture
def sample_workout():
    """Sample workout data for testing"""
    return {
        'exercise': 'Push-ups',
        'duration': 30,
        'category': 'Workout'
    }


@pytest.fixture
def sample_workouts():
    """Multiple sample workouts for testing"""
    return [
        {'exercise': 'Stretching', 'duration': 10, 'category': 'Warm-up'},
        {'exercise': 'Running', 'duration': 30, 'category': 'Workout'},
        {'exercise': 'Yoga', 'duration': 15, 'category': 'Cool-down'},
    ]


@pytest.fixture(autouse=True)
def clear_workouts():
    """Automatically clear workouts before each test"""
    workout_session.clear_workouts()
    yield
    workout_session.clear_workouts()
