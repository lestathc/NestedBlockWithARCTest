#import "Test.h"

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
