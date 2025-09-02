//
//  TemplateManagementView.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Enhanced template management with categories, variables, and CRUD operations
//  Hour 9.3: Enhanced template system implementation
//

import SwiftUI
import SwiftData

struct TemplateManagementView: View {
    @State private var templates: [EnhancedPromptTemplate] = []
    @State private var categories: [TemplateCategory] = []
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showFavoritesOnly = false
    @State private var sortBy: TemplateSearchQuery.SortOption = .lastModified
    @State private var isShowingEditor = false
    @State private var editingTemplate: EnhancedPromptTemplate? = nil
    @State private var isShowingCategoryManager = false
    
    var filteredTemplates: [EnhancedPromptTemplate] {
        var filtered = templates
        
        // Text search
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.content.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Favorites filter
        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // Sort results
        switch sortBy {
        case .name:
            filtered.sort { $0.name < $1.name }
        case .lastModified:
            filtered.sort { $0.lastModified > $1.lastModified }
        case .lastUsed:
            filtered.sort { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
        case .usageCount:
            filtered.sort { $0.usageCount > $1.usageCount }
        case .category:
            filtered.sort { $0.category < $1.category }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Template statistics
                templateStatsHeader
                
                // Template list
                templateList
            }
            .navigationTitle("Template Library")
            .searchable(text: $searchText, prompt: "Search \(templates.count) templates...")
            .toolbar {
                templateToolbar
            }
            .onAppear {
                loadTemplates()
                loadCategories()
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            TemplateEditorView(
                template: editingTemplate,
                categories: categories,
                onSave: { template in
                    saveTemplate(template)
                    isShowingEditor = false
                },
                onCancel: { isShowingEditor = false }
            )
        }
        .sheet(isPresented: $isShowingCategoryManager) {
            CategoryManagerView(
                categories: categories,
                onSave: { updatedCategories in
                    categories = updatedCategories
                    isShowingCategoryManager = false
                },
                onCancel: { isShowingCategoryManager = false }
            )
        }
    }
    
    // MARK: - Template Statistics Header
    
    private var templateStatsHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                TemplateStatCard(title: "Total", value: "\(templates.count)", color: .blue)
                TemplateStatCard(title: "Categories", value: "\(categories.count)", color: .green)
                TemplateStatCard(title: "Favorites", value: "\(templates.filter { $0.isFavorite }.count)", color: .orange)
                TemplateStatCard(title: "Built-in", value: "\(templates.filter { $0.isBuiltIn }.count)", color: .purple)
                
                Spacer()
            }
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Category filter
                    Menu {
                        Button("All Categories") { selectedCategory = nil }
                        Divider()
                        ForEach(categories, id: \.id) { category in
                            Button(category.name) { selectedCategory = category.name }
                        }
                    } label: {
                        FilterChip(
                            title: selectedCategory ?? "All Categories",
                            isActive: selectedCategory != nil
                        )
                    }
                    
                    // Favorites filter
                    Button(action: { showFavoritesOnly.toggle() }) {
                        FilterChip(title: "Favorites", isActive: showFavoritesOnly)
                    }
                    
                    // Sort filter
                    Menu {
                        ForEach(TemplateSearchQuery.SortOption.allCases, id: \.self) { option in
                            Button(option.rawValue) { sortBy = option }
                        }
                    } label: {
                        FilterChip(title: "Sort: \(sortBy.rawValue)", isActive: true)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.regularMaterial)
    }
    
    // MARK: - Template List
    
    private var templateList: some View {
        Group {
            if filteredTemplates.isEmpty {
                TemplateEmptyState(
                    hasTemplates: !templates.isEmpty,
                    searchText: searchText,
                    onCreateTemplate: { createNewTemplate() },
                    onClearSearch: { searchText = "" }
                )
            } else {
                List {
                    ForEach(filteredTemplates, id: \.id) { template in
                        TemplateRow(
                            template: template,
                            onTap: { useTemplate(template) },
                            onEdit: { editTemplate(template) },
                            onFavoriteToggle: { toggleTemplateFavorite(template) },
                            onDelete: { deleteTemplate(template) }
                        )
                    }
                    .onDelete(perform: deleteTemplates)
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var templateToolbar: some View {
        Group {
            Button("Categories") {
                isShowingCategoryManager = true
            }
            
            Button("New Template") {
                createNewTemplate()
            }
        }
    }
    
    // MARK: - Template Operations
    
    private func loadTemplates() {
        // In production, would load from SwiftData
        templates = generateAdvancedDefaultTemplates()
        print("[TemplateManagement] Loaded \(templates.count) templates")
    }
    
    private func loadCategories() {
        // In production, would load from SwiftData
        categories = generateDefaultTemplateCategories()
        print("[TemplateManagement] Loaded \(categories.count) categories")
    }
    
    private func createNewTemplate() {
        editingTemplate = nil
        isShowingEditor = true
    }
    
    private func editTemplate(_ template: EnhancedPromptTemplate) {
        editingTemplate = template
        isShowingEditor = true
    }
    
    private func useTemplate(_ template: EnhancedPromptTemplate) {
        // Mark as used
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].lastUsed = Date()
            templates[index].usageCount += 1
        }
        
        // In production, would navigate to prompt submission with template
        print("[TemplateManagement] Using template: \(template.name)")
    }
    
    private func toggleTemplateFavorite(_ template: EnhancedPromptTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].isFavorite.toggle()
            print("[TemplateManagement] Toggled favorite for: \(template.name)")
        }
    }
    
    private func saveTemplate(_ template: EnhancedPromptTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            print("[TemplateManagement] Updated template: \(template.name)")
        } else {
            templates.append(template)
            print("[TemplateManagement] Created new template: \(template.name)")
        }
    }
    
    private func deleteTemplate(_ template: EnhancedPromptTemplate) {
        templates.removeAll { $0.id == template.id }
        print("[TemplateManagement] Deleted template: \(template.name)")
    }
    
    private func deleteTemplates(offsets: IndexSet) {
        for index in offsets {
            deleteTemplate(filteredTemplates[index])
        }
    }
}

// MARK: - Supporting Views

struct TemplateStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isActive ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? .accentColor : .gray.opacity(0.2))
            .clipShape(Capsule())
    }
}

struct TemplateRow: View {
    let template: EnhancedPromptTemplate
    let onTap: () -> Void
    let onEdit: () -> Void
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(template.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if template.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                if template.isBuiltIn {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            // Preview content
            Text(template.previewContent)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Metadata
            HStack {
                // Category
                Text(template.category)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue)
                    .clipShape(Capsule())
                
                // Variable count
                if template.variableCount > 0 {
                    Text("\(template.variableCount) variables")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Usage count
                if template.usageCount > 0 {
                    Text("Used \(template.usageCount)x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Last modified
                Text(template.lastModified.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .swipeActions(edge: .trailing) {
            if !template.isBuiltIn {
                Button("Delete", role: .destructive) { onDelete() }
                Button("Edit") { onEdit() }
            }
        }
        .swipeActions(edge: .leading) {
            Button(template.isFavorite ? "Unfavorite" : "Favorite") { onFavoriteToggle() }
                .tint(.orange)
        }
        .contextMenu {
            TemplateContextMenu(
                template: template,
                onEdit: onEdit,
                onFavoriteToggle: onFavoriteToggle,
                onDelete: template.isBuiltIn ? nil : onDelete
            )
        }
    }
}

struct TemplateEmptyState: View {
    let hasTemplates: Bool
    let searchText: String
    let onCreateTemplate: () -> Void
    let onClearSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasTemplates ? "magnifyingglass" : "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(hasTemplates ? "No Matching Templates" : "No Templates Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(hasTemplates ?
                 "Try adjusting your search terms or filters" :
                 "Create your first template to get started"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            
            if hasTemplates && !searchText.isEmpty {
                Button("Clear Search") { onClearSearch() }
                    .buttonStyle(.bordered)
            } else if !hasTemplates {
                Button("Create Template") { onCreateTemplate() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct TemplateContextMenu: View {
    let template: EnhancedPromptTemplate
    let onEdit: () -> Void
    let onFavoriteToggle: () -> Void
    let onDelete: (() -> Void)?
    
    var body: some View {
        Group {
            Button("Use Template") {
                // Use template action
            }
            
            Button(template.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                onFavoriteToggle()
            }
            
            if !template.isBuiltIn {
                Button("Edit Template") {
                    onEdit()
                }
            }
            
            Divider()
            
            Button("Duplicate Template") {
                // Duplicate action
            }
            
            Button("Export Template") {
                // Export action  
            }
            
            if let onDelete = onDelete {
                Divider()
                Button("Delete Template", role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}

// MARK: - Template Editor View

struct TemplateEditorView: View {
    let template: EnhancedPromptTemplate?
    let categories: [TemplateCategory]
    let onSave: (EnhancedPromptTemplate) -> Void
    let onCancel: () -> Void
    
    @State private var name: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: String = "General"
    @State private var description: String = ""
    @State private var tags: String = ""
    @State private var variableValues: [String: String] = [:]
    @State private var isShowingPreview = false
    
    var isEditing: Bool { template != nil }
    var canSave: Bool { !name.isEmpty && !content.isEmpty }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Editor tabs
                Picker("Mode", selection: $isShowingPreview) {
                    Text("Edit").tag(false)
                    Text("Preview").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if isShowingPreview {
                    templatePreview
                } else {
                    templateEditor
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                loadTemplateData()
            }
        }
    }
    
    private var templateEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Basic info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Template Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.name) { category in
                            Text(category.name).tag(category.name)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Tags (comma separated)", text: $tags)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Template content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text("Use {{variable_name}} for dynamic content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Variables section
                if !extractedVariables.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Variables (\(extractedVariables.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(extractedVariables, id: \.name) { variable in
                            VariableRow(variable: variable)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var templatePreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Template Preview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(processedContent)
                    .font(.body)
                    .padding()
                    .background(.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if !extractedVariables.isEmpty {
                    Text("Variables need values for full preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private var extractedVariables: [TemplateVariable] {
        extractVariables(from: content)
    }
    
    private var processedContent: String {
        var processed = content
        
        // Replace with sample values for preview
        for variable in extractedVariables {
            let sampleValue = variableValues[variable.name] ?? "[Sample \(variable.name)]"
            processed = processed.replacingOccurrences(of: "{{\(variable.name)}}", with: sampleValue)
        }
        
        return processed
    }
    
    private func loadTemplateData() {
        if let template = template {
            name = template.name
            content = template.content
            selectedCategory = template.category
            description = template.description
            tags = template.tags.joined(separator: ", ")
        }
    }
    
    private func saveTemplate() {
        let template = template ?? EnhancedPromptTemplate(
            name: name,
            content: content,
            category: selectedCategory,
            description: description
        )
        
        template.name = name
        template.content = content
        template.category = selectedCategory
        template.description = description
        template.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        template.lastModified = Date()
        template.variables = extractVariables(from: content)
        
        onSave(template)
    }
}

struct VariableRow: View {
    let variable: TemplateVariable
    
    var body: some View {
        HStack {
            Image(systemName: variable.type.icon)
                .foregroundColor(variable.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(variable.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(variable.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if variable.isRequired {
                Text("Required")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.red)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Manager View (Placeholder)

struct CategoryManagerView: View {
    let categories: [TemplateCategory]
    let onSave: ([TemplateCategory]) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            List(categories, id: \.id) { category in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.displayColor)
                    
                    VStack(alignment: .leading) {
                        Text(category.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(category.templateCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onSave(categories) }
                }
            }
        }
    }
}

// MARK: - Preview

struct TemplateManagementView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateManagementView()
    }
}