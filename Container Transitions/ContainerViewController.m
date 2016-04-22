//
//  ContainerViewController.m
//  Container Transitions
//
//  Created by Joachim Bondo on 30/04/2014.
//
//  Interactive transition support added by Alek Åström on 11/05/2014.
//

#import "ContainerViewController.h"
#import "PanGestureInteractiveTransition.h"


/** A private UIViewControllerContextTransitioning class to be provided transitioning delegates.
 @discussion Because we are a custom UIVievController class, with our own containment implementation, we have to provide an object conforming to the UIViewControllerContextTransitioning protocol. The system view controllers use one provided by the framework, which we cannot configure, let alone create. This class will be used even if the developer provides their own transitioning objects.
 @note The only methods that will be called on objects of this class are the ones defined in the UIViewControllerContextTransitioning protocol. The rest is our own private implementation.
 */
@interface PrivateTransitionContext : NSObject <UIViewControllerContextTransitioning>
- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController goingRight:(BOOL)goingRight; /// Designated initializer.
@property (nonatomic, copy) void (^completionBlock)(BOOL didComplete); /// A block of code we can set to execute after having received the completeTransition: message.
@property (nonatomic, assign, getter=isAnimated) BOOL animated; /// Private setter for the animated property.
@property (nonatomic, assign, getter=isInteractive) BOOL interactive; /// Private setter for the interactive property.
@end

/// Instances of this private class perform the default transition animation which is to slide child views horizontally.
@interface PrivateAnimatedTransition : NSObject <UIViewControllerAnimatedTransitioning>
@end

#pragma mark -

@interface ContainerViewController ()
@property (nonatomic, copy, readwrite) NSArray *viewControllers;

@property (nonatomic, strong) UIView *privateContainerView; /// The view hosting the child view controllers views.
@property (nonatomic, strong) PanGestureInteractiveTransition *defaultInteractionController; /// The default, pan gesture enabled interactive transition controller.

@end

@implementation ContainerViewController

- (instancetype)initWithViewControllers:(NSArray *)viewControllers {
	NSParameterAssert ([viewControllers count] > 0);
	if ((self = [super init])) {
		self.viewControllers = [viewControllers copy];
	}
	return self;
}

- (void)loadView {
	
	// Add  container and buttons views.
	
    UIView *rootView = self.containerView ? : self.view;
	rootView.backgroundColor = [UIColor blackColor];
	rootView.opaque = YES;
	
	self.privateContainerView = [[UIView alloc] init];
	self.privateContainerView.backgroundColor = [UIColor blackColor];
	self.privateContainerView.opaque = YES;
	
		
	[self.privateContainerView setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	[rootView addSubview:self.privateContainerView];

    
    // Add gesture recognizer and setup for interactive transition
    __weak typeof(self) wself = self;
    self.defaultInteractionController = [[PanGestureInteractiveTransition alloc] initWithGestureRecognizerInView:self.privateContainerView recognizedBlock:^(UIPanGestureRecognizer *recognizer) {
        BOOL leftToRight = [recognizer velocityInView:recognizer.view].x > 0;
        
        NSUInteger currentVCIndex = [self.viewControllers indexOfObject:self.selectedViewController];
        if (!leftToRight && currentVCIndex != self.viewControllers.count-1) {
            [wself setSelectedViewController:self.viewControllers[currentVCIndex+1]];
        } else if (leftToRight && currentVCIndex > 0) {
            [wself setSelectedViewController:self.viewControllers[currentVCIndex-1]];
        }
    }];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    // Container view fills out entire root view.
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.privateContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.privateContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.privateContainerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.privateContainerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
    
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.selectedViewController = (self.selectedViewController ?: self.viewControllers[0]);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
	return self.selectedViewController;
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController {
	NSParameterAssert (selectedViewController);
	[self _transitionToChildViewController:selectedViewController];
}

- (UIGestureRecognizer *)interactiveTransitionGestureRecognizer {
    return self.defaultInteractionController.recognizer;
}

#pragma mark Private Methods


- (void)_transitionToChildViewController:(UIViewController *)toViewController {
	
	UIViewController *fromViewController = self.selectedViewController;
	if (toViewController == fromViewController || ![self isViewLoaded]) {
		return;
	}
	
	UIView *toView = toViewController.view;
	[toView setTranslatesAutoresizingMaskIntoConstraints:YES];
	toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	toView.frame = self.privateContainerView.bounds;
	
	[fromViewController willMoveToParentViewController:nil];
	[self addChildViewController:toViewController];
	
	// If this is the initial presentation, add the new child with no animation.
	if (!fromViewController) {
		[self.privateContainerView addSubview:toViewController.view];
		[toViewController didMoveToParentViewController:self];
        [self _finishTransitionToChildViewController:toViewController];
		return;
	}
	
	// Animate the transition by calling the animator with our private transition context. If we don't have a delegate, or if it doesn't return an animated transitioning object, we will use our own, private animator.
	
	id<UIViewControllerAnimatedTransitioning>animator = nil;
	if ([self.delegate respondsToSelector:@selector (containerViewController:animationControllerForTransitionFromViewController:toViewController:)]) {
		animator = [self.delegate containerViewController:self animationControllerForTransitionFromViewController:fromViewController toViewController:toViewController];
	}
    BOOL animatorIsDefault = (animator == nil);
	animator = (animator ?: [[PrivateAnimatedTransition alloc] init]);
	
	// Because of the nature of our view controller, with horizontally arranged buttons, we instantiate our private transition context with information about whether this is a left-to-right or right-to-left transition. The animator can use this information if it wants.
	NSUInteger fromIndex = [self.viewControllers indexOfObject:fromViewController];
	NSUInteger toIndex = [self.viewControllers indexOfObject:toViewController];
	PrivateTransitionContext *transitionContext = [[PrivateTransitionContext alloc] initWithFromViewController:fromViewController toViewController:toViewController goingRight:toIndex > fromIndex];
	
	transitionContext.animated = YES;
    
    // At the start of the transition, we need to find out if it should be interactive or not. We do this by trying to fetch an interaction controller.
    id<UIViewControllerInteractiveTransitioning> interactionController = [self _interactionControllerForAnimator:animator animatorIsDefault:animatorIsDefault];
    
	transitionContext.interactive = (interactionController != nil);
	transitionContext.completionBlock = ^(BOOL didComplete) {
        
        if (didComplete) {
            [fromViewController.view removeFromSuperview];
            [fromViewController removeFromParentViewController];
            [toViewController didMoveToParentViewController:self];
            [self _finishTransitionToChildViewController:toViewController];
            
        } else {
            [toViewController.view removeFromSuperview];
        }
        
        if ([animator respondsToSelector:@selector (animationEnded:)]) {
            [animator animationEnded:didComplete];
        }
        if ([self.delegate respondsToSelector:@selector(endTransitionToChildViewController:)]) {
            [self.delegate endTransitionToChildViewController:toViewController];
        }

	};
    if ([self.delegate respondsToSelector:@selector(startTransitionToChildViewController:)]) {
        [self.delegate startTransitionToChildViewController:toViewController];
    }

    if ([transitionContext isInteractive]) {
        [interactionController startInteractiveTransition:transitionContext];
    } else {
        [animator animateTransition:transitionContext];
        [self _finishTransitionToChildViewController:toViewController];
    }
}

- (void)_finishTransitionToChildViewController:(UIViewController *)toViewController {
    _selectedViewController = toViewController;
    if ([self.delegate respondsToSelector:@selector(finishTransitionToChildViewController:)]) {
        [self.delegate finishTransitionToChildViewController:toViewController];
    }
}

- (id<UIViewControllerInteractiveTransitioning>)_interactionControllerForAnimator:(id<UIViewControllerAnimatedTransitioning>)animationController animatorIsDefault:(BOOL)animatorIsDefault {
    
    if (self.defaultInteractionController.recognizer.state == UIGestureRecognizerStateBegan) {
        self.defaultInteractionController.animator = animationController;
        return self.defaultInteractionController;
    } else if (!animatorIsDefault && [self.delegate respondsToSelector:@selector(containerViewController:interactionControllerForAnimationController:)]) {
        return [self.delegate containerViewController:self interactionControllerForAnimationController:animationController];
    } else {
        return nil;
    }
}

@end

#pragma mark - Private Transitioning Classes

@interface PrivateTransitionContext ()
@property (nonatomic, strong) NSDictionary *privateViewControllers;
@property (nonatomic, assign) CGRect privateDisappearingFromRect;
@property (nonatomic, assign) CGRect privateAppearingFromRect;
@property (nonatomic, assign) CGRect privateDisappearingToRect;
@property (nonatomic, assign) CGRect privateAppearingToRect;
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, assign) UIModalPresentationStyle presentationStyle;
@property (nonatomic, assign) BOOL transitionWasCancelled;
@end

@implementation PrivateTransitionContext

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController goingRight:(BOOL)goingRight {
	NSAssert ([fromViewController isViewLoaded] && fromViewController.view.superview, @"The fromViewController view must reside in the container view upon initializing the transition context.");
	
	if ((self = [super init])) {
		self.presentationStyle = UIModalPresentationCustom;
		self.containerView = fromViewController.view.superview;
        _transitionWasCancelled = NO;
		self.privateViewControllers = @{
                                        UITransitionContextFromViewControllerKey:fromViewController,
                                        UITransitionContextToViewControllerKey:toViewController,
                                        };
        
		// Set the view frame properties which make sense in our specialized ContainerViewController context. Views appear from and disappear to the sides, corresponding to where the icon buttons are positioned. So tapping a button to the right of the currently selected, makes the view disappear to the left and the new view appear from the right. The animator object can choose to use this to determine whether the transition should be going left to right, or right to left, for example.
		CGFloat travelDistance = (goingRight ? -self.containerView.bounds.size.width : self.containerView.bounds.size.width);
		self.privateDisappearingFromRect = self.privateAppearingToRect = self.containerView.bounds;
		self.privateDisappearingToRect = CGRectOffset (self.containerView.bounds, travelDistance, 0);
		self.privateAppearingFromRect = CGRectOffset (self.containerView.bounds, -travelDistance, 0);
	}
	
	return self;
}

- (CGRect)initialFrameForViewController:(UIViewController *)viewController {
	if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
		return self.privateDisappearingFromRect;
	} else {
		return self.privateAppearingFromRect;
	}
}

- (CGRect)finalFrameForViewController:(UIViewController *)viewController {
	if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
		return self.privateDisappearingToRect;
	} else {
		return self.privateAppearingToRect;
	}
}

- (UIViewController *)viewControllerForKey:(NSString *)key {
	return self.privateViewControllers[key];
}

- (void)completeTransition:(BOOL)didComplete {
	if (self.completionBlock) {
		self.completionBlock (didComplete);
	}
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)finishInteractiveTransition {self.transitionWasCancelled = NO;}
- (void)cancelInteractiveTransition {self.transitionWasCancelled = YES;}

@end

@implementation PrivateAnimatedTransition

static CGFloat const kChildViewPadding = 0;
static CGFloat const kDamping = 1;
static CGFloat const kInitialSpringVelocity = 0.5;

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 1;
}

/// Slide views horizontally, with a bit of space between, while fading out and in.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	
	UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	
	// When sliding the views horizontally in and out, figure out whether we are going left or right.
	BOOL goingRight = ([transitionContext initialFrameForViewController:toViewController].origin.x < [transitionContext finalFrameForViewController:toViewController].origin.x);
	CGFloat travelDistance = [transitionContext containerView].bounds.size.width + kChildViewPadding;
	CGAffineTransform travel = CGAffineTransformMakeTranslation (goingRight ? travelDistance : -travelDistance, 0);
	
	[[transitionContext containerView] addSubview:toViewController.view];
//	toViewController.view.alpha = 0;
	toViewController.view.transform = CGAffineTransformInvert (travel);
	
	[UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:kDamping initialSpringVelocity:kInitialSpringVelocity options:UIViewAnimationOptionCurveLinear animations:^{
		fromViewController.view.transform = travel;
//		fromViewController.view.alpha = 0;
		toViewController.view.transform = CGAffineTransformIdentity;
//		toViewController.view.alpha = 1;
	} completion:^(BOOL finished) {
		fromViewController.view.transform = CGAffineTransformIdentity;
//        fromViewController.view.alpha = 1;
        
		[transitionContext completeTransition:![transitionContext transitionWasCancelled]];
	}];
}

@end
