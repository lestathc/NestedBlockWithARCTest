#import "ViewController.h"
#import "Test.h"
#import "HelloWorld2-Swift.h"

typedef void(^Block)();

@interface ViewController ()

@property (copy) Block block;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  __weak typeof(self) weakSelf = self;
  self.block = ^ {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    for (int i = 0; i < 1000; ++i) {
      //      NSLog(@"%@", [[TestSwift alloc] init]);
      [[[Test alloc] init] test];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      strongSelf.block();
    });
  };
  [[NSOperationQueue currentQueue] addOperationWithBlock:self.block];
}

@end
