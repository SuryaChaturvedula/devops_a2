"""
Configuration settings for ACEest Fitness & Gym application
"""
import os


class Config:
    """Base configuration"""
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    DEBUG = False
    TESTING = False
    
    # Application settings
    APP_NAME = 'ACEest Fitness & Gym'
    APP_VERSION = '1.0'
    
    # Flask settings
    JSON_SORT_KEYS = False
    JSONIFY_PRETTYPRINT_REGULAR = True


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    ENV = 'development'


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    ENV = 'production'
    
    # Override with secure secret key in production
    def __init__(self):
        super().__init__()
        if not os.environ.get('SECRET_KEY'):
            raise ValueError("SECRET_KEY environment variable must be set in production!")
        self.SECRET_KEY = os.environ.get('SECRET_KEY')


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DEBUG = True
    ENV = 'testing'
    SECRET_KEY = 'test-secret-key'


# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
