/// Localized strings for Scholarship pages
enum ScholarshipStrings {
  // MARK: - Navigation
  enum Navigation {
    static func scholarship(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Scholarship"
      case .ja: return "奨学金"
      }
    }
  }

  // MARK: - Info Page
  enum Info {
    static func title(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Student Scholarship"
      case .ja: return "学生スカラシップ"
      }
    }

    static func subtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "The try! Swift Tokyo Student Scholarship program supports students who are passionate about Swift development. We provide financial assistance for conference tickets, travel, and accommodation."
      case .ja:
        return
          "try! Swift Tokyo 学生スカラシッププログラムは、Swift開発に情熱を持つ学生を支援します。カンファレンスチケット、旅費、宿泊費の経済的支援を提供します。"
      }
    }

    static func applyNow(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Apply Now"
      case .ja: return "申請する"
      }
    }

    static func budgetRemaining(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Remaining Budget"
      case .ja: return "予算残高"
      }
    }

    static func budgetNotSet(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Budget not yet set"
      case .ja: return "予算未設定"
      }
    }

    static func eligibilityTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Eligibility"
      case .ja: return "応募資格"
      }
    }

    static func eligibilityItem1(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Currently enrolled as a full-time student at an accredited institution"
      case .ja: return "認定教育機関にフルタイムの学生として在籍していること"
      }
    }

    static func eligibilityItem2(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Studying computer science, software engineering, or a related field"
      case .ja: return "コンピュータサイエンス、ソフトウェアエンジニアリング、または関連分野を専攻していること"
      }
    }

    static func eligibilityItem3(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Demonstrate interest in Swift or Apple platform development"
      case .ja: return "SwiftまたはAppleプラットフォーム開発への関心を示すこと"
      }
    }

    static func eligibilityItem4(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Able to attend the full conference (April 12-14, 2026)"
      case .ja: return "カンファレンス全日程（2026年4月12日〜14日）に参加可能であること"
      }
    }

    static func whatsIncludedTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "What's Included"
      case .ja: return "支援内容"
      }
    }

    static func whatsIncludedItem1(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Free conference ticket"
      case .ja: return "カンファレンスチケット無料"
      }
    }

    static func whatsIncludedItem2(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Travel expense support (up to approved amount)"
      case .ja: return "旅費支援（承認額まで）"
      }
    }

    static func whatsIncludedItem3(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Accommodation support (up to approved amount)"
      case .ja: return "宿泊費支援（承認額まで）"
      }
    }

    static func whatsIncludedItem4(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Networking opportunities with industry professionals"
      case .ja: return "業界のプロフェッショナルとのネットワーキング機会"
      }
    }
  }

  // MARK: - Apply Page
  enum Apply {
    static func title(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Scholarship Application"
      case .ja: return "スカラシップ申請"
      }
    }

    static func subtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return "Complete the form below to apply for the try! Swift Tokyo Student Scholarship."
      case .ja: return "以下のフォームに記入して、try! Swift Tokyo 学生スカラシップに申請してください。"
      }
    }

    // MARK: Section Headers

    static func sectionPersonalInfo(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Personal Information"
      case .ja: return "個人情報"
      }
    }

    static func sectionBackground(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Background"
      case .ja: return "バックグラウンド"
      }
    }

    static func sectionPurpose(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Purpose of Attendance"
      case .ja: return "参加目的"
      }
    }

    static func sectionTicketInfo(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Ticket Information"
      case .ja: return "チケット情報"
      }
    }

    static func sectionTravelDetails(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Travel Details"
      case .ja: return "旅費詳細"
      }
    }

    static func sectionAccommodation(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Accommodation Details"
      case .ja: return "宿泊詳細"
      }
    }

    static func sectionAgreements(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Agreements"
      case .ja: return "同意事項"
      }
    }

    // MARK: Personal Information Fields

    static func fieldFullNameLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Full Name *"
      case .ja: return "氏名 *"
      }
    }

    static func fieldFullNamePlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Enter your full name"
      case .ja: return "氏名を入力"
      }
    }

    static func fieldEmailLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Email Address *"
      case .ja: return "メールアドレス *"
      }
    }

    static func fieldEmailPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Enter your email address"
      case .ja: return "メールアドレスを入力"
      }
    }

    static func fieldDateOfBirthLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Date of Birth *"
      case .ja: return "生年月日 *"
      }
    }

    static func fieldDateOfBirthPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "YYYY-MM-DD"
      case .ja: return "YYYY-MM-DD"
      }
    }

    static func fieldCountryLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Country of Residence *"
      case .ja: return "居住国 *"
      }
    }

    static func fieldCountryPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Enter your country of residence"
      case .ja: return "居住国を入力"
      }
    }

    // MARK: Background Fields

    static func fieldSchoolNameLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "School / University Name *"
      case .ja: return "学校名 / 大学名 *"
      }
    }

    static func fieldSchoolNamePlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Enter your school or university name"
      case .ja: return "学校名または大学名を入力"
      }
    }

    static func fieldFieldOfStudyLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Field of Study *"
      case .ja: return "専攻分野 *"
      }
    }

    static func fieldFieldOfStudyPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "e.g., Computer Science, Software Engineering"
      case .ja: return "例：コンピュータサイエンス、ソフトウェアエンジニアリング"
      }
    }

    static func fieldYearOfStudyLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Year of Study *"
      case .ja: return "学年 *"
      }
    }

    static func fieldYearOfStudyPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "e.g., 2nd year undergraduate, 1st year master's"
      case .ja: return "例：学部2年、修士1年"
      }
    }

    static func fieldExpectedGraduationLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Expected Graduation Date *"
      case .ja: return "卒業予定日 *"
      }
    }

    static func fieldExpectedGraduationPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "YYYY-MM"
      case .ja: return "YYYY-MM"
      }
    }

    static func fieldStudentIdUrlLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Student ID or Enrollment Proof URL"
      case .ja: return "学生証または在学証明書URL"
      }
    }

    static func fieldStudentIdUrlPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "URL to your student ID or enrollment verification"
      case .ja: return "学生証または在学証明書のURL"
      }
    }

    // MARK: Purpose of Attendance Fields

    static func fieldMotivationLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Why do you want to attend try! Swift Tokyo? *"
      case .ja: return "try! Swift Tokyoに参加したい理由 *"
      }
    }

    static func fieldMotivationPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return "Tell us why you want to attend and what you hope to gain from the conference"
      case .ja: return "参加したい理由と、カンファレンスから得たいことを教えてください"
      }
    }

    static func fieldSwiftExperienceLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Swift / iOS Development Experience *"
      case .ja: return "Swift / iOS開発経験 *"
      }
    }

    static func fieldSwiftExperiencePlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Describe your experience with Swift or iOS development, including any projects or contributions"
      case .ja: return "SwiftまたはiOS開発の経験を、プロジェクトやコントリビューションを含めて説明してください"
      }
    }

    // MARK: Ticket Information Fields

    static func fieldNeedsTicketLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Do you need a conference ticket? *"
      case .ja: return "カンファレンスチケットは必要ですか？ *"
      }
    }

    static func fieldNeedsTicketYes(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Yes, I need a ticket"
      case .ja: return "はい、チケットが必要です"
      }
    }

    static func fieldNeedsTicketNo(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "No, I already have a ticket"
      case .ja: return "いいえ、既にチケットを持っています"
      }
    }

    // MARK: Travel Details Fields

    static func fieldNeedsTravelSupportLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Do you need travel support? *"
      case .ja: return "旅費支援は必要ですか？ *"
      }
    }

    static func fieldNeedsTravelSupportYes(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Yes, I need travel support"
      case .ja: return "はい、旅費支援が必要です"
      }
    }

    static func fieldNeedsTravelSupportNo(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "No, I can cover my own travel"
      case .ja: return "いいえ、旅費は自己負担できます"
      }
    }

    static func fieldDepartingFromLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Departing From *"
      case .ja: return "出発地 *"
      }
    }

    static func fieldDepartingFromPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "City and country you will travel from"
      case .ja: return "出発する都市と国"
      }
    }

    static func fieldEstimatedTravelCostLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated Travel Cost (JPY) *"
      case .ja: return "旅費見積もり（円） *"
      }
    }

    static func fieldEstimatedTravelCostPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated round-trip travel cost in Japanese Yen"
      case .ja: return "往復旅費の見積もり（日本円）"
      }
    }

    // MARK: Accommodation Details Fields

    static func fieldNeedsAccommodationLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Do you need accommodation support? *"
      case .ja: return "宿泊支援は必要ですか？ *"
      }
    }

    static func fieldNeedsAccommodationYes(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Yes, I need accommodation support"
      case .ja: return "はい、宿泊支援が必要です"
      }
    }

    static func fieldNeedsAccommodationNo(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "No, I can arrange my own accommodation"
      case .ja: return "いいえ、宿泊は自己手配できます"
      }
    }

    static func fieldNumberOfNightsLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Number of Nights *"
      case .ja: return "宿泊数 *"
      }
    }

    static func fieldNumberOfNightsPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Number of nights you need accommodation"
      case .ja: return "宿泊が必要な泊数"
      }
    }

    static func fieldEstimatedAccommodationCostLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated Accommodation Cost (JPY) *"
      case .ja: return "宿泊費見積もり（円） *"
      }
    }

    static func fieldEstimatedAccommodationCostPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated total accommodation cost in Japanese Yen"
      case .ja: return "宿泊費の合計見積もり（日本円）"
      }
    }

    // MARK: Agreements Fields

    static func fieldAgreeCodeOfConductLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "I agree to abide by the try! Swift Code of Conduct *"
      case .ja: return "try! Swift行動規範を遵守することに同意します *"
      }
    }

    static func fieldAgreeTermsLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "I confirm that the information provided is accurate and I am currently enrolled as a student *"
      case .ja: return "提供する情報が正確であり、現在学生として在籍していることを確認します *"
      }
    }

    static func fieldAgreePhotoLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "I agree to be photographed and featured in conference materials (optional)"
      case .ja: return "カンファレンス資料への写真掲載に同意します（任意）"
      }
    }

    // MARK: Validation Errors

    static func errorFullNameRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Full name is required"
      case .ja: return "氏名は必須です"
      }
    }

    static func errorEmailRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Email address is required"
      case .ja: return "メールアドレスは必須です"
      }
    }

    static func errorEmailInvalid(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please enter a valid email address"
      case .ja: return "有効なメールアドレスを入力してください"
      }
    }

    static func errorDateOfBirthRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Date of birth is required"
      case .ja: return "生年月日は必須です"
      }
    }

    static func errorCountryRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Country of residence is required"
      case .ja: return "居住国は必須です"
      }
    }

    static func errorSchoolNameRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "School or university name is required"
      case .ja: return "学校名または大学名は必須です"
      }
    }

    static func errorFieldOfStudyRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Field of study is required"
      case .ja: return "専攻分野は必須です"
      }
    }

    static func errorYearOfStudyRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Year of study is required"
      case .ja: return "学年は必須です"
      }
    }

    static func errorExpectedGraduationRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Expected graduation date is required"
      case .ja: return "卒業予定日は必須です"
      }
    }

    static func errorMotivationRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please tell us why you want to attend"
      case .ja: return "参加したい理由を記入してください"
      }
    }

    static func errorSwiftExperienceRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please describe your Swift development experience"
      case .ja: return "Swift開発経験を記入してください"
      }
    }

    static func errorNeedsTicketRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please indicate if you need a conference ticket"
      case .ja: return "カンファレンスチケットの要否を選択してください"
      }
    }

    static func errorDepartingFromRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Departure location is required when requesting travel support"
      case .ja: return "旅費支援を申請する場合、出発地は必須です"
      }
    }

    static func errorEstimatedTravelCostRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated travel cost is required when requesting travel support"
      case .ja: return "旅費支援を申請する場合、旅費見積もりは必須です"
      }
    }

    static func errorEstimatedTravelCostInvalid(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please enter a valid travel cost amount"
      case .ja: return "有効な旅費金額を入力してください"
      }
    }

    static func errorNumberOfNightsRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Number of nights is required when requesting accommodation support"
      case .ja: return "宿泊支援を申請する場合、宿泊数は必須です"
      }
    }

    static func errorNumberOfNightsInvalid(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please enter a valid number of nights"
      case .ja: return "有効な宿泊数を入力してください"
      }
    }

    static func errorEstimatedAccommodationCostRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated accommodation cost is required when requesting accommodation support"
      case .ja: return "宿泊支援を申請する場合、宿泊費見積もりは必須です"
      }
    }

    static func errorEstimatedAccommodationCostInvalid(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please enter a valid accommodation cost amount"
      case .ja: return "有効な宿泊費金額を入力してください"
      }
    }

    static func errorAgreeCodeOfConductRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "You must agree to the Code of Conduct"
      case .ja: return "行動規範への同意は必須です"
      }
    }

    static func errorAgreeTermsRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "You must confirm that your information is accurate"
      case .ja: return "情報が正確であることの確認は必須です"
      }
    }

    // MARK: Educational Domain Warning

    static func educationalDomainWarning(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "We recommend using your educational institution email address (.edu, .ac.jp, etc.) for faster verification."
      case .ja:
        return "迅速な確認のため、教育機関のメールアドレス（.edu、.ac.jpなど）の使用を推奨します。"
      }
    }

    // MARK: Submit

    static func submitApplication(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit Application"
      case .ja: return "申請を送信"
      }
    }

    static func applicationSubmitted(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Application Submitted!"
      case .ja: return "申請完了！"
      }
    }

    static func applicationSubmittedDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Your scholarship application has been submitted successfully. We will review your application and notify you of the result."
      case .ja: return "スカラシップ申請が正常に送信されました。申請内容を審査し、結果をお知らせします。"
      }
    }

    static func applicationError(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Failed to submit application. Please try again."
      case .ja: return "申請の送信に失敗しました。もう一度お試しください。"
      }
    }

    static func signInRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign In Required"
      case .ja: return "ログインが必要です"
      }
    }

    static func signInDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return "Connect your GitHub account to submit a scholarship application."
      case .ja: return "GitHubアカウントを連携して、スカラシップ申請を送信しましょう。"
      }
    }

    static func signInWithGitHub(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign in with GitHub"
      case .ja: return "GitHubでログイン"
      }
    }
  }

  // MARK: - My Application Page
  enum MyApplication {
    static func title(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "My Scholarship Application"
      case .ja: return "マイスカラシップ申請"
      }
    }

    static func subtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "View and manage your scholarship application."
      case .ja: return "スカラシップ申請の確認と管理。"
      }
    }

    static func statusPending(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Pending Review"
      case .ja: return "審査中"
      }
    }

    static func statusApproved(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Approved"
      case .ja: return "承認済み"
      }
    }

    static func statusRejected(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Rejected"
      case .ja: return "不承認"
      }
    }

    static func statusWithdrawn(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Withdrawn"
      case .ja: return "取り下げ済み"
      }
    }

    static func withdrawApplication(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Withdraw Application"
      case .ja: return "申請を取り下げる"
      }
    }

    static func withdrawConfirmation(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Are you sure you want to withdraw your scholarship application? This action cannot be undone."
      case .ja: return "スカラシップ申請を取り下げてもよろしいですか？この操作は元に戻せません。"
      }
    }

    static func noApplicationYet(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "No application yet"
      case .ja: return "まだ申請がありません"
      }
    }

    static func noApplicationDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "You haven't submitted a scholarship application yet."
      case .ja: return "まだスカラシップ申請を送信していません。"
      }
    }

    static func applyForScholarship(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Apply for Scholarship"
      case .ja: return "スカラシップに申請する"
      }
    }

    static func signInRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign In Required"
      case .ja: return "ログインが必要です"
      }
    }

    static func signInDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please sign in to view your scholarship application."
      case .ja: return "スカラシップ申請を確認するにはログインしてください。"
      }
    }

    static func submittedAt(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submitted"
      case .ja: return "申請日"
      }
    }

    static func lastUpdated(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Last Updated"
      case .ja: return "最終更新"
      }
    }
  }

  // MARK: - Organizer Pages
  enum Organizer {
    static func allApplicationsTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "All Scholarship Applications"
      case .ja: return "全スカラシップ申請"
      }
    }

    static func allApplicationsSubtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Review and manage all scholarship applications."
      case .ja: return "全スカラシップ申請の確認と管理。"
      }
    }

    static func totalApplications(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Total Applications"
      case .ja: return "申請総数"
      }
    }

    static func pendingApplications(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Pending"
      case .ja: return "審査待ち"
      }
    }

    static func approvedApplications(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Approved"
      case .ja: return "承認済み"
      }
    }

    static func rejectedApplications(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Rejected"
      case .ja: return "不承認"
      }
    }

    static func applicantName(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Applicant Name"
      case .ja: return "申請者名"
      }
    }

    static func email(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Email"
      case .ja: return "メールアドレス"
      }
    }

    static func school(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "School"
      case .ja: return "学校名"
      }
    }

    static func fieldOfStudy(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Field of Study"
      case .ja: return "専攻分野"
      }
    }

    static func yearOfStudy(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Year of Study"
      case .ja: return "学年"
      }
    }

    static func expectedGraduation(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Expected Graduation"
      case .ja: return "卒業予定日"
      }
    }

    static func motivation(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Motivation"
      case .ja: return "参加動機"
      }
    }

    static func swiftExperience(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Swift Experience"
      case .ja: return "Swift経験"
      }
    }

    static func needsTicket(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Needs Ticket"
      case .ja: return "チケット要否"
      }
    }

    static func needsTravelSupport(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Needs Travel Support"
      case .ja: return "旅費支援要否"
      }
    }

    static func departingFrom(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Departing From"
      case .ja: return "出発地"
      }
    }

    static func estimatedTravelCost(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated Travel Cost"
      case .ja: return "旅費見積もり"
      }
    }

    static func needsAccommodation(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Needs Accommodation"
      case .ja: return "宿泊支援要否"
      }
    }

    static func numberOfNights(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Number of Nights"
      case .ja: return "宿泊数"
      }
    }

    static func estimatedAccommodationCost(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Estimated Accommodation Cost"
      case .ja: return "宿泊費見積もり"
      }
    }

    static func totalRequestedAmount(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Total Requested Amount"
      case .ja: return "申請合計金額"
      }
    }

    static func status(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Status"
      case .ja: return "ステータス"
      }
    }

    static func submittedDate(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submitted Date"
      case .ja: return "申請日"
      }
    }

    static func approve(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Approve"
      case .ja: return "承認"
      }
    }

    static func reject(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Reject"
      case .ja: return "不承認"
      }
    }

    static func approveConfirmation(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Are you sure you want to approve this scholarship application?"
      case .ja: return "このスカラシップ申請を承認してもよろしいですか？"
      }
    }

    static func rejectConfirmation(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Are you sure you want to reject this scholarship application?"
      case .ja: return "このスカラシップ申請を不承認にしてもよろしいですか？"
      }
    }

    static func reviewNotes(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Review Notes"
      case .ja: return "審査メモ"
      }
    }

    static func reviewNotesPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Add notes about this application (visible to organizers only)"
      case .ja: return "この申請に関するメモを追加（運営者のみに表示）"
      }
    }

    static func approvedAmount(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Approved Amount (JPY)"
      case .ja: return "承認金額（円）"
      }
    }

    static func approvedAmountPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Enter the approved scholarship amount"
      case .ja: return "承認するスカラシップ金額を入力"
      }
    }

    static func viewDetail(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "View Detail"
      case .ja: return "詳細を見る"
      }
    }

    static func backToList(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Back to List"
      case .ja: return "一覧に戻る"
      }
    }

    static func yes(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Yes"
      case .ja: return "はい"
      }
    }

    static func no(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "No"
      case .ja: return "いいえ"
      }
    }

    // MARK: Budget Management

    static func budgetManagement(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Budget Management"
      case .ja: return "予算管理"
      }
    }

    static func totalBudget(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Total Budget (JPY)"
      case .ja: return "総予算（円）"
      }
    }

    static func totalBudgetPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Enter total scholarship budget"
      case .ja: return "スカラシップ総予算を入力"
      }
    }

    static func allocatedBudget(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Allocated Budget"
      case .ja: return "配分済み予算"
      }
    }

    static func remainingBudget(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Remaining Budget"
      case .ja: return "残り予算"
      }
    }

    static func updateBudget(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Update Budget"
      case .ja: return "予算を更新"
      }
    }

    static func budgetUpdated(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Budget updated successfully."
      case .ja: return "予算が正常に更新されました。"
      }
    }

    static func budgetUpdateError(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Failed to update budget. Please try again."
      case .ja: return "予算の更新に失敗しました。もう一度お試しください。"
      }
    }

    static func filterAll(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "All"
      case .ja: return "すべて"
      }
    }

    static func filterPending(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Pending"
      case .ja: return "審査待ち"
      }
    }

    static func filterApproved(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Approved"
      case .ja: return "承認済み"
      }
    }

    static func filterRejected(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Rejected"
      case .ja: return "不承認"
      }
    }

    static func noApplicationsFound(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "No scholarship applications found."
      case .ja: return "スカラシップ申請が見つかりません。"
      }
    }
  }
}
