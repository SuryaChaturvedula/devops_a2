"""
Unit tests for Flask routes (Web UI and API)
"""
import pytest
import json
from app.models import workout_session


class TestWebRoutes:
    """Test web UI routes"""
    
    def test_index_page(self, client):
        """Test home page loads"""
        response = client.get('/')
        assert response.status_code == 200
        assert b'ACEest Fitness' in response.data
        assert b'Track your fitness journey' in response.data
    
    def test_workouts_page(self, client):
        """Test workouts page loads"""
        response = client.get('/workouts')
        assert response.status_code == 200
        assert b'Workout Manager' in response.data
    
    def test_health_check(self, client):
        """Test health check endpoint"""
        response = client.get('/health')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'service' in data


class TestAddWorkoutForm:
    """Test adding workouts via web form"""
    
    def test_add_workout_success(self, client, sample_workout):
        """Test successfully adding a workout via form"""
        response = client.post('/add_workout', data=sample_workout, follow_redirects=True)
        assert response.status_code == 200
        assert b'Added' in response.data or b'success' in response.data.lower()
    
    def test_add_workout_missing_exercise(self, client):
        """Test adding workout without exercise name"""
        response = client.post('/add_workout', data={
            'duration': 30,
            'category': 'Workout'
        }, follow_redirects=True)
        assert response.status_code == 200
        assert b'required' in response.data.lower()
    
    def test_add_workout_invalid_duration(self, client):
        """Test adding workout with invalid duration"""
        response = client.post('/add_workout', data={
            'exercise': 'Running',
            'duration': 'invalid',
            'category': 'Workout'
        }, follow_redirects=True)
        assert response.status_code == 200
        assert b'valid number' in response.data.lower() or b'error' in response.data.lower()
    
    def test_add_workout_negative_duration(self, client):
        """Test adding workout with negative duration"""
        response = client.post('/add_workout', data={
            'exercise': 'Running',
            'duration': -10,
            'category': 'Workout'
        }, follow_redirects=True)
        assert response.status_code == 200
        assert b'positive' in response.data.lower() or b'error' in response.data.lower()
    
    def test_add_multiple_workouts(self, client, sample_workouts):
        """Test adding multiple workouts"""
        for workout in sample_workouts:
            response = client.post('/add_workout', data=workout, follow_redirects=True)
            assert response.status_code == 200
        
        # Verify all workouts were added
        assert workout_session.get_workout_count() == len(sample_workouts)


class TestAPIWorkouts:
    """Test REST API workout endpoints"""
    
    def test_api_get_workouts_empty(self, client):
        """Test getting workouts when none exist"""
        response = client.get('/api/workouts')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['count'] == 0
        assert data['workouts'] == []
    
    def test_api_add_workout_success(self, client, sample_workout):
        """Test adding workout via API"""
        response = client.post('/api/workouts',
                              data=json.dumps(sample_workout),
                              content_type='application/json')
        assert response.status_code == 201
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['workout']['exercise'] == sample_workout['exercise']
        assert data['workout']['duration'] == sample_workout['duration']
    
    def test_api_add_workout_no_data(self, client):
        """Test adding workout without data"""
        response = client.post('/api/workouts',
                              data='',
                              content_type='application/json')
        # Flask returns 400 for invalid JSON
        assert response.status_code == 400
    
    def test_api_add_workout_missing_exercise(self, client):
        """Test adding workout without exercise name"""
        response = client.post('/api/workouts',
                              data=json.dumps({'duration': 30}),
                              content_type='application/json')
        assert response.status_code == 400
        
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'required' in data['error'].lower()
    
    def test_api_add_workout_invalid_duration(self, client):
        """Test adding workout with invalid duration"""
        response = client.post('/api/workouts',
                              data=json.dumps({
                                  'exercise': 'Running',
                                  'duration': 'invalid'
                              }),
                              content_type='application/json')
        assert response.status_code == 400
        
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_api_get_workouts_with_data(self, client, sample_workouts):
        """Test getting workouts after adding some"""
        # Add workouts
        for workout in sample_workouts:
            client.post('/api/workouts',
                       data=json.dumps(workout),
                       content_type='application/json')
        
        # Get workouts
        response = client.get('/api/workouts')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['count'] == len(sample_workouts)
        assert len(data['workouts']) == len(sample_workouts)
    
    def test_api_get_workouts_by_category(self, client, sample_workouts):
        """Test filtering workouts by category"""
        # Add workouts
        for workout in sample_workouts:
            client.post('/api/workouts',
                       data=json.dumps(workout),
                       content_type='application/json')
        
        # Get only Workout category
        response = client.get('/api/workouts?category=Workout')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert all(w['category'] == 'Workout' for w in data['workouts'])


class TestAPIStats:
    """Test statistics API endpoint"""
    
    def test_api_stats_empty(self, client):
        """Test stats when no workouts exist"""
        response = client.get('/api/workouts/stats')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['stats']['total_workouts'] == 0
        assert data['stats']['total_duration'] == 0
    
    def test_api_stats_with_data(self, client, sample_workouts):
        """Test stats after adding workouts"""
        # Add workouts
        for workout in sample_workouts:
            client.post('/api/workouts',
                       data=json.dumps(workout),
                       content_type='application/json')
        
        response = client.get('/api/workouts/stats')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert data['stats']['total_workouts'] == len(sample_workouts)
        
        # Check total duration
        expected_duration = sum(w['duration'] for w in sample_workouts)
        assert data['stats']['total_duration'] == expected_duration
        
        # Check category breakdown
        assert 'by_category' in data['stats']
        assert 'Warm-up' in data['stats']['by_category']
        assert 'Workout' in data['stats']['by_category']
        assert 'Cool-down' in data['stats']['by_category']


class TestAPIClear:
    """Test clear workouts endpoint"""
    
    def test_api_clear_workouts(self, client, sample_workouts):
        """Test clearing all workouts"""
        # Add workouts
        for workout in sample_workouts:
            client.post('/api/workouts',
                       data=json.dumps(workout),
                       content_type='application/json')
        
        # Verify workouts exist
        assert workout_session.get_workout_count() > 0
        
        # Clear workouts
        response = client.delete('/api/workouts/clear')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'Cleared' in data['message']
        
        # Verify workouts are cleared
        assert workout_session.get_workout_count() == 0
    
    def test_api_clear_empty(self, client):
        """Test clearing when no workouts exist"""
        response = client.delete('/api/workouts/clear')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['success'] is True


class TestIntegration:
    """Integration tests combining multiple features"""
    
    def test_full_workflow(self, client, sample_workouts):
        """Test complete workflow: add, view, stats, clear"""
        # 1. Start with empty
        response = client.get('/api/workouts')
        data = json.loads(response.data)
        assert data['count'] == 0
        
        # 2. Add workouts
        for workout in sample_workouts:
            response = client.post('/api/workouts',
                                  data=json.dumps(workout),
                                  content_type='application/json')
            assert response.status_code == 201
        
        # 3. Verify count
        response = client.get('/api/workouts')
        data = json.loads(response.data)
        assert data['count'] == len(sample_workouts)
        
        # 4. Check stats
        response = client.get('/api/workouts/stats')
        data = json.loads(response.data)
        assert data['stats']['total_workouts'] == len(sample_workouts)
        
        # 5. Clear all
        response = client.delete('/api/workouts/clear')
        assert response.status_code == 200
        
        # 6. Verify empty again
        response = client.get('/api/workouts')
        data = json.loads(response.data)
        assert data['count'] == 0
