import Elementary

struct SubmitCoInstructorFields: HTML, Sendable {
  let language: AppLanguage
  let prefix: String

  var body: some HTML {
    div(.class("submit-form-full co-instructor-fields")) {
      h4 { HTMLText(language == .ja ? "共同講師" : "Co-Instructor") }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "名前" : "Name") }
        input(.type(.text), .name("\(prefix)Name"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("Email") }
        input(.type(.email), .name("\(prefix)Email"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("GitHub") }
        input(.type(.text), .name("\(prefix)GithubUsername"))
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText("Bio") }
        textarea(.name("\(prefix)Bio"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("SNS") }
        input(.type(.url), .name("\(prefix)Sns"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "アイコンURL" : "Avatar URL") }
        input(.type(.url), .name("\(prefix)IconURL"))
      }
    }
  }
}
