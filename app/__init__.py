"""
ACEest Fitness & Gym - Flask Application Factory
"""
import os
from datetime import datetime
from flask import Flask


def create_app(config_name='development'):
    """Application factory pattern"""
    app = Flask(__name__)
    
    # Load configuration
    if config_name == 'testing':
        app.config['TESTING'] = True
        app.config['SECRET_KEY'] = 'test-secret-key'
    else:
        app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
        app.config['DEBUG'] = os.environ.get('FLASK_DEBUG', 'True') == 'True'
    
    # Register blueprints
    from app.routes import main_bp
    app.register_blueprint(main_bp)
    
    # Add template filters
    @app.template_filter('datetime')
    def format_datetime(value):
        if isinstance(value, str):
            try:
                value = datetime.fromisoformat(value)
            except ValueError:
                return value
        return value.strftime('%Y-%m-%d %H:%M')
    
    # Health check endpoint
    @app.route('/health')
    def health_check():
        return {'status': 'healthy', 'service': 'ACEest Fitness API'}, 200
    
    return app
