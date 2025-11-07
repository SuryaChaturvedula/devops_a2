"""
Data models for ACEest Fitness & Gym application
Version: 1.1 - Enhanced with session tracking and date management
"""
from datetime import datetime, date
from typing import List, Dict, Optional
import uuid


class Workout:
    """Workout model representing a single workout entry"""
    
    def __init__(self, exercise: str, duration: int, category: str = "Workout", 
                 timestamp: Optional[str] = None, session_id: Optional[str] = None):
        self.exercise = exercise
        self.duration = duration  # in minutes
        self.category = category  # Warm-up, Workout, Cool-down
        self.timestamp = timestamp or datetime.now().isoformat()
        self.session_id = session_id or str(uuid.uuid4())[:8]
        self.date = datetime.fromisoformat(self.timestamp).date().isoformat()
    
    def to_dict(self) -> Dict:
        """Convert workout to dictionary"""
        return {
            'exercise': self.exercise,
            'duration': self.duration,
            'category': self.category,
            'timestamp': self.timestamp,
            'session_id': self.session_id,
            'date': self.date
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Workout':
        """Create workout from dictionary"""
        return cls(
            exercise=data['exercise'],
            duration=data['duration'],
            category=data.get('category', 'Workout'),
            timestamp=data.get('timestamp'),
            session_id=data.get('session_id')
        )
    
    def __repr__(self):
        return f"<Workout {self.exercise} - {self.duration}min>"


class WorkoutSession:
    """Manages a collection of workouts with enhanced tracking"""
    
    def __init__(self):
        self.workouts: List[Workout] = []
        self.sessions: Dict[str, List[Workout]] = {}  # session_id -> workouts
    
    def add_workout(self, exercise: str, duration: int, category: str = "Workout", 
                    session_id: Optional[str] = None) -> Workout:
        """Add a new workout to the session"""
        workout = Workout(exercise, duration, category, session_id=session_id)
        self.workouts.append(workout)
        
        # Track by session
        if workout.session_id not in self.sessions:
            self.sessions[workout.session_id] = []
        self.sessions[workout.session_id].append(workout)
        
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
    
    def get_workouts_by_date(self, target_date: str) -> List[Workout]:
        """Get all workouts for a specific date"""
        return [w for w in self.workouts if w.date == target_date]
    
    def get_session_summary(self) -> Dict:
        """Get summary of all sessions"""
        summary = {}
        for session_id, workouts in self.sessions.items():
            summary[session_id] = {
                'count': len(workouts),
                'duration': sum(w.duration for w in workouts),
                'date': workouts[0].date if workouts else None,
                'timestamp': workouts[0].timestamp if workouts else None
            }
        return summary
    
    def get_recent_workouts(self, limit: int = 10) -> List[Workout]:
        """Get most recent workouts"""
        sorted_workouts = sorted(self.workouts, 
                                key=lambda x: x.timestamp, 
                                reverse=True)
        return sorted_workouts[:limit]
    
    def to_dict(self) -> Dict:
        """Convert session to dictionary"""
        return {
            'workouts': [w.to_dict() for w in self.workouts],
            'total_duration': self.get_total_duration(),
            'workout_count': self.get_workout_count(),
            'sessions': self.get_session_summary()
        }
    
    def __repr__(self):
        return f"<WorkoutSession {self.get_workout_count()} workouts, {self.get_total_duration()} mins, {len(self.sessions)} sessions>"


# In-memory storage (will be replaced with database in later versions)
workout_session = WorkoutSession()
