//
//  ContentView.swift
//  Eventhub
//
//  Created by Dhruv Rasikbhai Jivani on 10/2/25.
//

import SwiftUI
import CoreData

@main
struct EventHubApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RegistrationView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}

// MARK: - Core Data Setup

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        let modelName = "Eventhub"
        
        print("🔍 Attempting to load Core Data model: \(modelName)")
        
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") {
            print("✅ Found model at: \(modelURL)")
            
            guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("❌ Failed to create NSManagedObjectModel from URL: \(modelURL)")
            }
            
            print("✅ Created managed object model")
            print("📦 Entities: \(managedObjectModel.entities.map { $0.name ?? "unnamed" })")
            
            container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        } else {
            print("⚠️ Model not found at expected location")
            print("⚠️ Trying standard initialization...")
            container = NSPersistentContainer(name: modelName)
        }
        
        var loadError: Error?
        var storeLoaded = false
        
        container.loadPersistentStores { description, error in
            if let error = error {
                loadError = error
                print("❌ Core Data failed to load: \(error.localizedDescription)")
                print("❌ Description: \(description)")
            } else {
                storeLoaded = true
                print("✅ Core Data store loaded successfully")
                print("✅ Store URL: \(description.url?.absoluteString ?? "unknown")")
                print("✅ Store type: \(description.type)")
            }
        }
        
        if let error = loadError {
            print("❌ FATAL ERROR: Core Data could not be initialized")
            print("❌ Please ensure you have a '\(modelName).xcdatamodeld' file in your project")
            print("❌ Error details: \(error)")
            fatalError("Core Data failed to load: \(error.localizedDescription)")
        }
        
        if !storeLoaded {
            fatalError("Core Data store failed to load for unknown reason")
        }
        
        let entities = container.managedObjectModel.entities
        print("📦 Available entities: \(entities.map { $0.name ?? "unnamed" })")
        
        if entities.isEmpty {
            print("⚠️ WARNING: No entities found in the model!")
            print("⚠️ You need to create a 'Registrant' entity in your .xcdatamodeld file")
        } else if !entities.contains(where: { $0.name == "Registrant" }) {
            print("⚠️ WARNING: 'Registrant' entity not found!")
            print("⚠️ Available: \(entities.map { $0.name ?? "unnamed" })")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("✅ PersistenceController initialization complete")
    }
}

// MARK: - Core Data Registrant Extension

extension Registrant {
    static func create(in context: NSManagedObjectContext, fullName: String, email: String, age: Int16, gender: String, isStudent: Bool) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Registrant", in: context) else {
            print("❌ Failed to find Registrant entity description")
            print("Available entities: \(context.persistentStoreCoordinator?.managedObjectModel.entities.map { $0.name ?? "unnamed" } ?? [])")
            return
        }
        
        let newRegistrant = Registrant(entity: entity, insertInto: context)
        newRegistrant.id = UUID()
        newRegistrant.fullname = fullName
        newRegistrant.email = email
        newRegistrant.age = age
        newRegistrant.gender = gender
        newRegistrant.isStudent = isStudent
        newRegistrant.timestamp = Date()
        
        do {
            try context.save()
            print("""
            ✅ New registrant added:
            Name: \(fullName)
            Email: \(email)
            Age: \(age)
            Gender: \(gender)
            Student: \(isStudent ? "Yes" : "No")
            """)
        } catch {
            print("❌ Failed to save registrant: \(error.localizedDescription)")
        }
    }
}

// MARK: - Registration View

struct RegistrationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var age = 18
    @State private var gender = "Prefer not to say"
    @State private var isStudent = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var navigateToConfirmation = false
    
    let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("Event Registration")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Please fill in your details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
            Section("Personal Information") {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    TextField("Full Name", text: $fullName)
                }
                
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Stepper("Age: \(age)", value: $age, in: 18...100)
                }
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { genderOption in
                            Text(genderOption)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Toggle("Are you a student?", isOn: $isStudent)
                }
            }
            
            Section {
                Button(action: submitRegistration) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Submit Registration")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationDestination(isPresented: $navigateToConfirmation) {
            ConfirmationView(
                fullName: fullName,
                email: email,
                age: age,
                gender: gender,
                isStudent: isStudent,
                onReset: resetForm)
        }
    }
    
    func submitRegistration() {
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Full name cannot be empty."
            showAlert = true
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        
        guard age >= 18 else {
            alertMessage = "Age must be at least 18."
            showAlert = true
            return
        }
        
        let context = viewContext
        let name = fullName
        let userEmail = email
        let userAge = Int16(age)
        let userGender = gender
        let userIsStudent = isStudent
        
        Registrant.create(in: context,
                          fullName: name,
                          email: userEmail,
                          age: userAge,
                          gender: userGender,
                          isStudent: userIsStudent)
        
        navigateToConfirmation = true
    }
    
    func resetForm() {
        fullName = ""
        email = ""
        age = 18
        gender = "Prefer not to say"
        isStudent = false
    }
}

// MARK: - Confirmation View

struct ConfirmationView: View {
    var fullName: String
    var email: String
    var age: Int
    var gender: String
    var isStudent: Bool
    var onReset: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Thank you for registering!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We're excited to have you!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(icon: "person.fill", label: "Name", value: fullName)
                DetailRow(icon: "envelope.fill", label: "Email", value: email)
                DetailRow(icon: "calendar", label: "Age", value: "\(age)")
                DetailRow(icon: "person.2.fill", label: "Gender", value: gender)
                DetailRow(icon: "graduationcap.fill", label: "Student", value: isStudent ? "Yes" : "No")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
            
            Button(action: {
                onReset()
                dismiss()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Register Another")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label + ":")
                .fontWeight(.medium)
            
            Text(value)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Registrant List View

struct RegistrantListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Registrant.fullname, ascending: true)],
        animation: .default)
    private var registrants: FetchedResults<Registrant>
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        List {
            ForEach(registrants) { registrant in
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(registrant.fullname ?? "Unknown")
                            .font(.headline)
                        Text(registrant.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("All Registrants")
        .toolbar {
            EditButton()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { registrants[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete registrant: \(error.localizedDescription)")
            }
        }
    }
}
