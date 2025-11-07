"""
Test configuration and application initialization
"""
import pytest
from app import create_app
from config import DevelopmentConfig, ProductionConfig, TestingConfig


def test_app_creation():
    """Test app can be created"""
    app = create_app('testing')
    assert app is not None
    assert app.config['TESTING'] is True


def test_development_config():
    """Test development configuration"""
    config = DevelopmentConfig()
    assert config.DEBUG is True
    assert config.ENV == 'development'


def test_production_config_missing_secret():
    """Test production config requires secret key"""
    import os
    # Save original
    original = os.environ.get('SECRET_KEY')
    
    # Remove SECRET_KEY
    if 'SECRET_KEY' in os.environ:
        del os.environ['SECRET_KEY']
    
    try:
        with pytest.raises(ValueError):
            config = ProductionConfig()
    finally:
        # Restore original
        if original:
            os.environ['SECRET_KEY'] = original


def test_testing_config():
    """Test testing configuration"""
    config = TestingConfig()
    assert config.TESTING is True
    assert config.DEBUG is True
    assert config.ENV == 'testing'


def test_health_endpoint(client):
    """Test health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    
    import json
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'service' in data


def test_404_handling(client):
    """Test 404 error handling"""
    response = client.get('/nonexistent')
    assert response.status_code == 404
