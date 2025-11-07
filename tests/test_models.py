"""
Unit tests for data models
"""
import pytest
from app.models import Workout, WorkoutSession
from datetime import datetime


class TestWorkout:
    """Test Workout model"""
    
    def test_create_workout(self):
        """Test creating a workout"""
        workout = Workout('Push-ups', 30, 'Workout')
        assert workout.exercise == 'Push-ups'
        assert workout.duration == 30
        assert workout.category == 'Workout'
        assert workout.timestamp is not None
    
    def test_workout_to_dict(self):
        """Test workout to dictionary conversion"""
        workout = Workout('Squats', 20, 'Workout')
        data = workout.to_dict()
        
        assert data['exercise'] == 'Squats'
        assert data['duration'] == 20
        assert data['category'] == 'Workout'
        assert 'timestamp' in data
    
    def test_workout_from_dict(self):
        """Test creating workout from dictionary"""
        data = {
            'exercise': 'Lunges',
            'duration': 25,
            'category': 'Workout',
            'timestamp': datetime.now().isoformat()
        }
        workout = Workout.from_dict(data)
        
        assert workout.exercise == 'Lunges'
        assert workout.duration == 25
        assert workout.category == 'Workout'
    
    def test_workout_default_category(self):
        """Test default category is Workout"""
        workout = Workout('Running', 30)
        assert workout.category == 'Workout'
    
    def test_workout_repr(self):
        """Test workout string representation"""
        workout = Workout('Cycling', 45, 'Workout')
        assert 'Cycling' in repr(workout)
        assert '45' in repr(workout)


class TestWorkoutSession:
    """Test WorkoutSession model"""
    
    def test_create_session(self):
        """Test creating a workout session"""
        session = WorkoutSession()
        assert session.get_workout_count() == 0
        assert session.get_total_duration() == 0
    
    def test_add_workout(self):
        """Test adding a workout to session"""
        session = WorkoutSession()
        workout = session.add_workout('Push-ups', 30, 'Workout')
        
        assert workout.exercise == 'Push-ups'
        assert session.get_workout_count() == 1
        assert session.get_total_duration() == 30
    
    def test_add_multiple_workouts(self):
        """Test adding multiple workouts"""
        session = WorkoutSession()
        session.add_workout('Stretching', 10, 'Warm-up')
        session.add_workout('Running', 30, 'Workout')
        session.add_workout('Yoga', 15, 'Cool-down')
        
        assert session.get_workout_count() == 3
        assert session.get_total_duration() == 55
    
    def test_get_workouts_by_category(self):
        """Test filtering workouts by category"""
        session = WorkoutSession()
        session.add_workout('Stretching', 10, 'Warm-up')
        session.add_workout('Running', 30, 'Workout')
        session.add_workout('Cycling', 20, 'Workout')
        session.add_workout('Yoga', 15, 'Cool-down')
        
        warmup = session.get_workouts_by_category('Warm-up')
        workout = session.get_workouts_by_category('Workout')
        cooldown = session.get_workouts_by_category('Cool-down')
        
        assert len(warmup) == 1
        assert len(workout) == 2
        assert len(cooldown) == 1
    
    def test_get_duration_by_category(self):
        """Test getting duration by category"""
        session = WorkoutSession()
        session.add_workout('Stretching', 10, 'Warm-up')
        session.add_workout('Running', 30, 'Workout')
        session.add_workout('Cycling', 20, 'Workout')
        
        assert session.get_duration_by_category('Warm-up') == 10
        assert session.get_duration_by_category('Workout') == 50
        assert session.get_duration_by_category('Cool-down') == 0
    
    def test_clear_workouts(self):
        """Test clearing all workouts"""
        session = WorkoutSession()
        session.add_workout('Running', 30, 'Workout')
        session.add_workout('Cycling', 20, 'Workout')
        
        assert session.get_workout_count() == 2
        
        session.clear_workouts()
        assert session.get_workout_count() == 0
        assert session.get_total_duration() == 0
    
    def test_session_to_dict(self):
        """Test session to dictionary conversion"""
        session = WorkoutSession()
        session.add_workout('Running', 30, 'Workout')
        session.add_workout('Cycling', 20, 'Workout')
        
        data = session.to_dict()
        
        assert 'workouts' in data
        assert 'total_duration' in data
        assert 'workout_count' in data
        assert data['total_duration'] == 50
        assert data['workout_count'] == 2
        assert len(data['workouts']) == 2
    
    def test_get_all_workouts(self):
        """Test getting all workouts"""
        session = WorkoutSession()
        session.add_workout('Running', 30, 'Workout')
        session.add_workout('Cycling', 20, 'Workout')
        
        workouts = session.get_all_workouts()
        assert len(workouts) == 2
        assert all(isinstance(w, Workout) for w in workouts)
    
    def test_session_repr(self):
        """Test session string representation"""
        session = WorkoutSession()
        session.add_workout('Running', 30, 'Workout')
        
        repr_str = repr(session)
        assert '1 workouts' in repr_str or '1' in repr_str
        assert '30 mins' in repr_str or '30' in repr_str
