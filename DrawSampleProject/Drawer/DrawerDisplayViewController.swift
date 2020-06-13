//
//  ViewController.swift
//  DrawSampleProject
//
//  Created by Ashli Rankin on 6/13/20.
//  Copyright © 2020 Ashli Rankin. All rights reserved.
//

import UIKit

class DrawerDisplayViewController: UIViewController {
    private enum CardState {
        case expanded
        case collapsed
    }
    
    private let cardHeight: CGFloat = 560
    private let cardHandleArea: CGFloat = 60
    private var isCardVisible: Bool = false
    private var animationProgressWhenInterrupted: CGFloat = 0.0
    
    private var nextState: CardState {
        return isCardVisible ? .collapsed : .expanded
    }
    
    private var runningAnimations = [UIViewPropertyAnimator]()
    
    @IBOutlet private weak var objectDisplayImageView: UIImageView!
    
    private lazy var detailedViewController = DrawerDetailViewController(nibName: "DrawerDetailViewController", bundle: .main)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailedViewController.view.frame = CGRect(x: 0, y: view.frame.height, width: view.bounds.width, height: cardHeight)
        detailedViewController.view.clipsToBounds = true
        addChild(detailedViewController)
        view.addSubview(detailedViewController.view)
        animateTransitionIfNeeded(state: nextState, duration: 1.0)
        detailedViewController.delegate = self
    }
    private func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.detailedViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.detailedViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleArea
                }
            }
            frameAnimator.addCompletion { _ in
                self.isCardVisible = !self.isCardVisible
                self.runningAnimations.removeAll()
            }
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.detailedViewController.view.layer.cornerRadius = 20.0
                case .collapsed:
                    self.detailedViewController.view.layer.cornerRadius = 0
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
        }
    }
    
    
    private func startIntractiveTransition(state: CardState, duration: TimeInterval) {
        
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    private func updateInteractiveTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    private func continueInteractionTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)
        }
    }
    
}

extension DrawerDisplayViewController: DrawerDetailViewControllerDelegate {
    
    // MARK: - DetailedDescriptionViewControllerDelegate
    
    func panGestureDidBegin(_ cardViewController: DrawerDetailViewController) {
        startIntractiveTransition(state: nextState, duration: 1.0)
    }
    
    func panGestureDidChange(_ cardViewController: DrawerDetailViewController, with translation: CGPoint) {
        var fractionComplete = translation.y / cardHeight
        
        fractionComplete = isCardVisible ? fractionComplete : -fractionComplete
        updateInteractiveTransition(fractionCompleted: fractionComplete)
    }
    
    func panGestureDidEnd(_ cardViewController: DrawerDetailViewController) {
        continueInteractionTransition()
    }
}
