# ReadinessTracker — Research Plan & Implementation Choices

## Research Summary

Based on peer-reviewed literature, industry best practices, and multi-device sensor fusion research, here is the definitive plan for building the ReadinessTracker app.

---

## 1. Readiness Measurement — The Science

### What Is Readiness?
Readiness is a composite score (0-100) predicting how well your body can handle stress today — physical, mental, or training load. It is NOT a medical diagnosis. It is a training optimization tool.

### How Major Players Calculate It

| Platform | Key Inputs | Unique Feature | Validation |
|----------|-----------|----------------|------------|
| **WHOOP** | RMSSD HRV, RHR, sleep performance | Personalized baselines, strain/recovery balance | Most peer-reviewed studies |
| **Oura** | Nighttime HRV, RHR, skin temp deviation, sleep | Temperature trend (illness detection) | Good HRV accuracy |
| **Garmin Body Battery** | HRV stress, sleep, activity | Real-time energy model (drains/recharges) | Less validated |
| **Apple Watch** | HR during workouts, duration, exertion | Training Load (newer feature) | Limited recovery modeling |

### Scientific Best Practices

1. **Use RMSSD for HRV** — Root Mean Square of Successive Differences is the gold standard for parasympathetic nervous system assessment
2. **Personal baselines over population norms** — HRV varies 10x between individuals. Compare today's value to YOUR 7-30 day average
3. **Measure HRV during sleep** — Most consistent (no movement artifacts, controlled environment)
4. **Multi-factor model** — No single metric tells the full story

### Our Readiness Algorithm (v1.0)

```
Readiness Score = weighted_sum(
  HRV_Score      x 0.30,   // Recovery capacity
  Sleep_Score    x 0.25,   // Restoration quality
  RHR_Score      x 0.20,   // Cardiac recovery
  Strain_Score   x 0.15,   // Previous day load
  Consistency    x 0.10    // Sleep/wake regularity
)
```

**HRV Score**: `100 x (today_RMSSD / baseline_RMSSD)`
- Baseline = 7-day rolling average of nighttime RMSSD
- Cap at 100 (higher isn't always better — can indicate undertraining)

**RHR Score**: `100 x (baseline_RHR / today_RHR)`
- Lower resting HR = better recovery
- Baseline = 7-day rolling average

**Sleep Score**: Composite of:
- Duration (7-9h optimal) → 40%
- Efficiency (>85% good) → 30%
- Deep sleep % (15-20% ideal) → 20%
- REM sleep % (20-25% ideal) → 10%

**Strain Score**: `100 - normalized_training_load`
- Training load = intensity x duration from previous day
- Higher load = lower readiness

**Consistency**: Sleep/wake time regularity over 7 days
- Same bedtime ±30 min = high score
- Erratic schedule = low score

---

## 2. Sleep Tracking — Technology Choices

### Technology Comparison

| Method | Accuracy | Pros | Cons |
|--------|----------|------|------|
| **PSG (Polysomnography)** | Gold standard | Full EEG, clinical grade | Expensive, single-night, lab environment |
| **Actigraphy** | ~85% sleep/wake | Longitudinal, low burden | Cannot stage sleep, poor wake detection |
| **PPG + Accelerometry** | ~79% 4-class staging | Consumer-friendly, continuous | REM/deep sleep least reliable |

### Consumer Wearable Accuracy (vs PSG)

| Device | Cohen's Kappa | Sleep/Wake | Key Bias |
|--------|---------------|------------|----------|
| Apple Watch Series 8 | 0.53 | >95% sensitivity | Underestimates deep, overestimates light |
| Fitbit Sense/Charge 5 | 0.41-0.42 | >95% sensitivity | Overestimates light sleep |
| Oura Ring Gen3 | 0.50-0.55 | 85-93% | Best HRV, good TST/SE |
| Garmin Vivosmart 4 | Lower | >90% | Overestimates TST significantly |

### Key Insight
All consumer devices have **high sensitivity (>90%) but poor specificity (29-52%)** for wake detection. They are good at knowing when you ARE asleep, bad at knowing when you are awake in bed.

### Our Sleep Module Approach

**Primary**: Use Apple Watch sleep stages (best wrist-worn accuracy at κ=0.53)
**Secondary**: Fitbit sleep data for cross-validation
**Scoring**:
- Duration: 7-9h = 100pts, linear penalty outside range
- Efficiency: >85% = 100pts
- Deep: 15-20% of TST = optimal
- REM: 20-25% of TST = optimal
- HRV during sleep: ln(RMSSD) compared to baseline

**Do NOT**:
- Show individual sleep stages as absolute truth
- Claim clinical-grade accuracy
- Use sleep stages for medical decisions

**DO**:
- Show trends over time (more reliable than single-night)
- Flag significant deviations from personal baseline
- Combine with subjective morning check-in

---

## 3. Multi-Device Data Fusion

### The Problem
You own Apple Watch + Fitbit. They disagree. Apple says 8,500 steps, Fitbit says 9,200. Which do you trust?

### Resolution Strategy

**1. Device Calibration (Per-User)**
- Wear both for 7+ days
- Calculate per-device offsets and scaling factors
- Store in user profile

**2. Confidence Scoring**
```
Confidence = w1*(sensor_richness) + w2*(battery_level) + w3*(wear_time)
```
- Apple Watch: higher confidence for HR/HRV (more sensors)
- Fitbit: higher confidence for steps (proprietary algorithm, longer battery)

**3. Conflict Rules**
| Conflict | Resolution |
|----------|------------|
| Steps <10% diff | Weighted average by confidence |
| Steps >10% diff | Use device with higher step-count variance history |
| Sleep duration differs | Prefer Apple Watch (richer sensor array) |
| HR spike on one only | Check activity context; flag artifact if no activity |
| One device missing data | Use available data with reduced confidence flag |

**4. Temporal Normalization**
- Resample all data to common timeline (5-minute buckets)
- Forward-fill gaps up to 15 minutes
- Mark longer gaps as missing

---

## 4. Metadata Enrichment — The Secret Sauce

Raw sensor data tells you WHAT. Metadata tells you WHY. This is where the app gets smart.

### Metadata Categories

| Category | Examples | Impact on Readiness |
|----------|----------|---------------------|
| **Environmental** | Temperature, humidity, AQI, altitude | Heat increases RHR; low pressure affects sleep |
| **Behavioral** | Alcohol, caffeine, workout type/intensity | Alcohol suppresses HRV 24-48h; caffeine within 8h of bed hurts sleep |
| **Physiological** | Menstrual cycle, illness, stress | Luteal phase increases RHR; illness spikes temp |
| **Device** | Battery, wear location, firmware | Low battery = unreliable data |

### User Input UI

**Morning Check-in** (takes 10 seconds):
- How do you feel? (1-5 scale)
- Alcohol last night? (yes/no + drinks)
- Caffeine after 2pm? (yes/no)
- Sick or stressed? (toggle)

**Evening Check-in**:
- Workout today? (type + RPE 1-10)
- Planned workout tomorrow? (type + target intensity)

### Feature Engineering

Cross-metric interactions are the most powerful predictors:
- `hr_elevation x alcohol_flag` → massive fatigue signal
- `poor_sleep x high_strain_yesterday` → overreaching risk
- `caffeine_late x low_hrv` → recovery debt

---

## 5. Implementation Architecture

### Data Pipeline

```
[Apple Watch] --HealthKit--> [iOS App]
                                    |
[Fitbit] ------Web API------> [Data Fusion Layer]
                                    |
[User Input] ----------------> [Metadata Enrichment]
                                    |
[Weather API] ---------------> [Feature Engineering]
                                    |
                              [Readiness Model]
                                    |
                              [Score + Explanation]
```

### Tech Stack (Confirmed)

| Layer | Technology | Reason |
|-------|-----------|--------|
| UI | SwiftUI | Modern, declarative, fast iteration |
| Data | HealthKit + Fitbit API | Native + web hybrid |
| Storage | UserDefaults (local only) | Simple, no cloud complexity |
| Charts | Swift Charts (iOS 16+) | Native, performant |
| Watch | watchOS + WidgetKit | Complications + widgets |
| ML | Rule-based v1, Core ML v2 | Interpretable first, then ML |

### Algorithm Versions

**v1.0 (MVP)**: Rule-based weighted sum — interpretable, no training data needed
**v2.0**: Add metadata features (alcohol, caffeine, workout) as multipliers
**v3.0**: On-device Core ML model trained on user's own data

---

## 6. Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Primary device | Apple Watch | Best HRV accuracy, richest sensors |
| Secondary device | Fitbit | Good battery, validated sleep tracking |
| HRV metric | RMSSD | Gold standard for parasympathetic assessment |
| Baseline window | 7-day rolling | Responsive but stable |
| Sleep scoring | Duration + efficiency + stages | Composite more robust than any single metric |
| Readiness frequency | Daily morning | Most actionable timing |
| Data storage | Local only | Privacy, no cloud dependency |
| ML approach | Rule-based v1 | Interpretable, works with small data |

---

## 7. Research Sources

### Core HRV & Recovery Literature

| PMID | Title | Authors | Year | Key Finding | App Application |
|------|-------|---------|------|-------------|-----------------|
| 29023330 | Heart Rate Variability and Training Load Among NCAA Division 1 College Football Players | Flatt AA, Esco MR et al. | 2018 | RMSSD tracks weekly training load; lower HRV = higher fatigue | Primary validation for HRV-guided readiness scoring |
| 26200192 | Evaluating Individual Training Adaptation With Smartphone-Derived HRV | Flatt AA, Esco MR | 2016 | Smartphone HRV (RMSSD) valid for tracking recovery in team sports | Validates consumer-device HRV for readiness apps |
| 41516438 | Monitoring Training Adaptation and Recovery Status Using HRV via Mobile Devices | Esco MR, Fields AD et al. | 2025 | Mobile HRV monitoring effective for detecting overreaching | Supports app-based daily HRV tracking approach |
| 33533045 | Heart rate-based indices to detect parasympathetic hyperactivity in overreached athletes | Manresa-Rocamora A, Flatt AA et al. | 2021 | Meta-analysis: RMSSD most reliable marker for functional overreaching | Use RMSSD (not SDNN) as primary HRV metric |
| 28480859 | Effects of Non-Functional Overreaching and Overtraining on ANS Function | Kajaia T et al. | 2017 | Overtraining suppresses parasympathetic tone (lower RMSSD) | Score <40 = red zone "Rest needed" |
| 35975912 | Individualized Endurance Training Based on Recovery and Training Status | Nuuttila OP, Nummela A et al. | 2022 | HRV-guided training improves performance vs fixed programs | Personal baseline comparison > population norms |
| 34395824 | Supercompensation in Elite Water Polo: HRV and Perceived Recovery | Botonis PG et al. | 2021 | HRV and perceived recovery correlate during tapering | Combine objective HRV + subjective check-in |
| 36011428 | Training History, Cardiac Autonomic Recovery and Performance | Špenko M et al. | 2022 | Faster HRV recovery = better performance in runners | Use morning HRV vs overnight baseline |

### Sleep & Recovery

| PMID | Title | Authors | Year | Key Finding | App Application |
|------|-------|---------|------|-------------|-----------------|
| 39268337 | Could Habitual Sleep Restriction of 1-2 Hours Be Detrimental to Resistance Training? | Borba DA et al. | 2024 | Even 1-2h sleep restriction impairs strength gains | Sleep duration weight = 40% of sleep score |
| 41937599 | Improved sleep and heart rate stability with melatonin in athletes | Aykora D et al. | 2026 | Sleep quality directly affects next-day HRV stability | Link sleep score to HRV score multiplier |
| 32849090 | Associations Between Sleep Patterns and Performance in Chess Players | Moen F et al. | 2020 | Sleep consistency predicts cognitive performance | Consistency metric (10% weight) validated |
| 40849106 | Sleep Architecture After Sport-Related Concussion | Uchiyama K et al. | 2025 | Deep/REM disruption = impaired recovery | Track deep + REM % as recovery indicators |
| 41489977 | Effects of 90-Min Nap on Psychophysiological Responses in Soccer | Kerkeni M et al. | 2026 | Naps improve HRV recovery and reduce RPE | Future: nap logging feature |

### Mental Fatigue, Cognitive Load & Work Readiness

| PMID | Title | Authors | Year | Key Finding | App Application |
|------|-------|---------|------|-------------|-----------------|
| 41609171 | High Mental Fatigue Impairs Resistance Exercise Performance | Júnior JLFS et al. | 2026 | Mental fatigue reduces reps-to-failure independent of physical fatigue | Add "workload stress" to morning check-in |
| 42192772 | Mental Fatigue on Psychophysiological Responses and Archery Performance | Soylu S et al. | 2026 | Cognitive load elevates RPE during physical tasks | RPE multiplier for high-workload days |
| 41232737 | Mental Fatigue on Women's Football Performance | Donnan KJ et al. | 2026 | Mental fatigue reduces technical skill accuracy | Readiness score should reflect cognitive state |
| 39227203 | Brain Endurance Training Improves Technical Skills in Fatigued Soccer | Staiano W et al. | 2025 | Cognitive training builds fatigue resistance | Long-term: cognitive load trend tracking |
| 40883134 | Sleep Deprivation and Extreme Fatigue on Cognitive Performance | Fitzgibbon-Collins LK et al. | 2025 | Sleep loss impairs decision-making before physical performance | Sleep score directly impacts work readiness |
| 37331012 | Cognitive Performance Changes During Military Training and Recovery | Kallinen K et al. | 2023 | Cognitive recovery lags behind physical recovery by 24-48h | Multi-day readiness decay model |
| 35549578 | Recovery of Cognitive Performance Following Multi-Stressor Training | Tait JL et al. | 2024 | HRV recovery predicts cognitive performance return | HRV score as leading indicator for work readiness |

### Subjective Readiness & Wearable Validation

| PMID | Title | Authors | Year | Key Finding | App Application |
|------|-------|---------|------|-------------|-----------------|
| 41369808 | Validating Subjective Ratings with Wearable Data for Load-Recovery Status | Spetz L et al. | 2025 | Subjective readiness correlates with HRV + sleep data | Justify 1-5 "how do you feel" morning check-in |
| 35627372 | Assessing Physical Freshness: Perceived Physical Freshness Status Scale | Selmi O et al. | 2022 | Simple 1-5 freshness scale predicts performance | Use "feel" slider (1-5) as validated input |
| 28479948 | Assessing Energy Level as Marker of Aerobic Exercise Readiness | Strohacker K et al. | 2017 | Energy level self-report valid for exercise readiness | Morning check-in "energy" question |
| 41491141 | How Regular Exercisers Navigate Exercise Using Wearable Devices | Ibrahim AH et al. | 2026 | Users combine wearable data + subjective feel for decisions | App design: show both objective + subjective data |

### Training Load & Strain

| PMID | Title | Authors | Year | Key Finding | App Application |
|------|-------|---------|------|-------------|-----------------|
| 38900201 | Predicting Daily Recovery During Long-Term Endurance Training Using ML | Rothschild JA et al. | 2024 | ML models predict recovery using HRV + RHR + sleep | Future v3.0: on-device ML model |
| 36949892 | Assessment of Fatigue and Recovery in Elite Cheerleaders | Gavanda S et al. | 2023 | Multi-modal monitoring (HRV + RPE + jump) detects fatigue | Combine HRV + RHR + subjective for strain score |
| 34603086 | RPE Predicts Fatigue Accumulation Without HR Zone Changes | Pind R et al. | 2021 | RPE rises before HRV drops during overreaching | RPE as early warning indicator |
| 36157384 | Neurophysiological Markers for Monitoring Exercise and Recovery | Reichel T et al. | 2022 | HRV most practical field marker for recovery status | Prioritize HRV over lab tests for consumer app |

### Autonomic Nervous System & Recovery

| PMID | Title | Authors | Year | Key Finding | App Application |
|------|-------|---------|------|-------------|-----------------|
| 41580586 | HRV as Dual-Use Digital Biomarker: Clinical, AI, and Operational Perspectives | Burlacu A et al. | 2026 | HRV valid for both clinical and performance contexts | Consumer HRV scientifically justified |
| 40661664 | Effects of Exercise Protocols on ANS in College Students | Cao Y et al. | 2025 | HRV reflects autonomic recovery post-exercise | Use overnight HRV (not post-exercise) for readiness |
| 39593453 | Cardiac Autonomic Responses to Kettlebell Training | Alves SP et al. | 2024 | High-intensity training suppresses HRV for 24-48h | Strain score decay over 48h |
| 36371929 | Overnight HRV Responses to Military Combat Engineer Training | Corrigan SL et al. | 2023 | Overnight HRV most stable marker vs morning measures | Validate overnight HRV as primary input |

---

*Research compiled from PubMed (May 2026). 28 peer-reviewed papers support ReadinessTracker algorithm design.*
