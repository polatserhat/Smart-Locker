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
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Top Section
                HStack {
                    // Profile Picture with Navigation
                    Button(action: {
                        showProfile = true
                    }) {
                        if let user = authViewModel.currentUser {
                            VStack(alignment: .leading) {
                                Image("profile_placeholder")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            }
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
                    
                    // Location Pin
                    Button(action: {}) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.primaryBlack)
                    }
                }
                .padding(.top, 20)
                
                // Greeting and Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hello, \(authViewModel.currentUser?.name ?? "User")")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Text("Smart Travel")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Storage")
                        .font(.largeTitle)
                        .fontWeight(.black)
                }
                
                // Category Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(
                            icon: "airplane",
                            title: "Airports",
                            isSelected: selectedCategory == 0
                        ) {
                            selectedCategory = 0
                        }
                        
                        CategoryButton(
                            icon: "tram.fill",
                            title: "Stations",
                            isSelected: selectedCategory == 1
                        ) {
                            selectedCategory = 1
                        }
                        
                        CategoryButton(
                            icon: "building.2.fill",
                            title: "City Centers",
                            isSelected: selectedCategory == 2
                        ) {
                            selectedCategory = 2
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // View Plans Button
                Button(action: {
                    showPlansInfo = true
                }) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                        Text("View Available Plans")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppColors.primaryBlack)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppColors.primaryYellow, lineWidth: 1)
                    )
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                // Locker Illustration and CTA Buttons
                VStack(spacing: 24) {
                    Image("locker_illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                    
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
                        .padding()
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
                        .padding()
                        .background(AppColors.primaryBlack)
                        .cornerRadius(16)
                        .shadow(color: AppColors.primaryBlack.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.bottom, 30)
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
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthViewModel())
    }
} 
