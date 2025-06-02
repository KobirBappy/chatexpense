import 'package:chatapp/tax_profile_model.dart';

class BangladeshTaxCalculator {
  static double calculateTax(BangladeshTaxProfile profile) {
    double taxableIncome = profile.taxableIncome;
    double tax = 0;

    // Bangladesh Tax Slabs (2023-2024)
    if (taxableIncome > 350000) {
      tax += (taxableIncome > 450000 ? 100000 : taxableIncome - 350000) * 0.05;
    }
    if (taxableIncome > 450000) {
      tax += (taxableIncome > 750000 ? 300000 : taxableIncome - 450000) * 0.10;
    }
    if (taxableIncome > 750000) {
      tax += (taxableIncome > 1150000 ? 400000 : taxableIncome - 750000) * 0.15;
    }
    if (taxableIncome > 1150000) {
      tax += (taxableIncome > 1650000 ? 500000 : taxableIncome - 1150000) * 0.20;
    }
    if (taxableIncome > 1650000) {
      tax += (taxableIncome - 1650000) * 0.25;
    }

    // Apply discounts
    if (profile.isFemale || profile.isSeniorCitizen) tax *= 0.75;
    if (profile.isDisabled) tax *= 0.50;

    // Calculate investment rebate (up to 25% of taxable income or 15,00,000 Taka)
    final totalInvestments = profile.investments.values.reduce((a, b) => a + b);
    final investmentRebate = totalInvestments * 0.15; // 15% of investments
    final maxRebate = (taxableIncome * 0.25).clamp(0, 1500000);
    final actualRebate = investmentRebate.clamp(0, maxRebate);
    
    tax -= actualRebate;
    if (tax < 0) tax = 0;

    return tax;
  }

  static Map<String, String> getTaxSlabs() {
    return {
      'First 350,000': '0%',
      'Next 100,000 (350,001 - 450,000)': '5%',
      'Next 300,000 (450,001 - 750,000)': '10%',
      'Next 400,000 (750,001 - 1,150,000)': '15%',
      'Next 500,000 (1,150,001 - 1,650,000)': '20%',
      'Remaining (Above 1,650,000)': '25%',
      'Female/Senior Citizen Discount': '25%',
      'Disabled Person Discount': '50%',
      'Investment Rebate': '15% of investment (max 25% of income or 1,500,000)',
    };
  }
}