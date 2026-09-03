import SwiftUI

struct CheckInView: View {
    @StateObject private var metadataStore = MetadataStore.shared

    @State private var selectedTime: CheckInTime = .morning
    @State private var showSavedConfirmation = false
    
    // Morning
    @State private var subjectiveFeel = 3
    @State private var workloadStress = 3
    @State private var mentalFatigue = 3
    @State private var alcoholConsumed = false
    @State private var alcoholDrinks = 1
    @State private var caffeineAfter2pm = false
    @State private var isSick = false
    @State private var isStressed = false
    @State private var hadNap = false
    @State private var napDuration = 30
    @State private var napQuality = 3
    
    // Evening
    @State private var workoutToday = false
    @State private var workoutType = ""
    @State private var workoutRPE = 5
    @State private var workoutDuration = 45
    @State private var plannedWorkoutTomorrow = false
    @State private var plannedWorkoutType = ""
    @State private var plannedIntensity = "Moderate"
    
    private let intensities = ["Light", "Moderate", "Heavy"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                Form {
                    Picker("Check-in", selection: $selectedTime) {
                        Text("Morning").tag(CheckInTime.morning)
                        Text("Evening").tag(CheckInTime.evening)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)

                    if selectedTime == .morning {
                        morningSection
                    } else {
                        eveningSection
                    }

                    if let existing = metadataStore.metadataFor(date: Date(), timeOfDay: selectedTime) {
                        Section {
                            Text("Already checked in: \(existing.summaryText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)

                if showSavedConfirmation {
                    VStack {
                        Label("Check-in saved", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.green, in: Capsule())
                            .padding(.top, 8)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showSavedConfirmation)
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCheckIn() }
                }
            }
            .onAppear(perform: loadExisting)
            .onChange(of: selectedTime) { _ in
                Haptic.selectionChanged()
                loadExisting()
            }
        }
    }
    
    private var morningSection: some View {
        Group {
            Section("Physical State") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you feel? \(subjectiveFeel)/5")
                        .font(.subheadline)
                    feelPicker(binding: $subjectiveFeel)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workload stress \(workloadStress)/5")
                        .font(.subheadline)
                    Text("How stressful was yesterday's work?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    feelPicker(binding: $workloadStress, color: .orange)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mental fatigue \(mentalFatigue)/5")
                        .font(.subheadline)
                    Text("How mentally drained do you feel?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    feelPicker(binding: $mentalFatigue, color: .purple)
                }
            }
            
            Section("Nap") {
                Toggle("Did you nap?", isOn: $hadNap)
                if hadNap {
                    VStack(alignment: .leading) {
                        Text("Duration: \(napDuration) min")
                        Slider(value: .init(
                            get: { Double(napDuration) },
                            set: { napDuration = Int($0) }
                        ), in: 10...120, step: 5)
                    }
                    VStack(alignment: .leading) {
                        Text("Nap quality: \(napQuality)/5")
                        feelPicker(binding: $napQuality, color: .blue)
                    }
                }
            }
            
            Section("Last Night") {
                Toggle("Alcohol consumed?", isOn: $alcoholConsumed)
                if alcoholConsumed {
                    Stepper("Drinks: \(alcoholDrinks)", value: $alcoholDrinks, in: 1...10)
                }
                Toggle("Caffeine after 2pm?", isOn: $caffeineAfter2pm)
            }
            
            Section("Wellness") {
                Toggle("Feeling sick?", isOn: $isSick)
                Toggle("Feeling stressed?", isOn: $isStressed)
            }
        }
    }
    
    private var eveningSection: some View {
        Group {
            Section("Today's Activity") {
                Toggle("Workout today?", isOn: $workoutToday)
                if workoutToday {
                    TextField("Type (e.g. Run, Lift, HIIT)", text: $workoutType)
                    
                    VStack(alignment: .leading) {
                        Text("Duration: \(workoutDuration) min")
                        Slider(value: .init(
                            get: { Double(workoutDuration) },
                            set: { workoutDuration = Int($0) }
                        ), in: 10...180, step: 5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("RPE (Rate of Perceived Exertion): \(workoutRPE)/10")
                            .font(.subheadline)
                        Text("How hard was the workout?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: .init(
                            get: { Double(workoutRPE) },
                            set: { workoutRPE = Int($0) }
                        ), in: 1...10, step: 1)
                        HStack {
                            Text("Easy")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Max effort")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Tomorrow") {
                Toggle("Planned workout?", isOn: $plannedWorkoutTomorrow)
                if plannedWorkoutTomorrow {
                    TextField("Type", text: $plannedWorkoutType)
                    Picker("Intensity", selection: $plannedIntensity) {
                        ForEach(intensities, id: \.self) { intensity in
                            Text(intensity).tag(intensity)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    private func feelPicker(binding: Binding<Int>, color: Color = .green) -> some View {
        HStack {
            ForEach(1...5, id: \.self) { i in
                Button {
                    Haptic.tap()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        binding.wrappedValue = i
                    }
                } label: {
                    Circle()
                        .fill(i <= binding.wrappedValue ? color : Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(i)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(i <= binding.wrappedValue ? .white : .gray)
                        )
                        .scaleEffect(i == binding.wrappedValue ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: binding.wrappedValue)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    /// Pre-populate the form from today's existing check-in for the selected time of day.
    private func loadExisting() {
        guard let existing = metadataStore.metadataFor(date: Date(), timeOfDay: selectedTime) else { return }
        switch selectedTime {
        case .morning:
            subjectiveFeel = existing.subjectiveFeel ?? 3
            workloadStress = existing.workloadStress ?? 3
            mentalFatigue = existing.mentalFatigue ?? 3
            alcoholConsumed = existing.alcoholConsumed
            alcoholDrinks = existing.alcoholDrinks ?? 1
            caffeineAfter2pm = existing.caffeineAfter2pm
            isSick = existing.isSick
            isStressed = existing.isStressed
            hadNap = existing.hadNap
            napDuration = existing.napDurationMinutes ?? 30
            napQuality = existing.napQuality ?? 3
        case .evening:
            workoutToday = existing.workoutToday
            workoutType = existing.workoutType ?? ""
            workoutRPE = existing.workoutRPE ?? 5
            workoutDuration = existing.workoutDurationMinutes ?? 45
            plannedWorkoutTomorrow = existing.plannedWorkoutTomorrow
            plannedWorkoutType = existing.plannedWorkoutType ?? ""
            plannedIntensity = existing.plannedWorkoutIntensity ?? "Moderate"
        }
    }

    private func saveCheckIn() {
        let metadata: UserMetadata
        switch selectedTime {
        case .morning:
            metadata = UserMetadata(
                date: Date(),
                timeOfDay: .morning,
                subjectiveFeel: subjectiveFeel,
                workloadStress: workloadStress,
                mentalFatigue: mentalFatigue,
                alcoholConsumed: alcoholConsumed,
                alcoholDrinks: alcoholConsumed ? alcoholDrinks : nil,
                caffeineAfter2pm: caffeineAfter2pm,
                isSick: isSick,
                isStressed: isStressed,
                hadNap: hadNap,
                napDurationMinutes: hadNap ? napDuration : nil,
                napQuality: hadNap ? napQuality : nil
            )
        case .evening:
            metadata = UserMetadata(
                date: Date(),
                timeOfDay: .evening,
                workoutToday: workoutToday,
                workoutType: workoutToday ? workoutType : nil,
                workoutRPE: workoutToday ? workoutRPE : nil,
                workoutDurationMinutes: workoutToday ? workoutDuration : nil,
                plannedWorkoutTomorrow: plannedWorkoutTomorrow,
                plannedWorkoutType: plannedWorkoutTomorrow ? plannedWorkoutType : nil,
                plannedWorkoutIntensity: plannedWorkoutTomorrow ? plannedIntensity : nil
            )
        }
        metadataStore.save(metadata)
        Haptic.success()

        // Tab context: nothing to dismiss, show a brief confirmation instead.
        showSavedConfirmation = true
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            showSavedConfirmation = false
        }
    }
}
