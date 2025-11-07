"""
User profile and health calculations module
Version: 1.3
"""
from typing import Dict, Optional


class UserProfile:
    """User profile with health calculations"""
    
    def __init__(self, name: str = "", reg_id: str = "",
                 height: float = 0, weight: float = 0,
                 age: int = 0, gender: str = ""):
        self.name = name
        self.reg_id = reg_id
        self.height = height  # in cm
        self.weight = weight  # in kg
        self.age = age
        self.gender = gender  # Male/Female
    
    def calculate_bmi(self) -> Optional[float]:
        """Calculate Body Mass Index"""
        if self.height > 0 and self.weight > 0:
            height_m = self.height / 100  # convert to meters
            return round(self.weight / (height_m ** 2), 2)
        return None
    
    def get_bmi_category(self) -> str:
        """Get BMI category"""
        bmi = self.calculate_bmi()
        if bmi is None:
            return "Unknown"
        if bmi < 18.5:
            return "Underweight"
        elif 18.5 <= bmi < 25:
            return "Normal weight"
        elif 25 <= bmi < 30:
            return "Overweight"
        else:
            return "Obese"
    
    def calculate_bmr(self) -> Optional[float]:
        """Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation"""
        if self.weight > 0 and self.height > 0 and self.age > 0 and self.gender:
            if self.gender.lower() == 'male':
                bmr = (10 * self.weight) + (6.25 * self.height) - (5 * self.age) + 5
            else:  # female
                bmr = (10 * self.weight) + (6.25 * self.height) - (5 * self.age) - 161
            return round(bmr, 2)
        return None
    
    def calculate_daily_calories(self, activity_level: str = "moderate") -> Optional[float]:
        """Calculate daily calorie needs based on activity level"""
        bmr = self.calculate_bmr()
        if bmr is None:
            return None
        
        multipliers = {
            'sedentary': 1.2,
            'light': 1.375,
            'moderate': 1.55,
            'active': 1.725,
            'very_active': 1.9
        }
        
        multiplier = multipliers.get(activity_level.lower(), 1.55)
        return round(bmr * multiplier, 2)
    
    def to_dict(self) -> Dict:
        """Convert profile to dictionary"""
        return {
            'name': self.name,
            'reg_id': self.reg_id,
            'height': self.height,
            'weight': self.weight,
            'age': self.age,
            'gender': self.gender,
            'bmi': self.calculate_bmi(),
            'bmi_category': self.get_bmi_category(),
            'bmr': self.calculate_bmr(),
            'daily_calories': self.calculate_daily_calories()
        }
    
    def is_complete(self) -> bool:
        """Check if profile is complete"""
        return all([
            self.name,
            self.height > 0,
            self.weight > 0,
            self.age > 0,
            self.gender
        ])


# Global user profile (in-memory)
user_profile = UserProfile()
