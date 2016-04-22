//
//  DemoContainerViewController.m
//  Container Transitions
//
//  Created by zzzworm on 16/4/22.
//
//

#import "DemoContainerViewController.h"
#include "ContainerViewController.h"

static CGFloat const kButtonSlotWidth = 64; // Also distance between button centers
static CGFloat const kButtonSlotHeight = 44;

@interface DemoContainerViewController () <ContainerViewControllerDelegate>

@property (nonatomic, strong) UIView *privateButtonsView; /// The view hosting the buttons of the child view controllers.


@end

@implementation DemoContainerViewController


- (void)loadView {
    
    // Add  container and buttons views.
    self.view = [[UIView alloc] init];
    self.containerView = [[UIView alloc] init];
    [self.view addSubview:self.containerView];
//    self.containerView = self.view;
    [self.containerView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [super loadView];
    
    self.privateButtonsView = [[UIView alloc] init];
    self.privateButtonsView.backgroundColor = [UIColor clearColor];
    self.privateButtonsView.tintColor = [UIColor colorWithWhite:1 alpha:0.75f];
    [self.privateButtonsView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.privateButtonsView];
    
    [self _addChildViewControllerButtons];
    

}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    // Place buttons view in the top half, horizontally centered.
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.privateButtonsView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:[self.viewControllers count] * kButtonSlotWidth]];
    
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.privateButtonsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kButtonSlotHeight]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.privateButtonsView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.privateButtonsView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:0.4f constant:0]];
    
    
    //containerView
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:320]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:250]];
    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
//    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];

}

- (void)_addChildViewControllerButtons {
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *childViewController, NSUInteger idx, BOOL *stop) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *icon = [childViewController.tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button setImage:icon forState:UIControlStateNormal];
        UIImage *selectedIcon = [childViewController.tabBarItem.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [button setImage:selectedIcon forState:UIControlStateSelected];
        
        button.tag = idx;
        [button addTarget:self action:@selector(_buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.privateButtonsView addSubview:button];
        [button setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.privateButtonsView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.privateButtonsView attribute:NSLayoutAttributeLeading multiplier:1 constant:(idx + 0.5f) * kButtonSlotWidth]];
        [self.privateButtonsView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.privateButtonsView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)_buttonTapped:(UIButton *)button {
    UIViewController *selectedViewController = self.viewControllers[button.tag];
    self.selectedViewController = selectedViewController;
    
    if ([self.delegate respondsToSelector:@selector (containerViewController:didSelectViewController:)]) {
        [self.delegate containerViewController:self didSelectViewController:selectedViewController];
    }
}

- (void)_updateButtonSelection {
    [self.privateButtonsView.subviews enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        button.selected = (self.viewControllers[idx] == self.selectedViewController);
    }];
}

#pragma mark - ContainerViewControllDelegate

- (void)finishTransitionToChildViewController:(UIViewController *)toViewController
{
    [self _updateButtonSelection];
}

- (void)endTransitionToChildViewController:(UIViewController *)toViewController
{
    self.privateButtonsView.userInteractionEnabled = YES;
}

- (void)startTransitionToChildViewController:(UIViewController *)toViewController
{
    self.privateButtonsView.userInteractionEnabled = NO; // Prevent user tapping buttons mid-transition, messing up state
}
@end
