import Ignite

struct CfPLayout: Layout {
  var body: some Document {
    Head {
      Title("try! Swift Tokyo CfP")
    }

    Body {
      CfPNavigation()
      
      content
      
      CfPFooter()
    }
  }
}
