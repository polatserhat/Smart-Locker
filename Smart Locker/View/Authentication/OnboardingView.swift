import SwiftUI

struct OnboardingStep {
    let image: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var shouldShowLogin = false
    
    let steps = [
       
        OnboardingStep(
            image: "onboarding1",
            title: "Smart Lockers For Travelers",
            description: "Effortlessly store your luggage using our secure lockers located at key transportation points."
        ),
        OnboardingStep(
            image: "onboarding2",
            title: "Airport Access",
            description: "Find Smart Lockers in major airports and move freely before or after your flight."
        ),
        OnboardingStep(
            image: "onboarding3",
            title: "App-Based Entry",
            description: "Unlock lockers directly with the Smart Locker app – no queues, no hassle."
        ),
        OnboardingStep(
            image: "onboarding4",
            title: "Widespread Locations",
            description: "Our lockers are placed across city centers, stations, and airports to serve you better."
        ),
        OnboardingStep(
            image: "onboarding5",
            title: "Travel Light",
            description: "Explore your destination hands-free while your luggage stays safe and nearby."
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        GeometryReader { geometry in
                            VStack(alignment: .center, spacing: 0) {
                                if index == 0 {
                                    Image(steps[index].image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width * 0.85)
                                        .padding(.bottom, 20)

                                    VStack(spacing: 8) {
                                        Text(steps[index].title)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)

                                        Text("Your Luggage, Your Freedom")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding(.horizontal, 32)
                                } else {
                                    ZStack(alignment: .bottom) {
                                        Image(steps[index].image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: geometry.size.height * 0.8)
                                            .frame(maxWidth: .infinity)
                                            .clipped()

                                        VStack(spacing: 8) {
                                            Text(steps[index].title)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity)

                                            Text(steps[index].description)
                                                .font(.body)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .padding(.horizontal, 32)
                                        .padding(.bottom, 32)
                                    }
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                }

                                Spacer()
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .padding(.top, 16)
                
                Button(action: {
                    if currentStep < steps.count - 1 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        shouldShowLogin = true
                    }
                }) {
                    Text(currentStep == steps.count - 1 ? "GET STARTED" : "NEXT")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.gray]),
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .background(Color.white)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowLogin) {
            LoginView()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
