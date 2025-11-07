"""
ACEest Fitness & Gym - Main Entry Point
Run this file to start the Flask development server
"""
from app import create_app
import os

app = create_app()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_DEBUG', 'True') == 'True'
    
    print("=" * 60)
    print("🏋️  ACEest Fitness & Gym - Flask Application")
    print("=" * 60)
    print(f"🚀 Starting server on http://localhost:{port}")
    print(f"🔧 Debug mode: {debug}")
    print(f"📝 Version: 1.2 - Charts & Analytics")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=port, debug=debug)
