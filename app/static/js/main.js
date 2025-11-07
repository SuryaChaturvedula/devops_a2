// ACEest Fitness & Gym - Main JavaScript

document.addEventListener('DOMContentLoaded', function() {
    console.log('ACEest Fitness & Gym - Ready!');
    
    // Auto-dismiss alerts after 5 seconds
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }, 5000);
    });
    
    // Form validation and enhancement
    const workoutForm = document.getElementById('workoutForm');
    if (workoutForm) {
        workoutForm.addEventListener('submit', function(e) {
            const exercise = document.getElementById('exercise').value.trim();
            const duration = parseInt(document.getElementById('duration').value);
            
            if (!exercise) {
                e.preventDefault();
                alert('Please enter an exercise name!');
                return false;
            }
            
            if (duration <= 0 || isNaN(duration)) {
                e.preventDefault();
                alert('Please enter a valid duration!');
                return false;
            }
            
            // Add loading state to button
            const submitBtn = workoutForm.querySelector('button[type="submit"]');
            submitBtn.classList.add('loading');
            submitBtn.disabled = true;
        });
    }
    
    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    // Add animation to stat cards
    const statCards = document.querySelectorAll('.stat-card');
    statCards.forEach((card, index) => {
        card.style.animationDelay = `${index * 0.1}s`;
    });
    
    // API Demo functions (for developers)
    window.ACEestAPI = {
        async getWorkouts(category = null) {
            try {
                const url = category ? `/api/workouts?category=${category}` : '/api/workouts';
                const response = await fetch(url);
                const data = await response.json();
                console.log('Workouts:', data);
                return data;
            } catch (error) {
                console.error('Error fetching workouts:', error);
            }
        },
        
        async addWorkout(exercise, duration, category = 'Workout') {
            try {
                const response = await fetch('/api/workouts', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ exercise, duration, category })
                });
                const data = await response.json();
                console.log('Workout added:', data);
                return data;
            } catch (error) {
                console.error('Error adding workout:', error);
            }
        },
        
        async getStats() {
            try {
                const response = await fetch('/api/workouts/stats');
                const data = await response.json();
                console.log('Stats:', data);
                return data;
            } catch (error) {
                console.error('Error fetching stats:', error);
            }
        }
    };
    
    console.log('💡 Tip: Use ACEestAPI object in console to interact with the API!');
    console.log('Example: await ACEestAPI.getWorkouts()');
});

// Add tooltips to all elements with data-bs-toggle="tooltip"
var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
});
