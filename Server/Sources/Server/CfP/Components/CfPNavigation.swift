import Elementary
import SharedModels

struct CfPNavigation: HTML, Sendable {
  let user: UserDTO?

  var body: some HTML {
    nav(
      .class("navbar navbar-expand-lg navbar-dark fixed-top"),
      .style("background: rgba(0, 32, 63, 0.95);")
    ) {
      div(.class("container")) {
        a(.class("navbar-brand fw-bold text-white"), .href("/cfp/")) { "try! Swift Tokyo CfP" }

        button(
          .class("navbar-toggler"),
          .type(.button),
          .data("bs-toggle", value: "collapse"),
          .data("bs-target", value: "#navbarNav")
        ) {
          span(.class("navbar-toggler-icon")) {}
        }

        div(.class("collapse navbar-collapse"), .id("navbarNav")) {
          ul(.class("navbar-nav ms-auto align-items-center")) {
            li(.class("nav-item")) {
              a(.class("nav-link text-white"), .href("/cfp/")) { "Home" }
            }
            li(.class("nav-item")) {
              a(.class("nav-link text-white"), .href("/cfp/guidelines")) { "Guidelines" }
            }
            li(.class("nav-item")) {
              a(.class("nav-link text-white"), .href("/cfp/submit")) { "Submit" }
            }

            if let user {
              li(.class("nav-item")) {
                a(.class("nav-link text-white"), .href("/cfp/my-proposals")) { "My Proposals" }
              }
              li(.class("nav-item")) {
                span(.class("nav-link text-white fw-bold")) {
                  HTMLText("👤 \(user.username)")
                }
              }
              li(.class("nav-item ms-2")) {
                a(.class("btn btn-sm btn-danger"), .href("/cfp/logout")) { "Sign Out" }
              }
            } else {
              li(.class("nav-item ms-2")) {
                a(.class("btn btn-sm btn-light"), .href("/api/v1/auth/github")) {
                  "Login with GitHub"
                }
              }
            }
          }
        }
      }
    }
  }
}
