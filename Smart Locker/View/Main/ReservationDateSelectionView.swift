import SwiftUI

struct ReservationDateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var currentMonth = Date()
    @State private var selectedDates = Set<Date>()
    @State private var showLocationSelection = false
    @State private var error: String?
    @State private var showError = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
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
        VStack(spacing: 24) {
            // Header with back button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.primaryBlack)
                }
                
                Spacer()
                
                Text("Select Dates")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.top, 20)
            
            // Calendar Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(isPreviousMonthAvailable ? AppColors.primaryBlack : Color.gray)
                }
                .disabled(!isPreviousMonthAvailable)
                
                Spacer()
                
                Text(currentMonth, formatter: DateFormatter.monthYear)
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.primaryBlack)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
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
                                toggleDate(date)
                            }
                        }) {
                            Text(dateFormatter.string(from: date))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(selectedDates.contains(date) ? AppColors.primaryYellow : Color.clear)
                                .foregroundColor(
                                    isDateInPast(date) 
                                    ? .gray.opacity(0.5) 
                                    : (selectedDates.contains(date) ? .white : .primary)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    isDateInPast(date) ?
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    : nil
                                )
                        }
                        .disabled(!isDateSelectable(date))
                    } else {
                        Text(dateFormatter.string(from: date))
                            .font(.system(.body, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Selected Dates Summary
            if !selectedDates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Dates")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedDates).sorted(), id: \.self) { date in
                                Text(date.formatted(.dateTime.day().month().year()))
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.primaryYellow.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
            }
            
            // Confirm Button
            Button(action: {
                showLocationSelection = true
            }) {
                Text("Confirm Dates")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        selectedDates.isEmpty
                        ? Color.gray
                        : AppColors.primaryBlack
                    )
                    .cornerRadius(12)
            }
            .disabled(selectedDates.isEmpty)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(UIColor.systemBackground))
        .fullScreenCover(isPresented: $showLocationSelection) {
            LockerMapView(reservationDates: selectedDates)
                .environmentObject(AuthViewModel.shared ?? AuthViewModel())
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "An error occurred")
        }
    }
    
    private var isPreviousMonthAvailable: Bool {
        let today = Date()
        let firstDayOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        return firstDayOfCurrentMonth >= calendar.startOfDay(for: today)
    }
    
    private func toggleDate(_ date: Date) {
        if selectedDates.contains(date) {
            selectedDates.remove(date)
        } else {
            selectedDates.insert(date)
        }
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