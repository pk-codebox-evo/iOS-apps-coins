//
//  BTCValueViewController.m
//  Coins
//
//  Created by Sam Soffes on 12/20/13.
//  Copyright (c) 2013 Nothing Magical, Inc. All rights reserved.
//

#import "BTCValueViewController.h"
#import "BTCConversionProvider.h"
#import "BTCCurrencyPickerTableViewController.h"
#import "BTCNavigationController.h"

#import <SAMTextField/SAMTextField.h>
#import <SAMGradientView/SAMGradientView.h>
#import <SAMCategories/NSDate+SAMAdditions.h>
#import "UIImage+Vector.h"

@interface BTCValueViewController () <UITextFieldDelegate>
@property (nonatomic) NSDictionary *conversionRates;
@property (nonatomic, readonly) UIButton *inputButton;
@property (nonatomic, readonly) SAMTextField *textField;
@property (nonatomic, readonly) UILabel *label;
@property (nonatomic, readonly) UIButton *currencyButton;
@property (nonatomic, readonly) UILabel *lastUpdatedLabel;
@property (nonatomic) UIPopoverController *currencyPopover;
@end

@implementation BTCValueViewController

#pragma mark - Accessors

@synthesize textField = _textField;
@synthesize label = _label;
@synthesize currencyButton = _currencyButton;
@synthesize inputButton = _inputButton;
@synthesize lastUpdatedLabel = _lastUpdatedLabel;

- (UITextField *)textField {
	if (!_textField) {
		_textField = [[SAMTextField alloc] init];
		_textField.keyboardType = UIKeyboardTypeDecimalPad;
		_textField.delegate = self;
		_textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kBTCNumberOfCoinsKey];
		_textField.font = [UIFont fontWithName:@"Avenir-Light" size:24.0f];
		_textField.textColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
		_textField.textAlignment = NSTextAlignmentCenter;
		_textField.textEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
	}
	return _textField;
}


- (UILabel *)label {
	if (!_label) {
		_label = [[UILabel alloc] init];
		_label.font = [UIFont fontWithName:@"Avenir-Heavy" size:50.0f];
		_label.textColor = [UIColor whiteColor];
		_label.adjustsFontSizeToFitWidth = YES;
		_label.textAlignment = NSTextAlignmentCenter;
	}
	return _label;
}


- (UIButton *)currencyButton {
	if (!_currencyButton) {
		_currencyButton = [[UIButton alloc] init];
		[_currencyButton addTarget:self action:@selector(pickCurrency:) forControlEvents:UIControlEventTouchUpInside];
		[_currencyButton setImage:[UIImage imageWithPDFNamed:@"gear" tintColor:[UIColor colorWithWhite:1.0f alpha:0.5f] height:20.0f] forState:UIControlStateNormal];
	}
	return _currencyButton;
}


- (UIButton *)inputButton {
	if (!_inputButton) {
		_inputButton = [[UIButton alloc] init];
		_inputButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Light" size:20.0f];
		[_inputButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:0.5f] forState:UIControlStateNormal];
	}
	return _inputButton;
}


- (UILabel *)lastUpdatedLabel {
	if (!_lastUpdatedLabel) {
		_lastUpdatedLabel = [[UILabel alloc] init];
		_lastUpdatedLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.3f];
		_lastUpdatedLabel.font = [UIFont fontWithName:@"Avenir-Light" size:12.0f];
	}
	return _lastUpdatedLabel;
}

#pragma mark - NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	SAMGradientView *gradient = [[SAMGradientView alloc] initWithFrame:self.view.bounds];
	gradient.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	gradient.gradientColors = @[
		[UIColor colorWithRed:0.102f green:0.451f blue:0.635f alpha:1.0f],
		[UIColor colorWithRed:0.302f green:0.235f blue:0.616f alpha:1.0f]
	];
	gradient.dimmedGradientColors = gradient.gradientColors;
	[self.view addSubview:gradient];

	self.automaticallyAdjustsScrollViewInsets = NO;

	[self.view addSubview:self.textField];
	[self.view addSubview:self.label];
	[self.view addSubview:self.currencyButton];
	[self.view addSubview:self.inputButton];
	[self.view addSubview:self.lastUpdatedLabel];

	[[BTCConversionProvider sharedProvider] getConversionRates:^(NSDictionary *conversionRates) {
		self.conversionRates = conversionRates;

		dispatch_async(dispatch_get_main_queue(), ^{
			[self _update];
			self.lastUpdatedLabel.text = [NSString stringWithFormat:@"Updated %@ ago", [conversionRates[@"updatedAt"] sam_timeInWords]];
		});
	}];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_update) name:kBTCCurrencyDidChangeNotificationName object:nil];
}


- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:nil action:nil];

	CGSize size = self.view.bounds.size;

	CGSize labelSize = [self.label sizeThatFits:CGSizeMake(size.width - 40.0f, 100.0f)];
	labelSize.width = fminf(280.0f, labelSize.width);

	CGFloat offset = -20.0f;
	self.label.frame = CGRectMake(roundf((size.width - labelSize.width) / 2.0f), roundf((size.height - labelSize.height) / 2.0f) + offset, labelSize.width, labelSize.height);

//	self.textField.frame = CGRectMake(20.0f, CGRectGetMaxY(self.label.frame) + offset + 10.0f, 280.0f, 44.0f);
	self.inputButton.frame = CGRectMake(20.0f, CGRectGetMaxY(self.label.frame) + offset + 10.0f, size.width - 40.0f, 44.0f);

	self.currencyButton.frame = CGRectMake(size.width - 44.0f, size.height - 44.0f, 44.0f, 44.0f);
	self.lastUpdatedLabel.frame = CGRectMake(10.0f, size.height - 31.0f, 200.0f, 20.0f);
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self _update];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}


#pragma mark - Actions

- (void)pickCurrency:(id)sender {
	BTCCurrencyPickerTableViewController *viewController = [[BTCCurrencyPickerTableViewController alloc] init];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UINavigationController *navigationController = [[BTCNavigationController alloc] initWithRootViewController:viewController];
		navigationController.navigationBar.titleTextAttributes = @{
			NSForegroundColorAttributeName: [UIColor colorWithRed:0.102f green:0.451f blue:0.635f alpha:1.0f],
			NSFontAttributeName: [UIFont fontWithName:@"Avenir-Heavy" size:20.0f]
		};

		self.currencyPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		[self.currencyPopover presentPopoverFromRect:self.currencyButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
		return;
	}

	[self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - Private

- (void)_textFieldDidChange:(NSNotification *)notification {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:@([self.textField.text floatValue]) forKey:kBTCNumberOfCoinsKey];
	[userDefaults synchronize];

	[self _update];
}


- (void)_update {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.currencyPopover dismissPopoverAnimated:YES];
	}

	static NSNumberFormatter *currencyFormatter = nil;
	static dispatch_once_t currencyOnceToken;
	dispatch_once(&currencyOnceToken, ^{
		currencyFormatter = [[NSNumberFormatter alloc] init];
		currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	});

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	currencyFormatter.currencyCode = [userDefaults stringForKey:kBTCSelectedCurrencyKey];
	CGFloat value = [self.textField.text floatValue] * [self.conversionRates[currencyFormatter.currencyCode] floatValue];
	self.label.text = [currencyFormatter stringFromNumber:@(value)];

	static NSNumberFormatter *numberFormatter = nil;
	static dispatch_once_t numberOnceToken;
	dispatch_once(&numberOnceToken, ^{
		numberFormatter = [[NSNumberFormatter alloc] init];
		numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
		numberFormatter.currencySymbol = @"";
		numberFormatter.minimumFractionDigits = 0;
		numberFormatter.maximumFractionDigits = 10;
	});

	NSString *title = [numberFormatter stringFromNumber:[userDefaults objectForKey:kBTCNumberOfCoinsKey]];
	[self.inputButton setTitle:[NSString stringWithFormat:@"%@ BTC", title] forState:UIControlStateNormal];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self _update];
	[textField resignFirstResponder];
	return NO;
}

@end