import Ignite

/// This is a workaround to center when the number of elements is less than `columns`
struct CenterAlignedGrid<Data: Sequence, Content: HTML>: HTML {
  private let data: Data
  private let columns: Int
  private let content: (Data.Element) -> Content

  var body: some HTML {
    let splittedItems = data.map { $0 }.splitBy(subSize: columns)
    ForEach(splittedItems) { items in
      Grid {
        ForEach(items) { item in
          content(item)
        }
      }
      .columns(items.count)
      .horizontalAlignment(.center)
    }
  }

  init(_ data: Data, columns: Int, @HTMLBuilder content: @escaping (Data.Element) -> Content) {
    self.data = data
    self.columns = columns
    self.content = content
  }
}

extension Array {
  fileprivate func splitBy(subSize: Int) -> [[Element]] {
    return stride(from: .zero, to: self.count, by: subSize).map { startIndex in
      let endIndex = Swift.min(startIndex.advanced(by: subSize), self.count)
      return Array(self[startIndex..<endIndex])
    }
  }
}
