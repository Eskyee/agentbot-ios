import SwiftUI

struct SkillsCatalogView: View {
    @State private var skills: [Skill] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    struct Skill: Identifiable, Codable {
        let id: String
        let name: String
        let description: String
        let category: String
        let author: String
        let version: String
        let isInstalled: Bool
        let downloads: Int
        let rating: Double?
    }
    
    var categories: [String] {
        Array(Set(skills.map { $0.category })).sorted()
    }
    
    var filteredSkills: [Skill] {
        skills.filter { skill in
            let matchesSearch = searchText.isEmpty || skill.name.localizedCaseInsensitiveContains(searchText) || skill.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || skill.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(title: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(title: category, isSelected: selectedCategory == category) { selectedCategory = category }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            if isLoading {
                ProgressView("Loading skills...")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredSkills) { skill in
                            SkillCard(skill: skill) {
                                toggleInstall(skill)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Skills")
        .searchable(text: $searchText, prompt: "Search skills")
        .refreshable { await loadSkills() }
        .task { await loadSkills() }
    }
    
    private func loadSkills() async {
        isLoading = true
        do {
            let data = try await AuthManager.shared.authorizedRequest(path: "/api/skills")
            skills = try JSONDecoder().decode([Skill].self, from: data)
        } catch { skills = [] }
        isLoading = false
    }
    
    private func toggleInstall(_ skill: Skill) {
        Task {
            let path = skill.isInstalled ? "/api/skills/\(skill.id)/uninstall" : "/api/skills/\(skill.id)/install"
            _ = try? await AuthManager.shared.authorizedRequest(path: path, method: "POST")
            await loadSkills()
        }
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

private struct SkillCard: View {
    let skill: SkillsCatalogView.Skill
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(skill.name).font(.headline)
                    Text(skill.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(skill.isInstalled ? "Remove" : "Install") { onToggle() }
                    .buttonStyle(.bordered)
                    .tint(skill.isInstalled ? .red : .accentColor)
            }
            Text(skill.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text(skill.author)
                Spacer()
                Text("v\(skill.version)")
                if let rating = skill.rating {
                    Text("\(rating, specifier: "%.1f")")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
