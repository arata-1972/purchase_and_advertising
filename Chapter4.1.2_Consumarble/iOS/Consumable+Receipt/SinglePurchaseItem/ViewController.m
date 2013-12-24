//
//  ViewController.m
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/16.
//
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
	// アプリ内課金プロダクト情報を取得する
	myProduct = nil;
	myProductRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"ConsumableProduct"]];
	myProductRequest.delegate = self;
	[myProductRequest start];
    
	// Indicatorを表示する
	[self.indicator setHidden:NO];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	// AppDelegateからの購入通知を登録する
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(purchased:)
	                                             name:@"Purchased"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(failed:)
	                                             name:@"Failed"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(purchaseCompleted:)
	                                             name:@"PurchaseCompleted"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(restoreCompleted:)
	                                             name:@"RestoreCompleted"
	                                           object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(restoreFailed:)
	                                             name:@"RestoreFailed"
	                                           object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
	// AppDelegateからの、購入通知を解除する
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"Purchased"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"Failed"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"PurchaseCompleted"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"RestoreCompleted"
	                                              object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:@"RestoreFailed"
	                                              object:nil];
}

// SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	// アプリ内課金プロダクトが取得できなかった
	if (response == nil) {
		NSLog(@"didReceiveResponse response == nil");
		[self.productTitle setText:@"購入できるものはありません"];
        
		// Indicatorを非表示にする
		[self.indicator setHidden:YES];
        
		return;
	}
    
	// 確認できなかったidentifierをログに記録
	for (NSString *identifier in response.invalidProductIdentifiers) {
		NSLog(@"invalidProductIdentifiers: %@", identifier);
	}
    
	// アプリ内課金プロダクトを取得
	for (SKProduct *product in response.products) {
		NSLog(@"Product: %@ %@ %@ %d",
		      product.productIdentifier,
		      product.localizedTitle,
		      product.localizedDescription,
		      [product.price intValue]);
        
		// ここではアプリ内課金プロダクトが唯一である想定
		myProduct = product;
	}
    
	// 商品情報が1つも取得できなかった
	if (myProduct == nil) {
		NSLog(@"myProduct == nil");
		[self.productTitle setText:@"購入できるものはありません"];
        
		// Indicatorを非表示にする
		[self.indicator setHidden:YES];
        
		return;
	}
    
	// ローカライズ後の価格を取得
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:myProduct.priceLocale];
	NSString *localedPrice = [numberFormatter stringFromNumber:myProduct.price];
    
	// 商品情報を表示
	[self.productTitle setText:myProduct.localizedTitle];        // プロダクトのタイトル
	[self.productPrice setText:localedPrice];                    // ローカライズ後の金額
	[self.productDescription setText:myProduct.localizedDescription]; // プロダクトの説明
    
	// Indicatorを非表示にする
	[self.indicator setHidden:YES];
}

- (IBAction)purchaseButtonOnTouch:(id)sender {
	// 機能制限 - App内の購入　のチェックを行う
	if ([SKPaymentQueue canMakePayments] == NO) {
		UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:@"購入できません"
                                   message:@"App内の購入が機能制限されています"
                                  delegate:nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
		[alert show];
		return;
	}
    
	// 購入用のペイメントをSKProductから生成する
	SKPayment *payment = [SKPayment paymentWithProduct:myProduct];
	// SKPaymentQueueに追加＝トランザクションが開始される
	[[SKPaymentQueue defaultQueue] addPayment:payment];
    
	// Indicatorを表示する
	[self.indicator setHidden:NO];
}

- (IBAction)restoreButtonOnTouch:(id)sender {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
	// Indicatorを表示する
	[self.indicator setHidden:NO];
}

- (IBAction)helloButtonOnTouch:(id)sender {
	// すてにプロダクトを購入済みか判定する
	long itemCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"ConsumableProduct"];
	if (itemCount > 0) {
		// プロダクトの回数を減算して設定に保存
		itemCount--;
		[[NSUserDefaults standardUserDefaults] setInteger:itemCount
		                                           forKey:@"ConsumableProduct"];
		[[NSUserDefaults standardUserDefaults] synchronize];
        
		[[[UIAlertView alloc] initWithTitle:@"アイテムを使用しました"
		                            message:[NSString stringWithFormat:@"ライフが回復しました！アイテムの残数は %ld つです", itemCount]
		                           delegate:nil
		                  cancelButtonTitle:@"OK"
		                  otherButtonTitles:nil] show];
	}
	else {
		[[[UIAlertView alloc] initWithTitle:@"アイテムがありません"
		                            message:@"アイテムがなかったのでライフが回復できません..."
		                           delegate:nil
		                  cancelButtonTitle:@"OK"
		                  otherButtonTitles:nil] show];
	}
}

- (void)purchased:(NSNotification *)notification {
	// Indicatorを非表示にする
	[self.indicator setHidden:YES];
}

- (void)failed:(NSNotification *)notification {
	// Indicatorを非表示にする
	[self.indicator setHidden:YES];
}

- (void)purchaseCompleted:(NSNotification *)notification {
	// Indicatorを非表示にする
	[self.indicator setHidden:YES];
}

- (void)restoreCompleted:(NSNotification *)notification {
	// Indicatorを非表示にする
	[self.indicator setHidden:YES];
}

- (void)restoreFailed:(NSNotification *)notification {
	// Indicatorを非表示にする
	[self.indicator setHidden:YES];
}

@end
