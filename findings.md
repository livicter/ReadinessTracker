# Findings

- ReadinessBreakdown lives in ReadinessTracker/Models/HealthData.swift (not ReadinessCalculator.swift).
- RecoveryCalculator.calculateBreakdown returns RecoveryBreakdown with hrvScore, rhrScore, sleepScore, tempScore, respScore, totalScore.
- StrainCalculator.calculate returns Double (0-21).
- Need custom decoder on ReadinessBreakdown to keep persisted old data loading.
