import SharedModels
import SwiftUI

/// A reusable sponsor grid component for Android.
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
      Text(plan.rawValue.capitalized)
        .font(Font.title2.bold())
        .frame(maxWidth: CGFloat.infinity, alignment: Alignment.leading)

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
      return [GridItem(GridItem.Size.flexible())]
    case .gold, .silver, .bronze, .diversityAndInclusion, .community, .student:
      return [GridItem(GridItem.Size.flexible()), GridItem(GridItem.Size.flexible())]
    case .individual:
      return [GridItem(GridItem.Size.adaptive(minimum: 60, maximum: 100))]
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
        .aspectRatio(1.778, contentMode: ContentMode.fit)
        .overlay(alignment: Alignment.center) {
          if let name = sponsor.name {
            Text(name)
              .font(Font.caption)
              .foregroundStyle(Color.secondary)
              .multilineTextAlignment(TextAlignment.center)
              .padding(8)
          }
        }
    }
  }
}
