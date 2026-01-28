import SwiftUI
import SharedModels

/// A reusable sponsor grid component.
/// This SwiftUI code is shared between iOS and Android platforms.
public struct SponsorGridView: View {
    let sponsors: Sponsors
    let onSponsorTap: (Sponsor) -> Void

    public init(sponsors: Sponsors, onSponsorTap: @escaping (Sponsor) -> Void) {
        self.sponsors = sponsors
        self.onSponsorTap = onSponsorTap
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(Plan.allCases, id: \.self) { plan in
                    if let planSponsors = sponsors.allPlans[plan], !planSponsors.isEmpty {
                        SponsorSectionView(
                            plan: plan,
                            sponsors: planSponsors,
                            onSponsorTap: onSponsorTap
                        )
                    }
                }
            }
            .padding()
        }
    }
}

/// A section displaying sponsors for a specific plan tier.
public struct SponsorSectionView: View {
    let plan: Plan
    let sponsors: [Sponsor]
    let onSponsorTap: (Sponsor) -> Void

    public init(plan: Plan, sponsors: [Sponsor], onSponsorTap: @escaping (Sponsor) -> Void) {
        self.plan = plan
        self.sponsors = sponsors
        self.onSponsorTap = onSponsorTap
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(plan.rawValue.localizedCapitalized)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(sponsors) { sponsor in
                    SponsorCardView(sponsor: sponsor)
                        .onTapGesture {
                            onSponsorTap(sponsor)
                        }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        switch plan {
        case .platinum:
            return [GridItem(.flexible())]
        case .gold, .silver, .bronze, .diversityAndInclusion, .community, .student:
            return [GridItem(.flexible()), GridItem(.flexible())]
        case .individual:
            return [GridItem(.adaptive(minimum: 60, maximum: 100))]
        }
    }
}

/// A card displaying a single sponsor.
public struct SponsorCardView: View {
    let sponsor: Sponsor

    public init(sponsor: Sponsor) {
        self.sponsor = sponsor
    }

    public var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .aspectRatio(16/9, contentMode: .fit)
                .overlay {
                    if let name = sponsor.name {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(8)
                    }
                }
        }
    }
}

#Preview {
    SponsorGridView(
        sponsors: Sponsors(
            platinum: [Sponsor(id: 1, name: "Platinum Sponsor", imageName: "platinum")],
            gold: [
                Sponsor(id: 2, name: "Gold A", imageName: "gold_a"),
                Sponsor(id: 3, name: "Gold B", imageName: "gold_b")
            ],
            silver: [],
            bronze: [],
            diversity: [],
            student: [],
            community: [],
            individual: []
        ),
        onSponsorTap: { _ in }
    )
}
