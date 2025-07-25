import SwiftUI
import Combine
import Foundation

// MARK: - App Entry Point
@main
struct QuitSmokingApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Models
enum SubscriptionTier {
    case free
    case freeAccount
    case pro
}

struct User {
    var id: String = UUID().uuidString
    var email: String?
    var quitDate: Date
    var subscriptionTier: SubscriptionTier = .free
    var cigarettesPerDay: Int = 20
    var pricePerPack: Double = 10.0
    var cigarettesPerPack: Int = 20
}

struct JournalEntry: Identifiable {
    let id = UUID()
    let date: Date
    let mood: String
    let text: String?
    let cravingLevel: Int?
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let isUnlocked: Bool
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var user: User = User(quitDate: Date())
    @Published var currentTheme: AppTheme = .light
    @Published var journalEntries: [JournalEntry] = []
    @Published var achievements: [Achievement] = []
    @Published var showingPaywall = false
    
    var smokeFreeTime: TimeInterval {
        Date().timeIntervalSince(user.quitDate)
    }
    
    var moneySaved: Double {
        let days = smokeFreeTime / 86400
        let cigarettesNotSmoked = Double(user.cigarettesPerDay) * days
        let packsNotBought = cigarettesNotSmoked / Double(user.cigarettesPerPack)
        return packsNotBought * user.pricePerPack
    }
    
    var currentStreak: Int {
        Int(smokeFreeTime / 86400)
    }
}

// MARK: - Themes
enum AppTheme {
    case light
    case dark
    
    var gradientColors: [Color] {
        switch self {
        case .light:
            return [Color(hex: "FFE5EC"), Color(hex: "E5F3FF"), Color(hex: "F0E5FF")]
        case .dark:
            return [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")]
        }
    }
    
    var textColor: Color {
        switch self {
        case .light:
            return .black
        case .dark:
            return .white
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground(theme: appState.currentTheme)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                ProgressView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(1)
                
                JournalView()
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }
                    .tag(2)
                
                CoachView()
                    .tabItem {
                        Label("Coach", systemImage: "person.fill.questionmark")
                    }
                    .tag(3)
                
                CommunityView()
                    .tabItem {
                        Label("Community", systemImage: "person.3.fill")
                    }
                    .tag(4)
            }
            .accentColor(appState.currentTheme == .light ? .blue : .cyan)
        }
        .sheet(isPresented: $appState.showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeString = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Smoke-Free Timer
                    VStack(spacing: 15) {
                        Text("Smoke-Free For")
                            .font(.title2)
                            .foregroundColor(appState.currentTheme.textColor.opacity(0.8))
                        
                        Text(timeString)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(appState.currentTheme.textColor)
                            .onReceive(timer) { _ in
                                updateTimer()
                            }
                        
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(appState.currentStreak)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Day Streak")
                                    .font(.caption)
                            }
                            
                            VStack {
                                Text("$\(appState.moneySaved, specifier: "%.2f")")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Saved")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(appState.currentTheme.textColor)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Daily Quote
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Motivation")
                            .font(.headline)
                            .foregroundColor(appState.currentTheme.textColor)
                        
                        Text("\"Every cigarette you don't smoke is a victory worth celebrating.\"")
                            .font(.body)
                            .italic()
                            .foregroundColor(appState.currentTheme.textColor.opacity(0.9))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.15))
                    )
                    
                    // Quick Actions
                    HStack(spacing: 15) {
                        QuickActionButton(
                            title: "Check In",
                            icon: "checkmark.circle.fill",
                            color: .green
                        ) {
                            // Navigate to journal
                        }
                        
                        QuickActionButton(
                            title: "Emergency",
                            icon: "exclamationmark.triangle.fill",
                            color: .red,
                            isPro: true
                        ) {
                            if appState.user.subscriptionTier == .pro {
                                // Show emergency support
                            } else {
                                appState.showingPaywall = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("QuitNow")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            appState.currentTheme = appState.currentTheme == .light ? .dark : .light
                        }
                    }) {
                        Image(systemName: appState.currentTheme == .light ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(appState.currentTheme.textColor)
                    }
                }
            }
        }
    }
    
    func updateTimer() {
        let interval = appState.smokeFreeTime
        let days = Int(interval) / 86400
        let hours = Int(interval) % 86400 / 3600
        let minutes = Int(interval) % 3600 / 60
        let seconds = Int(interval) % 60
        
        if days > 0 {
            timeString = String(format: "%dd %02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            timeString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}

// MARK: - Progress View
struct ProgressView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Overview
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        StatCard(
                            title: "Cigarettes Not Smoked",
                            value: "\(Int(Double(appState.user.cigarettesPerDay) * (appState.smokeFreeTime / 86400)))",
                            icon: "nosign"
                        )
                        
                        StatCard(
                            title: "Life Regained",
                            value: "\(Int(appState.smokeFreeTime / 3600 / 11)) hours",
                            icon: "heart.fill"
                        )
                        
                        StatCard(
                            title: "Money Saved",
                            value: "$\(appState.moneySaved, specifier: "%.2f")",
                            icon: "dollarsign.circle.fill"
                        )
                        
                        StatCard(
                            title: "Carbon Monoxide",
                            value: "Normal",
                            icon: "wind"
                        )
                    }
                    
                    // Health Milestones
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Health Recovery Timeline")
                            .font(.headline)
                            .foregroundColor(appState.currentTheme.textColor)
                        
                        HealthMilestone(
                            time: "20 minutes",
                            description: "Blood pressure drops to normal",
                            isCompleted: appState.smokeFreeTime > 1200
                        )
                        
                        HealthMilestone(
                            time: "8 hours",
                            description: "Carbon monoxide level normalizes",
                            isCompleted: appState.smokeFreeTime > 28800
                        )
                        
                        HealthMilestone(
                            time: "24 hours",
                            description: "Heart attack risk decreases",
                            isCompleted: appState.smokeFreeTime > 86400
                        )
                        
                        HealthMilestone(
                            time: "48 hours",
                            description: "Nerve endings start to regenerate",
                            isCompleted: appState.smokeFreeTime > 172800
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

// MARK: - Journal View
struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingNewEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Add Entry Button
                    Button(action: {
                        showingNewEntry = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Journal Entry")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue)
                        )
                    }
                    
                    // Journal Entries
                    ForEach(appState.journalEntries) { entry in
                        JournalEntryCard(entry: entry)
                    }
                }
                .padding()
            }
            .navigationTitle("Journal")
            .sheet(isPresented: $showingNewEntry) {
                NewJournalEntryView()
            }
        }
    }
}

// MARK: - Coach View
struct CoachView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            if appState.user.subscriptionTier == .pro {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("AI Coach")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your personalized quit-smoking coach is here to help!")
                            .multilineTextAlignment(.center)
                        
                        // AI Coach features would go here
                    }
                    .padding()
                }
            } else {
                ProFeatureLockedView(
                    feature: "AI Coach",
                    description: "Get personalized advice and support from our AI-powered coach"
                )
            }
        }
    }
}

// MARK: - Community View
struct CommunityView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            if appState.user.subscriptionTier == .free {
                ProFeatureLockedView(
                    feature: "Community",
                    description: "Connect with others on their quit-smoking journey"
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Community")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Community features would go here
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct AnimatedGradientBackground: View {
    let theme: AppTheme
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: theme.gradientColors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isPro: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if isPro {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                            .offset(x: 15, y: -15)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(color)
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct HealthMilestone: View {
    let time: String
    let description: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(time)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct JournalEntryCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.mood)
                    .font(.title2)
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let text = entry.text {
                Text(text)
                    .font(.body)
                    .lineLimit(3)
            }
            
            if let cravingLevel = entry.cravingLevel {
                HStack {
                    Text("Craving Level:")
                        .font(.caption)
                    
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= cravingLevel ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct NewJournalEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedMood = "😊"
    @State private var journalText = ""
    @State private var cravingLevel = 3
    
    let moods = ["😊", "😔", "😤", "😌", "😰", "💪", "🤔", "😴"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("How are you feeling?") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(moods, id: \.self) { mood in
                                Text(mood)
                                    .font(.largeTitle)
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(selectedMood == mood ? Color.blue : Color.gray.opacity(0.2))
                                    )
                                    .onTapGesture {
                                        selectedMood = mood
                                    }
                            }
                        }
                    }
                }
                
                Section("Journal Entry") {
                    TextEditor(text: $journalText)
                        .frame(minHeight: 100)
                }
                
                Section("Craving Level") {
                    HStack {
                        ForEach(1...5, id: \.self) { level in
                            Image(systemName: level <= cravingLevel ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .onTapGesture {
                                    cravingLevel = level
                                }
                        }
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let entry = JournalEntry(
                            date: Date(),
                            mood: selectedMood,
                            text: journalText.isEmpty ? nil : journalText,
                            cravingLevel: cravingLevel
                        )
                        appState.journalEntries.insert(entry, at: 0)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProFeatureLockedView: View {
    let feature: String
    let description: String
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(feature)
                .font(.title)
                .fontWeight(.bold)
            
            Text(description)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                appState.showingPaywall = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Pro")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue)
                )
            }
        }
        .padding()
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Get the most out of your quit-smoking journey")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        PaywallFeature(
                            icon: "brain",
                            title: "AI Coach",
                            description: "Personalized advice based on your habits"
                        )
                        
                        PaywallFeature(
                            icon: "exclamationmark.triangle.fill",
                            title: "Emergency Button",
                            description: "Instant support during cravings"
                        )
                        
                        PaywallFeature(
                            icon: "chart.bar.fill",
                            title: "Advanced Analytics",
                            description: "Deep insights into your progress"
                        )
                        
                        PaywallFeature(
                            icon: "person.3.fill",
                            title: "Community Access",
                            description: "Connect with others on the same journey"
                        )
                        
                        PaywallFeature(
                            icon: "paintbrush.fill",
                            title: "Custom Themes",
                            description: "Personalize your app experience"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Pricing Options
                    VStack(spacing: 15) {
                        PricingOption(
                            title: "Monthly",
                            price: "$4.99",
                            period: "per month",
                            isPopular: false
                        )
                        
                        PricingOption(
                            title: "Yearly",
                            price: "$24.99",
                            period: "per year",
                            isPopular: true,
                            savings: "Save 58%"
                        )
                        
                        PricingOption(
                            title: "Lifetime",
                            price: "$59.99",
                            period: "one time",
                            isPopular: false
                        )
                    }
                    .padding(.horizontal)
                    
                    Text("7-day free trial included")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PaywallFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PricingOption: View {
    let title: String
    let price: String
    let period: String
    let isPopular: Bool
    var savings: String? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            Text(title)
                .font(.headline)
            
            HStack(baseline: .bottom, spacing: 5) {
                Text(price)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(period)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let savings = savings {
                Text(savings)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Button(action: {
                // Handle subscription
            }) {
                Text("Subscribe")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(isPopular ? Color.green : Color.blue)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isPopular ? Color.green : Color.gray.opacity(0.3), lineWidth: isPopular ? 2 : 1)
        )
    }
}

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}