import SwiftUI

struct LoginStartView: View {
    @ObservedObject var loginService: LoginService
    @State private var showFindSchool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Canvas LMS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        showFindSchool = true
                    }) {
                        Text("Find my school")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $showFindSchool) {
                LoginFindSchoolView(loginService: loginService)
            }
        }
    }
}

