import SwiftUI

struct ReservationDateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDates: Set<Date> = []
    @State private var showLocationSelection = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    @State private var currentMonth = Date()
    
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        
        return calendar.generateDates(for: dateInterval)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
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
                        .foregroundColor(AppColors.primaryBlack)
                }
                
                Spacer()
                
                Text(monthFormatter.string(from: currentMonth))
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.primaryBlack)
                }
            }
            .padding(.horizontal)
            
            // Weekday headers
            HStack {
                ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                        Button(action: {
                            toggleDate(date)
                        }) {
                            Text(dateFormatter.string(from: date))
                                .font(.system(.body, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(
                                    selectedDates.contains(date)
                                    ? AppColors.primaryYellow
                                    : Color.clear
                                )
                                .foregroundColor(
                                    selectedDates.contains(date)
                                    ? AppColors.primaryBlack
                                    : calendar.isDateInToday(date)
                                    ? AppColors.primaryYellow
                                    : .primary
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            calendar.isDateInToday(date)
                                            ? AppColors.primaryYellow
                                            : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        }
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
                                Text(date.formatted(date: .long, time: .omitted))
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
        }
    }
    
    private func toggleDate(_ date: Date) {
        if selectedDates.contains(date) {
            selectedDates.remove(date)
        } else {
            selectedDates.insert(date)
        }
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
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

#Preview {
    ReservationDateSelectionView()
} 