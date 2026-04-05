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
      HStack {
        Text(plan.rawValue.capitalized)
          .font(Font.title2.bold())
        Spacer()
        Text("\(sponsors.count)")
          .font(Font.caption.bold())
          .foregroundStyle(Color.secondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Color.secondary.opacity(0.12), in: Capsule())
      }

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
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)

      VStack(spacing: 10) {
        ModuleImageView(imageName: sponsor.imageName, contentMode: .fit) {
          sponsorPlaceholder
        }
        .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 72)

        if let name = sponsor.name {
          Text(name)
            .font(Font.caption.weight(.semibold))
            .foregroundStyle(Color.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
      }
      .padding(12)
    }
    .frame(maxWidth: .infinity, minHeight: 112)
  }

  private var sponsorInitials: String {
    guard let name = sponsor.name?.trimmingCharacters(in: .whitespacesAndNewlines),
      !name.isEmpty
    else {
      return String(sponsor.imageName.prefix(2)).uppercased()
    }
    let words = name.split(separator: " ")
    if words.count >= 2 {
      let first = words[0].prefix(1)
      let second = words[1].prefix(1)
      return String(first + second).uppercased()
    }
    return String(name.prefix(2)).uppercased()
  }

  private var sponsorPlaceholder: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 1.0, green: 0.61, blue: 0.35).opacity(0.18),
              Color(red: 0.92, green: 0.33, blue: 0.34).opacity(0.14),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      Text(sponsorInitials)
        .font(Font.title2.bold())
        .foregroundStyle(Color(red: 0.92, green: 0.33, blue: 0.34))
    }
  }
}
