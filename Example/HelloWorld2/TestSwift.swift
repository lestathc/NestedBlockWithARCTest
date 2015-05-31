import UIKit

@objc class TestSwift: NSObject {

  var value = 0
  var holdBlock1: (() -> ())?
  var holdBlock2: (() -> ())?

  override init() {
    super.init()
    var localBlock: (() -> ())?
    self.holdBlock1 = {
      [weak self] in
      if let strongSelf = self {
        strongSelf.value = 1 // no memory leak
        strongSelf.holdBlock2 = {
          [weak strongSelf] in // Ref#1
          strongSelf?.value = 3 // with Ref#1, no memory leak; without Ref#1, memory leak (without cycle reference in Instruments)!!!
        }
        localBlock = {
          [weak strongSelf] in // Ref#2
          strongSelf?.value = 3 // with Ref#2, no memory leak; without Ref#2, memory leak (without cycle reference in Instruments), no need assign it back to self!!!
        }
        localBlock!()
        let innerLocalBlock = {
          strongSelf.value = 4 // no memory leak
        }
        innerLocalBlock()
        strongSelf.holdBlock2!()
      }
      return
    }
    self.holdBlock1!()
    return
  }

}
