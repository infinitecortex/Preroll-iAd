//
//  GameViewController.m
//  Preroll-iAd
//
//  Created by Spencer Johnson on 12/18/15.
//  Copyright (c) 2015 Spencer Johnson. All rights reserved.
//

#import "GameViewController.h"
#import <SpriteKit/SpriteKit.h>

//AVPlayerViewController and AVPlayer
@import AVFoundation;
@import iAd;

@interface GameViewController()
@property (nonatomic, strong) SKSpriteNode *reserveIndicator;
@property (nonatomic, assign) NSInteger reserveLevel;
//preroll iAd properties and controller
@property (nonatomic, strong) AVPlayerViewController *prerollAdPlayer;
@property (nonatomic, assign) BOOL completeAdPlayback;
@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Basic setup of an SKView and Scene
    SKView *skView = (SKView *)self.view;
    SKScene *bannerScene = [[SKScene alloc] initWithSize:self.view.frame.size];
    
    // Instantiate the texture Atlas for the art assets
    SKTextureAtlas* health = [SKTextureAtlas atlasNamed:@"health"];
    
    // Instantiate the helth status banner
    SKSpriteNode *healthBanner = [SKSpriteNode spriteNodeWithTexture:[health textureNamed:@"HealthBar"]];
    
    // Place the banner in the middle of the view
    healthBanner.position = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    
    // For the reserve indicator create a white sprite node the same size as the health banner
    CGSize reserveSize = healthBanner.size;
    reserveSize.width = reserveSize.width * 0.875;
    self.reserveIndicator = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor] size:reserveSize];
    // Set the anchor point for the indicator to be the left side for horizontal and center for vertical
    self.reserveIndicator.anchorPoint = CGPointMake(0.0,0.5);
    // Posistion the indicator so the left side lines up with the indicator area in the banner
    self.reserveIndicator.position = CGPointMake(-reserveSize.width/2,0);
    
    // We will use a crop node to mask out health indicator so it only shows up in the healt bar area of the banner
    SKCropNode *reserveCropNode = [[SKCropNode alloc]init];
    reserveCropNode.maskNode = [SKSpriteNode spriteNodeWithTexture:[health textureNamed:@"HealthBar_Mask"]];
    // Add the health level indicator as a child of the crop node
    [reserveCropNode addChild:self.reserveIndicator];
    //    self.reserveIndicator.blendMode = SKBlendModeMultiplyX2;
    
    //    SKSpriteNode *blendNode = [SKSpriteNode spriteNodeWithTexture:nil size:reserveSize];
    //    blendNode.blendMode = SKBlendModeMultiply;
    //
    //    [blendNode addChild:reserveCropNode];
    //
    
    [healthBanner addChild:reserveCropNode];
    [bannerScene addChild:healthBanner];
    
    self.reserveLevel = 70;
    
    [self updateReserveDisplay:self.reserveLevel];
    
    [skView presentScene:bannerScene];
    
    
    // add a tap gesture recognizer.  Just used to show the effect of changing the reserve level
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObjectsFromArray:skView.gestureRecognizers];
    skView.gestureRecognizers = gestureRecognizers;
    
    //set up the ViewController
    self.prerollAdPlayer = [[AVPlayerViewController alloc] init];
    //self.prerollAdPlayer.showsPlaybackControls = false;
}


- (void)updateReserveDisplay:(NSInteger)reserve {
    self.reserveIndicator.color = [SKColor colorWithRed:((100.0-reserve)/100.0) green:(reserve/100.0) blue:0.0 alpha:1.0];
    [self.reserveIndicator setXScale:(reserve/100.0)];
}


- (void) handleTap:(UIGestureRecognizer*)gestureRecognize {
    self.reserveLevel = self.reserveLevel - 5;
    if (self.reserveLevel < 0) [self showAdRewardRefillAlert];
    [self updateReserveDisplay:self.reserveLevel];
    
}

- (void)refillReserves{
    self.reserveLevel = 100;
    [self updateReserveDisplay:self.reserveLevel];
}

- (void) showAdRewardRefillAlert{
    UIAlertController *reviveAlertController = [UIAlertController alertControllerWithTitle:@"Refill Health Bar!"
                                                                                   message:@"Watch an Ad to refill the Health Bar"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *adAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self playVideoAd];
    }];
    [reviveAlertController addAction:cancelAction];
    [reviveAlertController addAction:adAction];
    [self presentViewController:reviveAlertController animated:YES completion:nil];
}

- (void) playVideoAd{
    self.completeAdPlayback = false;
    [self presentViewController:self.prerollAdPlayer animated:YES completion:^{
        [self.prerollAdPlayer playPrerollAdWithCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"%@",error);
            }
            else {
                //
                [self refillReserves];
                self.completeAdPlayback = true;
            }
            [self.prerollAdPlayer dismissViewControllerAnimated:YES completion:^{
                if (!self.completeAdPlayback) {
                    [self showAdPlayerErrorAlert];
                }
            }];
        }];
    }];
}

- (void) showAdPlayerErrorAlert{
    UIAlertController *reviveAlertController = [UIAlertController alertControllerWithTitle:@"Error:"
                                                                                   message:@"Ad was unalbe to complete playing."
                                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Give Up" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *adAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self playVideoAd];
    }];
    UIAlertAction *refillAction = [UIAlertAction actionWithTitle:@"Free Refill" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self refillReserves];
    }];
    [reviveAlertController addAction:cancelAction];
    [reviveAlertController addAction:adAction];
    [reviveAlertController addAction:refillAction];
    [self presentViewController:reviveAlertController animated:YES completion:nil];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
