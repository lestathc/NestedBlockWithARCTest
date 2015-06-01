# NestedBlockWithARCTest

There are too many articles or questions about the memory managment about block in ARC, like

http://amattn.com/p/objective_c_blocks_summary_syntax_best_practices.html
http://stackoverflow.com/questions/16526499/what-are-the-best-practices-to-avoid-leaks-when-using-objective-c-blocks
http://stackoverflow.com/questions/10431110/nested-blocks-and-references-to-self

I'd like to use follow lib to make it simple,
https://github.com/jspahrsummers/libextobjc/blob/master/extobjc/EXTScope.h
but whether I need pair the strongify and weakify for each block, I have no clear clue. Discuss with it.
http://stackoverflow.com/questions/28305356/ios-proper-use-of-weakifyself-and-strongifyself

So, I write some simple code to test it. The conclustion is, it is good to pair self for each block call.

## Objective C
```objective-c
typedef void(^Block)();

@interface Test()

@property (assign) int value;

@property (copy) Block holdBlock1;
@property (copy) Block holdBlock2;
@property (copy) Block holdBlock3;
@property (copy) Block holdBlock4;

@end

@implementation Test

- (void)test {
  __block Block localBlock;
  __weak typeof(self) weakSelf = self;
  self.holdBlock1 = ^ {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    strongSelf.value = 1; // no memory leak
    strongSelf.holdBlock2 = ^ {
      strongSelf.value = 2; // memory leak, compiler warning
      weakSelf.value = 2; // no memory leak
    };
    weakSelf.holdBlock3 = ^ {
      strongSelf.value = 3; // memory leak, no compiler warning
      weakSelf.value = 3; // is it leak? I think no leak
    };
    localBlock = ^ {
      strongSelf.value = 4; // currently, no leak. Ref#1
    };
    localBlock();
    strongSelf.holdBlock2();
  };
  self.holdBlock1();
  NSLog(@"%d", self.value);
  self.holdBlock4 = localBlock; // memory leak, due to Ref#1.
  self.holdBlock4();
  NSLog(@"%d", self.value);
}

@end

```

##Swift
```swift
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
```
