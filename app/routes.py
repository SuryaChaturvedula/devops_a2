"""
Routes for ACEest Fitness & Gym application
Version: 1.2 - Added charts and analytics
Handles both Web UI and REST API endpoints
"""
from flask import Blueprint, render_template, request, jsonify, redirect, url_for, flash
from app.models import workout_session, Workout

main_bp = Blueprint('main', __name__)

# ==================== WEB UI ROUTES ====================

@main_bp.route('/')
def index():
    """Home page"""
    return render_template('index.html')


@main_bp.route('/workouts')
def workouts():
    """Workout management page"""
    all_workouts = workout_session.get_all_workouts()
    categories = ['Warm-up', 'Workout', 'Cool-down']
    
    # Group workouts by category
    grouped_workouts = {
        category: workout_session.get_workouts_by_category(category)
        for category in categories
    }
    
    stats = {
        'total_workouts': workout_session.get_workout_count(),
        'total_duration': workout_session.get_total_duration(),
        'warmup_duration': workout_session.get_duration_by_category('Warm-up'),
        'workout_duration': workout_session.get_duration_by_category('Workout'),
        'cooldown_duration': workout_session.get_duration_by_category('Cool-down'),
    }
    
    return render_template('workouts.html', 
                         workouts=all_workouts, 
                         grouped_workouts=grouped_workouts,
                         stats=stats,
                         categories=categories)


@main_bp.route('/analytics')
def analytics():
    """Analytics and charts page"""
    categories = ['Warm-up', 'Workout', 'Cool-down']
    
    stats = {
        'total_workouts': workout_session.get_workout_count(),
        'total_duration': workout_session.get_total_duration(),
        'total_sessions': len(workout_session.get_session_summary()),
        'by_category': {
            category: {
                'count': len(workout_session.get_workouts_by_category(category)),
                'duration': workout_session.get_duration_by_category(category)
            }
            for category in categories
        }
    }
    
    return render_template('analytics.html', stats=stats)


@main_bp.route('/add_workout', methods=['POST'])
def add_workout_form():
    """Handle workout form submission"""
    exercise = request.form.get('exercise', '').strip()
    duration_str = request.form.get('duration', '').strip()
    category = request.form.get('category', 'Workout')
    
    # Validation
    if not exercise:
        flash('Exercise name is required!', 'error')
        return redirect(url_for('main.workouts'))
    
    try:
        duration = int(duration_str)
        if duration <= 0:
            flash('Duration must be a positive number!', 'error')
            return redirect(url_for('main.workouts'))
    except ValueError:
        flash('Duration must be a valid number!', 'error')
        return redirect(url_for('main.workouts'))
    
    # Add workout
    workout = workout_session.add_workout(exercise, duration, category)
    flash(f'✅ Added {exercise} ({duration} min) to {category}!', 'success')
    
    return redirect(url_for('main.workouts'))


# ==================== REST API ROUTES ====================

@main_bp.route('/api/workouts', methods=['GET'])
def api_get_workouts():
    """Get all workouts (API)"""
    category = request.args.get('category')
    
    if category:
        workouts = workout_session.get_workouts_by_category(category)
    else:
        workouts = workout_session.get_all_workouts()
    
    return jsonify({
        'success': True,
        'workouts': [w.to_dict() for w in workouts],
        'count': len(workouts)
    }), 200


@main_bp.route('/api/workouts', methods=['POST'])
def api_add_workout():
    """Add a new workout (API)"""
    data = request.get_json()
    
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400
    
    exercise = data.get('exercise', '').strip()
    duration = data.get('duration')
    category = data.get('category', 'Workout')
    
    # Validation
    if not exercise:
        return jsonify({'success': False, 'error': 'Exercise name is required'}), 400
    
    try:
        duration = int(duration)
        if duration <= 0:
            return jsonify({'success': False, 'error': 'Duration must be positive'}), 400
    except (ValueError, TypeError):
        return jsonify({'success': False, 'error': 'Duration must be a valid number'}), 400
    
    # Add workout
    workout = workout_session.add_workout(exercise, duration, category)
    
    return jsonify({
        'success': True,
        'message': 'Workout added successfully',
        'workout': workout.to_dict()
    }), 201


@main_bp.route('/api/workouts/stats', methods=['GET'])
def api_get_stats():
    """Get workout statistics (API)"""
    categories = ['Warm-up', 'Workout', 'Cool-down']
    
    stats = {
        'total_workouts': workout_session.get_workout_count(),
        'total_duration': workout_session.get_total_duration(),
        'by_category': {
            category: {
                'count': len(workout_session.get_workouts_by_category(category)),
                'duration': workout_session.get_duration_by_category(category)
            }
            for category in categories
        }
    }
    
    return jsonify({'success': True, 'stats': stats}), 200


@main_bp.route('/api/workouts/sessions', methods=['GET'])
def api_get_sessions():
    """Get session summary (API)"""
    summary = workout_session.get_session_summary()
    
    return jsonify({
        'success': True,
        'sessions': summary,
        'total_sessions': len(summary)
    }), 200


@main_bp.route('/api/workouts/recent', methods=['GET'])
def api_get_recent():
    """Get recent workouts (API)"""
    limit = request.args.get('limit', 10, type=int)
    recent = workout_session.get_recent_workouts(limit)
    
    return jsonify({
        'success': True,
        'workouts': [w.to_dict() for w in recent],
        'count': len(recent)
    }), 200


@main_bp.route('/api/workouts/clear', methods=['DELETE'])
def api_clear_workouts():
    """Clear all workouts (API)"""
    count = workout_session.get_workout_count()
    workout_session.clear_workouts()
    
    return jsonify({
        'success': True,
        'message': f'Cleared {count} workouts'
    }), 200
