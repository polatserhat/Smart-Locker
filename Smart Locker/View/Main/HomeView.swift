import SwiftUI

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
