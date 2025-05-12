import SwiftUI
import FirebaseFirestore


struct CategoryButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.primaryYellow : Color.gray)
            )
        }
    }
}

struct HomeView: View {
    @State private var selectedCategory = 0
    @State private var showLockerMap = false
    @State private var showReservation = false
    @State private var showProfile = false
    @State private var showPlansInfo = false
    @State private var showPastRentals = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var reservationViewModel: ReservationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Section with Profile
                HStack {
                    Button(action: {
                        showProfile = true
                    }) {
                        if let user = authViewModel.currentUser {
                            Image("profile_placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        } else {
                            Image("profile_placeholder")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                    
                    Spacer()
                    
                    // View Plans Button
                    Button(action: {
                        showPlansInfo = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                            Text("Plans")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppColors.primaryBlack)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.primaryYellow, lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Greeting and Title
                VStack(spacing: 8) {
                    Text("Hello, \(authViewModel.currentUser?.name ?? "User")")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 0) {
                        Text("Smart")
                            .font(.system(size: 44, weight: .bold))
                        Text("Locker")
                            .font(.system(size: 44, weight: .black))
                            .foregroundColor(AppColors.primaryYellow)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
                
                // Main Content Section
                VStack(spacing: 16) {
                    // Active Rental Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Rental")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if let activeRental = reservationViewModel.currentRentals.first {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activeRental.locationName)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        Text("\(activeRental.size) Locker")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(activeRental.startDate, style: .time)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.primaryYellow)
                                }
                                
                                if activeRental.status == "active" {
                                    Button(action: {
                                        // Calculate final price and end rental
                                        let endTime = Date()
                                        let startTime = activeRental.startDate
                                        let hours = Calendar.current.dateComponents([.hour, .minute], from: startTime, to: endTime)
                                        let totalHours = Double(hours.hour ?? 0) + (Double(hours.minute ?? 0) / 60.0)
                                        
                                        // Get pricing from the locker document
                                        let db = Firestore.firestore()
                                        db.collection("lockers")
                                            .document(activeRental.lockerId)
                                            .getDocument { snapshot, error in
                                                if let error = error {
                                                    print("Error fetching locker: \(error.localizedDescription)")
                                                    return
                                                }
                                                
                                                guard let data = snapshot?.data(),
                                                      let pricing = data["pricing"] as? [String: Any],
                                                      let standardPricing = pricing["standard"] as? [String: Any],
                                                      let hourlyRate = standardPricing["hourly"] as? Double else {
                                                    print("Error getting pricing data")
                                                    return
                                                }
                                                
                                                let finalPrice = max(hourlyRate * totalHours, hourlyRate) // Minimum of 1 hour
                                                
                                                // Show confirmation alert
                                                let formatter = NumberFormatter()
                                                formatter.numberStyle = .currency
                                                formatter.maximumFractionDigits = 2
                                                
                                                let priceString = formatter.string(from: NSNumber(value: finalPrice)) ?? "$\(String(format: "%.2f", finalPrice))"
                                                let hoursString = String(format: "%.1f", totalHours)
                                                
                                                // Update rental status and price
                                                let batch = db.batch()
                                                
                                                // Update rental document
                                                let rentalRef = db.collection("rentals").document(activeRental.id)
                                                batch.updateData([
                                                    "status": "completed",
                                                    "endDate": Timestamp(date: endTime),
                                                    "totalPrice": finalPrice,
                                                    "updatedAt": Timestamp(date: endTime)
                                                ], forDocument: rentalRef)
                                                
                                                // Update locker status
                                                let lockerRef = db.collection("lockers").document(activeRental.lockerId)
                                                batch.updateData([
                                                    "status": "available",
                                                    "available": true,
                                                    "currentRentalId": nil,
                                                    "updatedAt": Timestamp(date: endTime)
                                                ], forDocument: lockerRef)
                                                
                                                // Update statistics
                                                let statsRef = db.collection("statistics").document("system_stats")
                                                batch.updateData([
                                                    "locker_stats.available": FieldValue.increment(Int64(1)),
                                                    "locker_stats.occupied": FieldValue.increment(Int64(-1)),
                                                    "rental_stats.active_rentals": FieldValue.increment(Int64(-1)),
                                                    "revenue_stats.total_revenue": FieldValue.increment(finalPrice),
                                                    "revenue_stats.today_revenue": FieldValue.increment(finalPrice),
                                                    "revenue_stats.by_size.\(activeRental.size)": FieldValue.increment(finalPrice),
                                                    "revenue_stats.by_plan.standard": FieldValue.increment(finalPrice),
                                                    "usage_stats.total_rentals": FieldValue.increment(Int64(1)),
                                                    "usage_stats.rental_hours": FieldValue.increment(Int64(ceil(totalHours))),
                                                    "usage_stats.standard_rentals": FieldValue.increment(Int64(1)),
                                                    "usage_stats.total_revenue": FieldValue.increment(finalPrice)
                                                ], forDocument: statsRef)
                                                
                                                // Commit the batch
                                                batch.commit { error in
                                                    if let error = error {
                                                        print("Error ending rental: \(error.localizedDescription)")
                                                    } else {
                                                        print("Rental ended successfully")
                                                        
                                                        // Update statistics
                                                        db.collection("statistics").document("system_stats").updateData([
                                                            "locker_stats.available": FieldValue.increment(Int64(1)),
                                                            "locker_stats.occupied": FieldValue.increment(Int64(-1)),
                                                            "rental_stats.active_rentals": FieldValue.increment(Int64(-1))
                                                        ])
                                                    }
                                                }
                                            }
                                    }) {
                                        Text("End Rental")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.red)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No active rental")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    Text("Your locker rentals will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primaryYellow)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    // Past Rentals Section
                    Button(action: {
                        showPastRentals = true
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Past Rentals")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View History")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Text("Check your rental history")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primaryYellow)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Direct Rent Button
                        Button(action: {
                            showLockerMap = true
                        }) {
                            HStack {
                                Text("DIRECT RENT")
                                    .fontWeight(.bold)
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 20))
                            }
                            .foregroundColor(AppColors.primaryBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primaryYellow)
                            .cornerRadius(16)
                            .shadow(color: AppColors.primaryYellow.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        // Reservation Button
                        Button(action: {
                            showReservation = true
                        }) {
                            HStack {
                                Text("RESERVATION")
                                    .fontWeight(.bold)
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 20))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primaryBlack)
                            .cornerRadius(16)
                            .shadow(color: AppColors.primaryBlack.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showLockerMap) {
                LockerMapView()
            }
            .fullScreenCover(isPresented: $showReservation) {
                ReservationDateSelectionView()
            }
            .fullScreenCover(isPresented: $showProfile) {
                ProfilePageView()
            }
            .fullScreenCover(isPresented: $showPlansInfo) {
                PlanSelectionView(isInformationOnly: true)
            }
            .fullScreenCover(isPresented: $showPastRentals) {
                RentalHistoryView()
                    .environmentObject(reservationViewModel)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(ReservationViewModel())
    }
}
