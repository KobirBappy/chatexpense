class Validators {
  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }
  
  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Confirm Password Validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }
  
  // Phone Number Validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone number is optional
    }
    
    // Remove all non-digit characters
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digits.length > 15) {
      return 'Phone number is too long';
    }
    
    return null;
  }
  
  // Amount Validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (amount > 999999999) {
      return 'Amount is too large';
    }
    
    return null;
  }
  
  // Description Validation
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 3) {
      return 'Description must be at least 3 characters';
    }
    
    if (value.length > 500) {
      return 'Description is too long';
    }
    
    return null;
  }
  
  // Category Validation
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }
    
    return null;
  }
  
  // Date Validation
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    
    if (date.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }
    
    final minDate = DateTime.now().subtract(const Duration(days: 365 * 5));
    if (date.isBefore(minDate)) {
      return 'Date is too far in the past';
    }
    
    return null;
  }
  
  // Budget Validation
  static String? validateBudget(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Budget is optional
    }
    
    final budget = double.tryParse(value);
    if (budget == null) {
      return 'Please enter a valid budget';
    }
    
    if (budget < 0) {
      return 'Budget cannot be negative';
    }
    
    if (budget > 999999999) {
      return 'Budget is too large';
    }
    
    return null;
  }
  
  // Custom Category Validation
  static String? validateCustomCategory(String? value, List<String> existingCategories) {
    if (value == null || value.isEmpty) {
      return 'Category name is required';
    }
    
    if (value.length < 2) {
      return 'Category name must be at least 2 characters';
    }
    
    if (value.length > 30) {
      return 'Category name is too long';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Category name can only contain letters and spaces';
    }
    
    if (existingCategories.map((c) => c.toLowerCase()).contains(value.toLowerCase())) {
      return 'This category already exists';
    }
    
    return null;
  }
}