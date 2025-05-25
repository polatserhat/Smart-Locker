import SwiftUI

struct ReservationDateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    @State private var selectedStartTime = Date()
    @State private var showLocationSelection = false
    @State private var error: String?
    @State private var showError = false
    @State private var navigateToLockerMap = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    // Helper function to check if a date is in the past
    private func isDateInPast(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        return date < today
    }
    
    // Helper function to check if a date is selectable
    private func isDateSelectable(_ date: Date) -> Bool {
        !isDateInPast(date) && calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Select Date & Time")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Calendar Section
                VStack(spacing: 16) {
                    // Calendar Header
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(isPreviousMonthAvailable ? AppColors.textPrimary : Color.gray)
                        }
                        .disabled(!isPreviousMonthAvailable)
                        
                        Spacer()
                        
                        Text(currentMonth, formatter: DateFormatter.monthYear)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Calendar Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        
                        let days = calendar.generateDates(
                            for: DateInterval(
                                start: calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!,
                                end: calendar.date(byAdding: DateComponents(month: 1, day: -1), to: currentMonth)!
                            )
                        )
                        
                        ForEach(days, id: \.self) { date in
                            if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                                Button(action: {
                                    if isDateSelectable(date) {
                                        selectedDate = date
                                    }
                                }) {
                                    Text(dateFormatter.string(from: date))
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .background(
                                            selectedDate != nil && calendar.isDate(selectedDate!, inSameDayAs: date) 
                                            ? AppColors.secondary 
                                            : Color.clear
                                        )
                                        .foregroundColor(
                                            isDateInPast(date) 
                                            ? AppColors.textSecondary.opacity(0.5) 
                                            : (selectedDate != nil && calendar.isDate(selectedDate!, inSameDayAs: date) 
                                               ? Color.white 
                                               : AppColors.textPrimary)
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            isDateInPast(date) ?
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                                            : nil
                                        )
                                }
                                .disabled(!isDateSelectable(date))
                            } else {
                                Text(dateFormatter.string(from: date))
                                    .font(.system(.body, design: .rounded))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Time Selection Section - Compact Design
                if selectedDate != nil {
                    VStack(spacing: 12) {
                        Text("Select Start Time")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Compact Time Picker
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(AppColors.secondary)
                                .font(.title3)
                            
                            DatePicker("", selection: $selectedStartTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "en_US"))
                                .onAppear {
                                    UIDatePicker.appearance().minuteInterval = 15
                                }
                            
                            Spacer()
                            
                            Text(timeFormatter.string(from: selectedStartTime))
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.secondary.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(AppColors.surface)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: selectedDate)
                }
                
                Spacer()
                
                // Selected Date and Time Summary
                if let selectedDate = selectedDate {
                    VStack(spacing: 12) {
                        Text("Reservation Summary")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(selectedDate.formatted(.dateTime.day().month().year()))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                Text(timeFormatter.string(from: selectedStartTime))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: selectedDate)
                }
                
                // Confirm Button
                Button(action: {
                    print("🔘 Continue button pressed")
                    print("📅 Selected date: \(selectedDate?.description ?? "nil")")
                    print("🕐 Selected time: \(selectedStartTime)")
                    navigateToLockerMap = true
                    print("🧭 Navigation state set to: \(navigateToLockerMap)")
                }) {
                    Text("Continue to Location Selection")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedDate != nil ? AppColors.secondary : AppColors.textSecondary)
                        .cornerRadius(12)
                }
                .disabled(selectedDate == nil)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToLockerMap) {
                if let selectedDate = selectedDate {
                    LockerMapView(reservationDates: Set([selectedDate]))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "An error occurred")
            }
            .onAppear {
                // Set default start time to the next available 15-minute slot
                let calendar = Calendar.current
                let now = Date()
                let minutes = calendar.component(.minute, from: now)
                let roundedMinutes = ((minutes / 15) + 1) * 15
                
                if let nextSlot = calendar.date(byAdding: .minute, value: roundedMinutes - minutes, to: now) {
                    selectedStartTime = nextSlot
                }
                
                print("🔍 ReservationDateSelectionView appeared")
            }
        }
    }
    
    private var isPreviousMonthAvailable: Bool {
        let today = Date()
        let firstDayOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        return firstDayOfCurrentMonth >= calendar.startOfDay(for: today)
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth),
           isPreviousMonthAvailable {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

extension Calendar {
    func generateDates(for dateInterval: DateInterval) -> [Date] {
        var dates: [Date] = []
        dates.append(dateInterval.start)
        
        enumerateDates(
            startingAfter: dateInterval.start,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < dateInterval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

#Preview {
    ReservationDateSelectionView()
        .environmentObject(AuthViewModel())
} 