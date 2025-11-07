"""
Data models for ACEest Fitness & Gym application
"""
from datetime import datetime
from typing import List, Dict, Optional


class Workout:
    """Workout model representing a single workout entry"""
    
    def __init__(self, exercise: str, duration: int, category: str = "Workout", 
                 timestamp: Optional[str] = None):
        self.exercise = exercise
        self.duration = duration  # in minutes
        self.category = category  # Warm-up, Workout, Cool-down
        self.timestamp = timestamp or datetime.now().isoformat()
    
    def to_dict(self) -> Dict:
        """Convert workout to dictionary"""
        return {
            'exercise': self.exercise,
            'duration': self.duration,
            'category': self.category,
            'timestamp': self.timestamp
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Workout':
        """Create workout from dictionary"""
        return cls(
            exercise=data['exercise'],
            duration=data['duration'],
            category=data.get('category', 'Workout'),
            timestamp=data.get('timestamp')
        )
    
    def __repr__(self):
        return f"<Workout {self.exercise} - {self.duration}min>"


class WorkoutSession:
    """Manages a collection of workouts"""
    
    def __init__(self):
        self.workouts: List[Workout] = []
    
    def add_workout(self, exercise: str, duration: int, category: str = "Workout") -> Workout:
        """Add a new workout to the session"""
        workout = Workout(exercise, duration, category)
        self.workouts.append(workout)
        return workout
    
    def get_workouts_by_category(self, category: str) -> List[Workout]:
        """Get all workouts in a specific category"""
        return [w for w in self.workouts if w.category == category]
    
    def get_all_workouts(self) -> List[Workout]:
        """Get all workouts"""
        return self.workouts
    
    def get_total_duration(self) -> int:
        """Calculate total workout duration"""
        return sum(w.duration for w in self.workouts)
    
    def get_duration_by_category(self, category: str) -> int:
        """Get total duration for a specific category"""
        return sum(w.duration for w in self.workouts if w.category == category)
    
    def get_workout_count(self) -> int:
        """Get total number of workouts"""
        return len(self.workouts)
    
    def clear_workouts(self):
        """Clear all workouts"""
        self.workouts.clear()
    
    def to_dict(self) -> Dict:
        """Convert session to dictionary"""
        return {
            'workouts': [w.to_dict() for w in self.workouts],
            'total_duration': self.get_total_duration(),
            'workout_count': self.get_workout_count()
        }
    
    def __repr__(self):
        return f"<WorkoutSession {self.get_workout_count()} workouts, {self.get_total_duration()} mins>"


# In-memory storage (will be replaced with database in later versions)
workout_session = WorkoutSession()
