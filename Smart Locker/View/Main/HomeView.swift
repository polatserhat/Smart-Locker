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
                    .fill(isSelected ? Color.primaryYellow : Color.secondaryGray)
            )
        }
    }
}

struct HomeView: View {
    @State private var selectedCategory = 0
    @State private var showLockerMap = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Top Section
                HStack {
                    // Profile Picture
                    Image("profile_placeholder")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    
                    Spacer()
                    
                    // Location Pin
                    Button(action: {}) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.primaryBlack)
                    }
                }
                .padding(.top, 20)
                
                // Greeting and Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hello, Muhammad")
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
                
                Spacer()
                
                // Locker Illustration and CTA
                VStack(spacing: 24) {
                    Image("locker_illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                    
                    Button(action: {
                        showLockerMap = true
                    }) {
                        HStack {
                            Text("START TO RENT")
                                .fontWeight(.bold)
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 20))
                        }
                        .foregroundColor(.primaryBlack)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryYellow)
                        .cornerRadius(16)
                        .shadow(color: Color.primaryYellow.opacity(0.3), radius: 10, x: 0, y: 5)
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
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 