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
            image: "smartlocker.logo",
            title: "Smart Lockers For Travelers",
            description: ""
        ),
        OnboardingStep(
            image: "locker.wifi",
            title: "",
            description: "Use our app to easily access lockers and have an effortless trip."
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            if index == 0 {
                                // Logo screen
                                Image(steps[index].image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .padding(.bottom, 40)
                                
                                Text(steps[index].title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                            } else {
                                // Feature description screen
                                Image(steps[index].image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .padding(.bottom, 40)
                                
                                Text(steps[index].description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentStep < steps.count - 1 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        shouldShowLogin = true
                    }
                }) {
                    Text("NEXT")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryBlack)
                        .cornerRadius(12)
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